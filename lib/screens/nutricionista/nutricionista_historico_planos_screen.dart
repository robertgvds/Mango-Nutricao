import 'package:flutter/material.dart';
import '../../classes/paciente.dart';
import '../../classes/planoalimentar.dart';
import '../../widgets/app_colors.dart';
import '../../database/plano_alimentar_repository.dart';
import 'nutricionista_editor_plano_screen.dart';

class NutricionistaHistoricoPlanosScreen extends StatefulWidget {
  final Paciente paciente;
  final bool
  isEmbedded; // True = Dentro da Aba (sem Scaffold), False = Tela Cheia
  final Color? primaryColor; // Cor do tema

  const NutricionistaHistoricoPlanosScreen({
    super.key,
    required this.paciente,
    this.isEmbedded = false,
    this.primaryColor,
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
    try {
      final lista = await _repo.listarPlanos(widget.paciente.id!);
      if (mounted) {
        setState(() {
          _planos = lista;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro: $e");
      if (mounted) setState(() => _isLoading = false);
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
        builder:
            (context) => NutricionistaEditorPlanoScreen(
              pacienteId: widget.paciente.id!,
              plano: planoExistente,
            ),
      ),
    ).then((_) => _carregarPlanos());
  }

  // Widget auxiliar para montar cada item da lista (CARD)
  Widget _buildCardItem(PlanoAlimentar plano, Color corTema, int index) {
    final bool isAtual = index == 0;
    return Card(
      elevation: isAtual ? 2 : 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side:
            isAtual
                ? BorderSide(color: corTema, width: 2)
                : BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAtual ? corTema : Colors.grey[300],
          child: Icon(
            isAtual ? Icons.star : Icons.history,
            color: Colors.white,
          ),
        ),
        title: Text(
          plano.nome.isNotEmpty ? plano.nome : "Plano Sem Nome",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isAtual ? Colors.black : Colors.grey[700],
          ),
        ),
        subtitle: Text(
          "${isAtual ? 'Plano Atual • ' : ''}Criado em ${_formatDate(plano.dataCriacao)}",
          style: TextStyle(
            color: isAtual ? corTema : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'editar') _abrirEditor(planoExistente: plano);
            if (value == 'excluir') _excluirPlano(plano.id);
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Text("Editar / Visualizar"),
                ),
                const PopupMenuItem(
                  value: 'excluir',
                  child: Text("Excluir", style: TextStyle(color: Colors.red)),
                ),
              ],
        ),
        onTap: () => _abrirEditor(planoExistente: plano),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color corTema = widget.primaryColor ?? AppColors.verde;

    // 1. Estado de Carregamento
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: corTema));
    }

    // 2. Estado Vazio (Reutilizável)
    Widget emptyState = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text(
              "Nenhum plano cadastrado.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    // 3. Botão de Criar (Reutilizável)
    Widget botaoCriar = SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _abrirEditor(),
        icon: const Icon(Icons.add),
        label: const Text("CRIAR NOVO PLANO"),
        style: ElevatedButton.styleFrom(
          backgroundColor: corTema,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
        ),
      ),
    );

    // ============================================================
    // LAYOUT A: EMBUTIDO (DENTRO DA ABA)
    // SOLUÇÃO DO ERRO: Usamos Column em vez de ListView
    // ============================================================
    if (widget.isEmbedded) {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            if (_planos.isEmpty)
              emptyState
            else
              // Aqui está a correção: Geramos a lista dentro de uma Column.
              // Isso remove o "ShrinkWrappingViewport" problemático.
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: List.generate(_planos.length, (index) {
                    return _buildCardItem(_planos[index], corTema, index);
                  }),
                ),
              ),
            const SizedBox(height: 10),
            botaoCriar,
          ],
        ),
      );
    }

    // ============================================================
    // LAYOUT B: TELA CHEIA (STANDALONE)
    // ============================================================
    return Scaffold(
      backgroundColor: corTema,
      appBar: AppBar(
        title: const Text(
          "Plano Alimentar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corTema,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Text(
                    "Planos de ${widget.paciente.nome}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: corTema,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista com Expanded (pode scrollar internamente aqui)
                  Expanded(
                    child:
                        _planos.isEmpty
                            ? emptyState
                            : ListView.builder(
                              itemCount: _planos.length,
                              itemBuilder:
                                  (context, index) => _buildCardItem(
                                    _planos[index],
                                    corTema,
                                    index,
                                  ),
                            ),
                  ),

                  const SizedBox(height: 10),
                  botaoCriar,
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
