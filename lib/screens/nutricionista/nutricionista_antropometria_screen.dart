import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_colors.dart';
import 'nutricionista_nova_avaliacao.dart';
// Certifique-se de que estes arquivos existem no seu projeto baseados nos passos anteriores
import '../../classes/paciente.dart';
import 'nutricionista_historico_planos_screen.dart';

class NutricionistaAntropometriaScreen extends StatefulWidget {
  final String pacienteId;

  const NutricionistaAntropometriaScreen({super.key, required this.pacienteId});

  @override
  State<NutricionistaAntropometriaScreen> createState() =>
      _NutricionistaAntropometriaScreenState();
}

class _NutricionistaAntropometriaScreenState
    extends State<NutricionistaAntropometriaScreen> {
  // 0 = Antropometria, 1 = Planos
  int _abaSelecionada = 0;

  final Color corAbaixo = Colors.orange;
  final Color corIdeal = Colors.green;
  final Color corAcima = Colors.red;

  bool _existeAvaliacao = false;

  // Variável para armazenar o objeto Paciente completo para passar para a tela de planos
  Paciente? _pacienteObjeto;

  Future<Map<String, dynamic>> _buscarDados() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      final userSnap = await dbRef.child('usuarios/${widget.pacienteId}').get();

      // Pega a última avaliação para exibir na tela principal
      final antropoSnap =
          await dbRef
              .child('antropometria/${widget.pacienteId}')
              .orderByKey()
              .limitToLast(1)
              .get();

      // Cria o objeto Paciente se os dados existirem
      if (userSnap.value != null) {
        final dadosUser = Map<String, dynamic>.from(userSnap.value as Map);
        dadosUser['id'] = widget.pacienteId; // Garante que o ID está no map
        _pacienteObjeto = Paciente.fromMap(dadosUser);
      }

      return {'usuario': userSnap.value, 'antropometria': antropoSnap.value};
    } catch (e) {
      debugPrint("Erro ao buscar dados: $e");
      return {};
    }
  }

  Color _definirCor(String? classificacao) {
    if (classificacao == null) return Colors.grey;
    final valor = classificacao.toLowerCase();
    if (valor.contains('ideal')) return corIdeal;
    if (valor.contains('abaixo')) return corAbaixo;
    if (valor.contains('acima')) return corAcima;
    return Colors.grey;
  }

  String _formatarData(String? isoString) {
    if (isoString == null) return "--/--/----";
    try {
      final data = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(data);
    } catch (e) {
      return isoString;
    }
  }

  // --- NAVEGAÇÃO ---
  void _navegarParaFormulario({Map<String, dynamic>? dadosEdicao}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NovaAvaliacaoScreen(
              pacienteId: widget.pacienteId,
              dadosExistentes: dadosEdicao,
            ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // --- UI: TOGGLE (BOTÃO DE DIVISÃO) ---
  Widget _buildToggleSwitch() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabItem(0, "Antropometria"),
          _buildTabItem(1, "Planos Alimentares"),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final bool isSelected = _abaSelecionada == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _abaSelecionada = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.laranja : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // --- UI: CONTEÚDO DA ABA ANTROPOMETRIA ---
  Widget _buildAbaAntropometria(
    String nome,
    Map<String, dynamic>? avaliacao,
    Color primaryColor,
  ) {
    if (avaliacao == null) {
      return _buildEmptyState(nome);
    }
    return _buildContent(nome, avaliacao, primaryColor);
  }

  // --- UI: CONTEÚDO DA ABA PLANOS ---
  Widget _buildAbaPlanos() {
    if (_pacienteObjeto == null) {
      return const Center(child: Text("Carregando dados do paciente..."));
    }
    // Aqui integramos a tela criada anteriormente.
    // Dica: Idealmente a NutricionistaHistoricoPlanosScreen deveria aceitar um parâmetro
    // para esconder sua própria AppBar se quisermos que pareça 100% integrado,
    // mas aqui ela funcionará como um widget filho.
    return SizedBox(
      height: 600, // Altura fixa ou use Expanded se refatorar o layout
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: NutricionistaHistoricoPlanosScreen(paciente: _pacienteObjeto!),
      ),
    );
  }

  // ... (Mantenha as funções _mostrarSeletorDeAvaliacoes, _deletarAvaliacao, _confirmarExclusao, _mostrarOpcoes IGUAIS) ...
  // Para economizar espaço na resposta, assumi que você manteve esses métodos auxiliares do código original.
  // Vou incluir apenas as chamadas no build.

  // --- LÓGICA DE MODAL IGUAL AO ORIGINAL ---
  void _mostrarSeletorDeAvaliacoes({required bool isDeleteMode}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isDeleteMode
                        ? "Escolha qual apagar"
                        : "Escolha qual editar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDeleteMode ? Colors.red : AppColors.laranja,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder(
                      stream:
                          FirebaseDatabase.instance
                              .ref()
                              .child('antropometria/${widget.pacienteId}')
                              .orderByKey()
                              .onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data?.snapshot.value == null) {
                          return const Center(
                            child: Text("Nenhuma avaliação encontrada."),
                          );
                        }
                        final dadosRaw = snapshot.data!.snapshot.value as Map;
                        List<Map<String, dynamic>> listaAvaliacoes = [];
                        dadosRaw.forEach((key, value) {
                          final map = Map<String, dynamic>.from(value as Map);
                          map['key'] = key;
                          listaAvaliacoes.add(map);
                        });
                        listaAvaliacoes.sort(
                          (a, b) =>
                              (b['data'] ?? '').compareTo(a['data'] ?? ''),
                        );

                        return ListView.separated(
                          controller: controller,
                          itemCount: listaAvaliacoes.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = listaAvaliacoes[index];
                            final dataFormatada = _formatarData(item['data']);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isDeleteMode
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                child: Icon(
                                  isDeleteMode
                                      ? Icons.delete_outline
                                      : Icons.edit,
                                  color:
                                      isDeleteMode ? Colors.red : Colors.blue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                "Avaliação de $dataFormatada",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "Peso: ${item['massaCorporal']}kg | IMC: ${item['imc']}",
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                if (isDeleteMode) {
                                  _confirmarExclusao(
                                    item['key'],
                                    dataFormatada,
                                  ); // usando key como ID
                                } else {
                                  _navegarParaFormulario(dadosEdicao: item);
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarExclusao(String idAvaliacao, String dataFormatada) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Apagar Avaliação"),
            content: Text(
              "Tem certeza que deseja apagar a avaliação de $dataFormatada?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deletarAvaliacao(idAvaliacao);
                },
                child: const Text(
                  "Apagar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deletarAvaliacao(String idAvaliacao) async {
    await FirebaseDatabase.instance
        .ref()
        .child('antropometria/${widget.pacienteId}/$idAvaliacao')
        .remove();
    setState(() {});
  }

  void _mostrarOpcoes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text("Atualizar avaliação antiga"),
                enabled: _existeAvaliacao,
                onTap: () {
                  Navigator.pop(context);
                  _mostrarSeletorDeAvaliacoes(isDeleteMode: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text("Criar nova avaliação"),
                onTap: () {
                  Navigator.pop(context);
                  _navegarParaFormulario(dadosEdicao: null);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Apagar avaliação",
                  style: TextStyle(color: Colors.red),
                ),
                enabled: _existeAvaliacao,
                onTap: () {
                  Navigator.pop(context);
                  _mostrarSeletorDeAvaliacoes(isDeleteMode: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.laranja;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text(
          _abaSelecionada == 0 ? "Última Avaliação" : "Histórico de Planos",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // O Floating Action Button só aparece na aba Antropometria
      floatingActionButton:
          _abaSelecionada == 0
              ? FloatingActionButton(
                onPressed: _mostrarOpcoes,
                backgroundColor: primaryColor,
                child: const Icon(Icons.menu, color: Colors.white),
              )
              : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _buscarDados(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Erro ao carregar.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final dadosGerais = snapshot.data;
          String nome = "Paciente";
          if (dadosGerais?['usuario'] != null) {
            nome = (dadosGerais!['usuario'] as Map)['nome'] ?? "Paciente";
          }

          Map<String, dynamic>? avaliacao;
          if (dadosGerais?['antropometria'] != null) {
            final mapAntropo = Map<String, dynamic>.from(
              dadosGerais!['antropometria'] as Map,
            );
            if (mapAntropo.isNotEmpty) {
              avaliacao = Map<String, dynamic>.from(
                mapAntropo.values.first as Map,
              );
              _existeAvaliacao = true;
            } else {
              _existeAvaliacao = false;
            }
          } else {
            _existeAvaliacao = false;
          }

          return CustomScrollView(
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
                    children: [
                      // --- AQUI ESTÁ A DIVISÃO ---
                      _buildToggleSwitch(),

                      // --- CONTEÚDO VARIÁVEL ---
                      if (_abaSelecionada == 0)
                        _buildAbaAntropometria(nome, avaliacao, primaryColor)
                      else
                        _buildAbaPlanos(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- MÉTODOS VISUAIS ANTIGOS (Mantidos) ---
  Widget _buildEmptyState(String nome) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Text(
          "Paciente: $nome",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Icon(Icons.note_alt_outlined, size: 60, color: Colors.grey),
        const SizedBox(height: 10),
        const Text(
          "Nenhuma avaliação registrada.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildContent(
    String nome,
    Map<String, dynamic> avaliacao,
    Color primaryColor,
  ) {
    final dataExame = _formatarData(avaliacao['data']);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Data: $dataExame",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _legendaContainer(),
        const SizedBox(height: 25),
        Row(
          children: [
            Icon(Icons.bar_chart, color: primaryColor, size: 22),
            const SizedBox(width: 8),
            const Text(
              "Resultados",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _itemDado(
          "Massa Corporal",
          avaliacao['massaCorporal'],
          "kg",
          avaliacao['classMassaCorporal'],
        ),
        _itemDado(
          "Massa Gordura",
          avaliacao['massaGordura'],
          "kg",
          avaliacao['classMassaGordura'],
        ),
        _itemDado(
          "% de Gordura",
          avaliacao['percentualGordura'],
          "%",
          avaliacao['classPercentualGordura'],
        ),
        _itemDado(
          "Massa Esquelética",
          avaliacao['massaEsqueletica'],
          "kg",
          avaliacao['classMassaEsqueletica'],
        ),
        _itemDado("IMC", avaliacao['imc'], "", avaliacao['classImc']),
        _itemDado("CMB", avaliacao['cmb'], "cm", avaliacao['classCmb']),
        _itemDado(
          "RCQ",
          avaliacao['relacaoCinturaQuadril'],
          "",
          avaliacao['classRcq'],
        ),
      ],
    );
  }

  Widget _legendaContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legenda("Abaixo", corAbaixo),
          _legenda("Ideal", corIdeal),
          _legenda("Acima", corAcima),
        ],
      ),
    );
  }

  Widget _legenda(String texto, Color cor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _itemDado(
    String label,
    dynamic valor,
    String unidade,
    dynamic classificacao,
  ) {
    final String valTexto = valor?.toString() ?? "-";
    final Color corStatus = _definirCor(classificacao?.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Text(
                "$valTexto $unidade",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: corStatus,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
