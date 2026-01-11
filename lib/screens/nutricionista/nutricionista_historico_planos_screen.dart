import 'package:app/classes/plano_alimentar.dart';
import 'package:app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import '../../classes/paciente.dart';
import '../../database/plano_alimentar_repository.dart';
import 'nutricionista_editor_plano_screen.dart';

class NutricionistaHistoricoPlanosScreen extends StatefulWidget {
  final Paciente paciente;

  const NutricionistaHistoricoPlanosScreen({
    super.key,
    required this.paciente,
  });

  @override
  State<NutricionistaHistoricoPlanosScreen> createState() =>
      _NutricionistaHistoricoPlanosScreenState();
}

class _NutricionistaHistoricoPlanosScreenState
    extends State<NutricionistaHistoricoPlanosScreen> {
  final PlanoAlimentarRepository _repo = PlanoAlimentarRepository();
  List<PlanoAlimentar> _planos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    setState(() => _isLoading = true);
    final lista = await _repo.listarPlanos(widget.paciente.id!);

    if (mounted) {
      setState(() {
        _planos = lista;
        _isLoading = false;
      });
    }
  }

  Future<void> _excluirPlano(String planoId) async {
    await _repo.excluirPlano(widget.paciente.id!, planoId);
    _carregarPlanos();
  }

  void _abrirEditor({PlanoAlimentar? planoExistente}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutricionistaEditorPlanoScreen(
          pacienteId: widget.paciente.id!,
          plano: planoExistente,
        ),
      ),
    ).then((_) => _carregarPlanos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Define a cor de fundo no Scaffold para cobrir a área atrás do container branco
      backgroundColor: AppColors.verde,
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Plano Alimentar",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0, // Remove sombra para mesclar com o fundo
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // Expanded faz o Container branco ocupar todo o espaço restante da tela
                Expanded(
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
                        horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Planos de ${widget.paciente.nome}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: AppColors.verde),
                        ),
                        const SizedBox(height: 20),
                        // Lista de Planos (Ocupa o espaço disponível)
                        Expanded(
                          child: _planos.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.assignment_outlined,
                                          size: 60, color: Colors.grey[300]),
                                      const SizedBox(height: 10),
                                      const Text("Nenhum plano cadastrado.",
                                          style:
                                              TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  // Padding extra em baixo para a lista não ficar atrás do botão
                                  padding: const EdgeInsets.only(bottom: 80),
                                  itemCount: _planos.length,
                                  itemBuilder: (context, index) {
                                    final plano = _planos[index];
                                    final isAtual = index == 0;

                                    return Card(
                                      elevation: isAtual ? 2 : 1,
                                      color: AppColors.branco,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          side: isAtual
                                              ? const BorderSide(
                                                  color: AppColors.verde,
                                                  width: 2)
                                              : BorderSide(color: AppColors.cinzaClaro, width: 1)),
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor: isAtual
                                              ? AppColors.verde
                                              : Colors.grey[300],
                                          child: Icon(
                                              isAtual
                                                  ? Icons.star
                                                  : Icons.history,
                                              color: Colors.white),
                                        ),
                                        title: Text(
                                          plano.nome.isNotEmpty
                                              ? plano.nome
                                              : "Plano Sem Nome",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isAtual
                                                ? Colors.black
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        subtitle: Text(
                                          "${isAtual ? 'Plano Atual • ' : ''}Criado em ${_formatDate(plano.dataCriacao)}",
                                          style: TextStyle(
                                              color: isAtual
                                                  ? AppColors.verde
                                                  : Colors.grey,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'editar')
                                              _abrirEditor(
                                                  planoExistente: plano);
                                            if (value == 'excluir')
                                              _excluirPlano(plano.id);
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                                value: 'editar',
                                                child: Text(
                                                    "Editar / Visualizar")),
                                            const PopupMenuItem(
                                                value: 'excluir',
                                                child: Text("Excluir",
                                                    style: TextStyle(
                                                        color: Colors.red))),
                                          ],
                                        ),
                                        onTap: () => _abrirEditor(
                                            planoExistente: plano),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        
                        // Botão de Adicionar (Fixo na parte inferior do container branco)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirEditor(),
                              icon: const Icon(Icons.add),
                              label: const Text("CRIAR NOVO PLANO"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verde,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}