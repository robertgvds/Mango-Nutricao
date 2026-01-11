import 'package:app/screens/nutricionista/nutricionista_historico_planos_screen.dart';
import 'package:app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:app/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../classes/nutricionista.dart';
import '../../database/nutricionista_repository.dart';
import '../../database/paciente_repository.dart';
import '../../classes/paciente.dart';
import 'nutricionista_detalhes_paciente_screen.dart';
import '../../database/antropometria_repository.dart';
import '../../database/plano_alimentar_repository.dart';
import '../../classes/planoalimentar.dart';
import 'package:firebase_database/firebase_database.dart';

class NutricionistaHomeScreen extends StatefulWidget {
  final String nutriId;
  final Function(int) onMudarAba;

  const NutricionistaHomeScreen({
    super.key,
    required this.nutriId,
    required this.onMudarAba,
  });

  @override
  State<NutricionistaHomeScreen> createState() =>
      _NutricionistaHomeScreenState();
}

class _NutricionistaHomeScreenState extends State<NutricionistaHomeScreen> {
  final _nutriRepo = NutricionistaRepository();
  final _pacienteRepo = PacienteRepository();

  Nutricionista? _nutricionista;
  List<Paciente> _meusPacientes = [];
  bool _isLoading = true;
  bool _isLinking = false;
  Map<String, PlanoAlimentar?> _mapaPlanos = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _vincularPaciente() async {
    final String idDigitado = _idController.text.trim();

    if (idDigitado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, insira o ID do paciente.")),
      );
      return;
    }

    if (_nutricionista == null) return;

    // Evita duplicação local antes de chamar o banco
    if (_nutricionista!.pacientesIds.contains(idDigitado)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este paciente já está vinculado a você."),
        ),
      );
      return;
    }

    setState(() => _isLinking = true);

    try {
      // 1. Verifica se o paciente existe no banco
      final Paciente? pacienteEncontrado = await _pacienteRepo.buscarPorId(
        idDigitado,
      );

      if (pacienteEncontrado == null) {
        throw Exception("Paciente não encontrado. Verifique o ID.");
      }

      // 2. Adiciona à lista do Nutricionista (Objeto local + Update Repo)
      _nutricionista!.adicionarPaciente(idDigitado);
      await _nutriRepo.atualizar(_nutricionista!);

      // 3. Atualiza o cadastro do Paciente (Reverse Link)
      // Isso garante que o paciente saiba quem é seu nutri (útil para outras telas)
      final DatabaseReference refPaciente = FirebaseDatabase.instance
          .ref()
          .child('usuarios')
          .child(idDigitado);

      await refPaciente.update({'nutricionistaId': widget.nutriId});

      // 4. Sucesso
      _idController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sucesso! ${pacienteEncontrado.nome} vinculado."),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 5. Recarrega a lista para aparecer na UI
      await _carregarDados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final nutri = await _nutriRepo.buscarPorId(widget.nutriId);
      final _planoRepo = PlanoAlimentarRepository();
      final _antropometriaRepo = AntropometriaRepository();

      if (nutri != null) {
        List<Paciente> listaPacientes = [];
        Map<String, PlanoAlimentar?> tempPlano = {};

        for (String id in nutri.pacientesIds) {
          final p = await _pacienteRepo.buscarPorId(id);
          if (p != null) {
            p.antropometria = await _antropometriaRepo.buscarUltimaAvaliacao(
              id,
            );
            final planos = await _planoRepo.listarPlanos(id);
            tempPlano[id] = planos.isNotEmpty ? planos.first : null;

            listaPacientes.add(p);
          }
        }

        if (mounted) {
          setState(() {
            _nutricionista = nutri;
            _meusPacientes = listaPacientes;
            _mapaPlanos = tempPlano; // Atualiza o mapa com os novos dados
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao recarregar dados: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MÉTODO DE NAVEGAÇÃO ---
  // Busca o paciente pelo ID e abre a tela de Plano Alimentar
  Future<void> _abrirTestePlanoAlimentar(String pacienteId) async {
    // Mostra loading rápido
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pacienteTeste = await _pacienteRepo.buscarPorId(pacienteId);

      // Fecha o loading
      if (mounted) Navigator.pop(context);

      if (pacienteTeste != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => NutricionistaHistoricoPlanosScreen(
                    paciente: pacienteTeste,
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Paciente de teste não encontrado no banco."),
            ),
          );
        }
      }
    } catch (e) {
      // Fecha loading se der erro
      if (mounted) Navigator.pop(context);
      debugPrint("Erro teste: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.laranja,

      // Botão flutuante removido conforme solicitado
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
      body: CustomScrollView(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  const Divider(),

                  _buildSecaoTitulo(
                    "Vincular Novo Paciente",
                    AppColors.laranja,
                  ),

                  _buildAdicionarPacienteInput(),
                  const Divider(),

                  _buildSecaoTitulo(
                    "Avaliações Pendentes",
                    const Color(0xFF916DD5),
                  ),

                  if (_meusPacientes.any((p) => p.antropometria == null))
                    ..._meusPacientes
                        .where((p) => p.antropometria == null)
                        .map((p) => _cardAvaliacaoPendente(p))
                  else
                    _buildMensagem(
                      "Todos os pacientes estão avaliados!",
                      AppColors.roxo,
                    ),

                  const Divider(),

                  _buildSecaoTitulo(
                    "Planos Pendentes",
                    const Color(0xFF4CAF50),
                  ),

                  if (_meusPacientes.any((p) => _mapaPlanos[p.id] == null))
                    ..._meusPacientes
                        .where((p) => _mapaPlanos[p.id] == null)
                        .map((p) => _cardPlanoPendente(p))
                  else
                    _buildMensagem(
                      "Sem planos a pendentes!",
                      AppColors.verdeEscuro,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final TextEditingController _idController = TextEditingController();

  Widget _buildAdicionarPacienteInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: "ID do paciente",
                  hintStyle: const TextStyle(fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: _isLinking ? null : _vincularPaciente,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laranja,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
              ),
              child:
                  _isLinking
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text("Vincular", style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: [
              const TextSpan(text: "Olá, "),
              TextSpan(
                text: _nutricionista?.nome ?? "Nutri",
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
        Text("Pacientes ativos: ${_nutricionista?.pacientesIds.length ?? 0}"),
        Text(
          "CRN: ${_nutricionista?.crn ?? "N/A"}",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _cardAvaliacaoPendente(Paciente paciente) {
    final antro = paciente.antropometria;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paciente.nome,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            antro == null
                ? "Sem Avaliações"
                : "Última Avaliação: ${antro.data}",
            style: const TextStyle(
              color: AppColors.roxo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAF87EF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.accessibility_new, size: 18),
              label: const Text("Adicionar Avaliação"),
              onPressed: () {
                if (paciente.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => NutricionistaAntropometriaScreen(
                            pacienteId: paciente.id!,
                          ),
                    ),
                  ).then((_) => _carregarDados());
                }
              },
            ),
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

  Widget _cardPlanoPendente(Paciente paciente) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paciente.nome,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Sem Plano Alimentar Ativo",
            style: TextStyle(
              color: AppColors.verdeEscuro,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: const Text("Adicionar Plano Alimentar"),
              onPressed: () {
                _abrirTestePlanoAlimentar(
                  paciente.id!,
                ).then((_) => _carregarDados());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensagem(String mensagem, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: c),
          const SizedBox(width: 12),
          Text(
            mensagem,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
