import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_colors.dart';
import 'nutricionista_nova_avaliacao.dart';
import '../../classes/paciente.dart';

// Importa os componentes
import 'tab_antropometria.dart';
import 'tab_planos.dart';

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
  bool _existeAvaliacao = false;
  Paciente? _pacienteObjeto;

  // Lógica para definir a cor do tema atual
  Color get corTema => _abaSelecionada == 0 ? Colors.deepPurple : Colors.green;

  Future<Map<String, dynamic>> _buscarDados() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      final userSnap = await dbRef.child('usuarios/${widget.pacienteId}').get();

      final antropoSnap =
          await dbRef
              .child('antropometria/${widget.pacienteId}')
              .orderByKey()
              .limitToLast(1)
              .get();

      if (userSnap.value != null) {
        final dadosUser = Map<String, dynamic>.from(userSnap.value as Map);
        dadosUser['id'] = widget.pacienteId;
        _pacienteObjeto = Paciente.fromMap(dadosUser);
      }
      return {'usuario': userSnap.value, 'antropometria': antropoSnap.value};
    } catch (e) {
      debugPrint("Erro ao buscar dados: $e");
      return {};
    }
  }

  // --- LÓGICA DE ACTIONS (Criar/Editar/Apagar) ---
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
      if (mounted) setState(() {});
    });
  }

  Future<void> _deletarAvaliacao(String idAvaliacao) async {
    await FirebaseDatabase.instance
        .ref()
        .child('antropometria/${widget.pacienteId}/$idAvaliacao')
        .remove();
    setState(() {});
  }

  void _confirmarExclusao(String idAvaliacao, String dataFormatada) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Apagar Avaliação"),
            content: Text("Deseja apagar a avaliação de $dataFormatada?"),
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

  String _formatarDataSimples(String? isoString) {
    if (isoString == null) return "--/--";
    try {
      final data = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(data);
    } catch (e) {
      return isoString;
    }
  }

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
                      // Usa a cor do tema ou vermelho
                      color: isDeleteMode ? Colors.red : corTema,
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: corTema),
                          );
                        }
                        if (!snapshot.hasData ||
                            snapshot.data?.snapshot.value == null) {
                          return const Center(
                            child: Text("Nenhuma avaliação."),
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
                            final dataFormatada = _formatarDataSimples(
                              item['data'],
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isDeleteMode
                                        ? Colors.red.withOpacity(0.1)
                                        : corTema.withOpacity(0.1),
                                child: Icon(
                                  isDeleteMode
                                      ? Icons.delete_outline
                                      : Icons.edit,
                                  color: isDeleteMode ? Colors.red : corTema,
                                  size: 20,
                                ),
                              ),
                              title: Text("Avaliação de $dataFormatada"),
                              subtitle: Text(
                                "Peso: ${item['massaCorporal']}kg",
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                if (isDeleteMode) {
                                  _confirmarExclusao(
                                    item['key'],
                                    dataFormatada,
                                  );
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
                title: const Text("Atualizar antiga"),
                enabled: _existeAvaliacao,
                onTap: () {
                  Navigator.pop(context);
                  _mostrarSeletorDeAvaliacoes(isDeleteMode: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text("Nova avaliação"),
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

  // --- WIDGETS DE UI ---
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
    // Animação suave de cor se quiser, ou troca direta:
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
              // MUDANÇA AQUI: Usa corTema se selecionado
              color: isSelected ? corTema : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MUDANÇA AQUI: Fundo muda conforme tema
      backgroundColor: corTema,
      appBar: AppBar(
        title: Text(
          _abaSelecionada == 0 ? "Última Avaliação" : "Histórico de Planos",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // MUDANÇA AQUI: AppBar muda conforme tema
        backgroundColor: corTema,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // MUDANÇA AQUI: FAB muda conforme tema
      floatingActionButton:
          _abaSelecionada == 0
              ? FloatingActionButton(
                onPressed: _mostrarOpcoes,
                backgroundColor: corTema,
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
                      _buildToggleSwitch(),
                      // Passamos o corTema para os filhos
                      if (_abaSelecionada == 0)
                        AntropometriaTab(
                          nomePaciente: nome,
                          avaliacao: avaliacao,
                          primaryColor: corTema, // ROXO
                        )
                      else
                        PlanosAlimentaresTab(
                          paciente: _pacienteObjeto,
                          primaryColor: corTema, // VERDE
                        ),
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
}
