import 'package:app/classes/plano_alimentar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_colors.dart';
import '../../classes/refeicao.dart';
import '../../database/plano_alimentar_repository.dart';

class PacientePlanoAlimentarScreen extends StatefulWidget {
  const PacientePlanoAlimentarScreen({super.key});

  @override
  State<PacientePlanoAlimentarScreen> createState() =>
      _PacientePlanoAlimentarScreenState();
}

class _PacientePlanoAlimentarScreenState
    extends State<PacientePlanoAlimentarScreen> {
  final _repo = PlanoAlimentarRepository();
  bool _isLoading = true;
  List<PlanoAlimentar> _todosPlanos = [];
  PlanoAlimentar? _planoAtual;
  
  String _idUsadoParaBusca = "Buscando...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final user = authService.usuario;

      String? idFinal;

      if (user != null) {
        dynamic u = user;
        try {
          idFinal = u.id; // Tenta .id (Classe Usuario)
        } catch (e) {
          try {
            idFinal = u.uid; // Tenta .uid (Firebase User)
          } catch (e2) {
            debugPrint("Não foi possível ler ID ou UID do usuário.");
          }
        }
      }

      // Se quiser forçar para testes, descomente a linha abaixo:
      // if (idFinal == null) idFinal = "uGFqVcMBdNVRQzaWs0cnmlSlBmw2";

      if (idFinal != null) {
        setState(() => _idUsadoParaBusca = idFinal!);
        // Busca no Firebase
        final lista = await _repo.listarPlanos(idFinal);

        if (mounted) {
          setState(() {
            _todosPlanos = lista;
            if (lista.isNotEmpty) {
              _planoAtual = lista.first;
            }
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _idUsadoParaBusca = "Nenhum Usuário Logado";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verde,
      appBar: AppBar(
        backgroundColor: AppColors.verde,
        elevation: 0,
        title: const Text(
          'Plano Alimentar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : CustomScrollView(
              slivers: [
                // 1. O botão fica dentro de um SliverToBoxAdapter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exportando PDF...')),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        label: const Text('Exportar como PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeEscuro, // Ou uma cor mais escura definida
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. A parte branca usa SliverFillRemaining
                SliverFillRemaining(
                  hasScrollBody: false, // IMPORTANTE: Isso evita o erro de layout overflow
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
                        if (_planoAtual == null)
                          _buildSemPlano()
                        else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Refeições',
                                style: TextStyle(
                                  color: AppColors.verde,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _planoAtual!.nome,
                                style: TextStyle(
                                  color: Colors.grey[600], 
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Renderiza os Cards das refeições usando MAP (sem ListView aninhado)
                          if (_planoAtual!.refeicoes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: Text("Nenhuma refeição neste plano.")),
                            )
                          else
                            ..._planoAtual!.refeicoes.map((ref) => _buildRefeicaoCardStyle(ref)),
                        ],

                        // Se quiser mostrar histórico abaixo:
                        if (_todosPlanos.length > 1) ...[
                           const SizedBox(height: 30),
                           const Divider(),
                           const Padding(
                             padding: EdgeInsets.symmetric(vertical: 10),
                             child: Text("Histórico", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                           ),
                           ..._todosPlanos.skip(1).map((antigo) => ListTile(
                             leading: const Icon(Icons.history, color: Colors.grey),
                             title: Text(antigo.nome),
                             subtitle: Text("Data: ${_formatDate(antigo.dataCriacao)}"),
                             onTap: () => _mostrarDetalhesPlanoAntigo(antigo),
                           ))
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSemPlano() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text(
              "Nenhum plano alimentar encontrado.",
              style: TextStyle(color: Colors.grey),
            ),
            Text("ID: $_idUsadoParaBusca", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- CARD NO ESTILO SOLICITADO ---
  Widget _buildRefeicaoCardStyle(Refeicao refeicao) {
    // Usando getters da sua classe ou calculando na hora
    double cal = refeicao.totalCalorias;
    double prot = refeicao.totalProteinas;
    double carb = refeicao.totalCarboidratos;
    double gord = refeicao.totalGorduras;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.verde.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: AppColors.verde),
          ),
          title: Text(
            refeicao.nome,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${refeicao.horario} • ${cal.toStringAsFixed(0)} kcal',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          children: [
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: [
                  // Resumo Macros
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge("Carb", "${carb.toStringAsFixed(1)}g", Colors.orange),
                      _buildMacroBadge("Prot", "${prot.toStringAsFixed(1)}g", Colors.blue),
                      _buildMacroBadge("Gord", "${gord.toStringAsFixed(1)}g", Colors.red),
                    ],
                  ),
                  const Divider(height: 20),
                  // Lista de alimentos
                  if (refeicao.alimentos.isEmpty)
                    const Text("Sem alimentos", style: TextStyle(color: Colors.grey))
                  else
                    ...refeicao.alimentos.map((alimento) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(alimento.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("${alimento.calorias} kcal / 100g"),
                      trailing: Text(
                        "${alimento.quantidade.toStringAsFixed(0)}g",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.verde),
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text("$label: $value", style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _mostrarDetalhesPlanoAntigo(PlanoAlimentar plano) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text(plano.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.verde)),
              Text("Plano de ${_formatDate(plano.dataCriacao)}", style: const TextStyle(color: Colors.grey)),
              const Divider(height: 30),
              ...plano.refeicoes.map((ref) => _buildRefeicaoCardStyle(ref)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}";
  }
}