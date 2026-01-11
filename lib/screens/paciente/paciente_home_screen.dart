import 'package:flutter/services.dart';
import 'package:app/database/plano_alimentar_repository.dart';
import 'package:app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/services/auth_service.dart';
import '../../classes/antropometria.dart';
import '../../database/antropometria_repository.dart';
import '../../database/paciente_repository.dart';
import '../../classes/paciente.dart';
import '../../classes/refeicao.dart';
import '../../classes/nutricionista.dart';
import '../../database/nutricionista_repository.dart';
import '../../classes/plano_alimentar.dart';

class HomeTabScreen extends StatefulWidget {
  final String pacienteId;
  final Function(int) onMudarAba;

  const HomeTabScreen({
    super.key,
    required this.pacienteId,
    required this.onMudarAba,
  });

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  bool _isLoading = true;
  Paciente? _paciente;
  final PacienteRepository _pacienteRepo = PacienteRepository();
  final NutricionistaRepository _nutriRepo = NutricionistaRepository();
  Antropometria? _ultimaAvaliacao;
  Nutricionista? _nutricionista;
  Refeicao? _proximaRefeicao;

  @override
  void initState() {
    super.initState();
    _carregarDadosHome();
  }

  Future<void> _carregarDadosHome() async {
    setState(() => _isLoading = true);
    try {
      _paciente = await _pacienteRepo.buscarPorId(widget.pacienteId);
      print("DEBUG: CRN do Paciente: ${_paciente?.nutricionistaCrn}");
      _ultimaAvaliacao = await AntropometriaRepository().buscarUltimaAvaliacao(
        widget.pacienteId,
      );

      final crn = _paciente?.nutricionistaCrn;
      if (crn != null && crn.trim().isNotEmpty) {
        _nutricionista = await _nutriRepo.buscarPorCRN(crn);
      }
      print("DEBUG: Nutricionista encontrado: ${_nutricionista?.nome}");

      List<PlanoAlimentar> planos = await PlanoAlimentarRepository()
          .listarPlanos(widget.pacienteId);
      if (planos.isNotEmpty) {
        _proximaRefeicao = _calcularProximaRefeicao(planos.first.refeicoes);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Erro ao carregar Home: $e");
      setState(() => _isLoading = false);
    }
  }

  Refeicao? _calcularProximaRefeicao(List<Refeicao> refeicoes) {
    if (refeicoes.isEmpty) return null;

    final agora = DateTime.now();
    final horaAtualEmMinutos = agora.hour * 60 + agora.minute;

    Refeicao? proxima;
    int menorDiferenca = 9999;

    for (var ref in refeicoes) {
      // Converte "08:00" para minutos (480)
      final partes = ref.horario.split(':');
      if (partes.length < 2) continue;

      final horaRef = int.parse(partes[0]) * 60 + int.parse(partes[1]);
      final diferenca = horaRef - horaAtualEmMinutos;

      // Se a refeição ainda vai acontecer hoje e é a mais próxima
      if (diferenca > 0 && diferenca < menorDiferenca) {
        menorDiferenca = diferenca;
        proxima = ref;
      }
    }

    // Se não houver mais nenhuma hoje (ex: já passou da janta), mostra a primeira do dia seguinte
    return proxima ?? refeicoes.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool temCrnVinculado =
        _paciente?.nutricionistaCrn != null &&
        _paciente!.nutricionistaCrn!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.laranja,
      appBar: AppBar(
        backgroundColor: AppColors.laranja,
        elevation: 0,
        title: const Text('Mango Nutri', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Olá, '),
                                    TextSpan(
                                      text:
                                          '${_paciente?.nome ?? "Carregando..."}',
                                      style: const TextStyle(
                                        color: AppColors.laranja,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoLinha(
                                'Idade',
                                '${_paciente?.idade ?? "--"} anos',
                              ),

                              const Divider(),

                              _buildSecaoTitulo(
                                "Nutricionista",
                                AppColors.laranja,
                              ),

                              if (temCrnVinculado)
                                _nutricionista != null
                                    ? _buildCardNutricionista()
                                    : const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                              else
                                _buildCardSemNutri(),

                              const SizedBox(height: 20),
                              const Divider(),

                              _buildSecaoTitulo(
                                "Próxima Refeição",
                                AppColors.verde,
                              ),
                              if (_proximaRefeicao != null) ...[
                                _buildCardProximaRefeicao(_proximaRefeicao!),
                                const SizedBox(height: 16),
                                _buildBotaoPlanoCompleto(),
                              ] else ...[
                                _buildCardSemPlano(),
                              ],

                              const SizedBox(height: 30),
                              const Divider(),

                              _buildSecaoTitulo(
                                "Última Avaliação",
                                AppColors.roxo,
                              ),

                              _ultimaAvaliacao != null
                                  ? _buildCardAntropometria(_ultimaAvaliacao!)
                                  : _buildCardSemDadosAntro(),

                              const SizedBox(height: 16),

                              _buildBotaoHistoricoCompleto(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInfoLinha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$rotulo: $valor',
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.cinzaEscuro,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCardNutricionista() {
    final nutri = _nutricionista;

    if (nutri == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.laranja.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_ind,
              color: AppColors.laranja,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nutri.nome.isEmpty ? "Nome não informado" : nutri.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CRN: ${nutri.crn.isEmpty ? "--" : nutri.crn}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSemNutri() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        children: [
          const Text(
            'Você ainda não possui um nutricionista vinculado.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText(
                widget.pacienteId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 20,
                  color: AppColors.laranja,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.pacienteId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID copiado para a área de transferência.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const Text(
            'Passe este código a um nutricionista.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoTitulo(String t, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Text(
      t,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c),
    ),
  );

  Widget _buildCardProximaRefeicao(Refeicao refeicao) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                refeicao.nome,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.verde,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.verde.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  refeicao.horario,
                  style: const TextStyle(
                    color: AppColors.verde,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            refeicao.alimentos.map((a) => a.nome).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroInfo("Kcal", refeicao.totalCalorias),
              _buildMacroInfo("Prot", refeicao.totalProteinas),
              _buildMacroInfo("Carb", refeicao.totalCarboidratos),
              _buildMacroInfo("Gord", refeicao.totalGorduras),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, double valor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          "${valor.toStringAsFixed(1)}${label == 'Kcal' ? '' : 'g'}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.verdeEscuro,
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoPlanoCompleto() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () => widget.onMudarAba(2),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Row(
          children: [
            Icon(Icons.restaurant_menu, size: 18),
            Expanded(
              child: Text(
                "Ver plano alimentar completo",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSemPlano() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        "Seu nutricionista ainda não liberou seu plano alimentar.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildCardAntropometria(Antropometria dados) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                "Avaliado em: ${_formatarData(dados.data)}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoEvolucao(
                "Peso",
                dados.massaCorporal?.toString() ?? "--",
              ),
              _buildInfoEvolucao("IMC", dados.imc?.toStringAsFixed(1) ?? "--"),
              _buildInfoEvolucao(
                "% Gordura",
                "${dados.percentualGordura?.toStringAsFixed(1) ?? "--"}%",
              ),
              _buildInfoEvolucao(
                "Massa Musc.",
                "${dados.massaEsqueletica?.toStringAsFixed(1) ?? "--"}kg",
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return "--/--/----";
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
  }

  Widget _buildInfoEvolucao(String label, String valor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.roxo,
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoHistoricoCompleto() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () => widget.onMudarAba(1),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.roxo,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Row(
          children: [
            Icon(Icons.accessibility_new, size: 18),
            Expanded(
              child: Text(
                "Ver histórico completo",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSemDadosAntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            color: Colors.grey.shade400,
            size: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            "Nenhuma avaliação física cadastrada ainda.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
