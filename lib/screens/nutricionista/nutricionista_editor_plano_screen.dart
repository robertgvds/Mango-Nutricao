import 'package:app/classes/plano_alimentar.dart';
import 'package:app/database/taco_db.dart';
import 'package:flutter/material.dart';
import '../../classes/refeicao.dart';
import '../../classes/alimento.dart';
import '../../database/plano_alimentar_repository.dart';
import '../../widgets/app_colors.dart';

class NutricionistaEditorPlanoScreen extends StatefulWidget {
  final String pacienteId;
  final PlanoAlimentar? plano;

  const NutricionistaEditorPlanoScreen({
    super.key,
    required this.pacienteId,
    this.plano,
  });

  @override
  State<NutricionistaEditorPlanoScreen> createState() =>
      _NutricionistaEditorPlanoScreenState();
}

class _NutricionistaEditorPlanoScreenState
    extends State<NutricionistaEditorPlanoScreen> {
  final _repo = PlanoAlimentarRepository();
  final _nomePlanoController = TextEditingController();

  late PlanoAlimentar _planoEmEdicao;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.plano != null) {
      _planoEmEdicao = widget.plano!;
      _nomePlanoController.text = _planoEmEdicao.nome;
    } else {
      _planoEmEdicao = PlanoAlimentar(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: "",
        dataCriacao: DateTime.now(),
        refeicoes: [],
      );
    }
  }

  Future<void> _salvarPlano() async {
    if (_nomePlanoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dê um nome ao plano")),
      );
      return;
    }

    setState(() => _isSaving = true);
    _planoEmEdicao.nome = _nomePlanoController.text;

    try {
      await _repo.salvarPlano(widget.pacienteId, _planoEmEdicao);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Salvo com sucesso!"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Modal Nova Refeição ---
  void _addRefeicao() {
    final nomeCtrl = TextEditingController();
    final horaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Refeição'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome', hintText: 'Ex: Lanche'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: horaCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Horário', prefixIcon: Icon(Icons.access_time)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  horaCtrl.text =
                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.isNotEmpty && horaCtrl.text.isNotEmpty) {
                setState(() {
                  _planoEmEdicao.refeicoes.add(Refeicao(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nome: nomeCtrl.text,
                    horario: horaCtrl.text,
                    alimentos: [],
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Criar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verde,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          )
        ],
      ),
    );
  }

  // --- Abre o Modal de Seleção ---
  void _abrirSelecaoAlimento(Refeicao refeicao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AlimentoSelectionModal(
        onAlimentoSelected: (alimento) {
          // O setState aqui atualiza a tela principal (NutricionistaEditorPlanoScreen)
          setState(() => refeicao.alimentos.add(alimento));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verde,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _salvarPlano,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verde,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text("CONCLUIR E SALVAR",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        elevation: 0,
        title:
            const Text('Editar Plano', style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nomePlanoController,
                    decoration: InputDecoration(
                      labelText: "Nome do Plano",
                      hintText: "Ex: Hipertrofia",
                      prefixIcon: const Icon(Icons.edit, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Refeições",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _addRefeicao,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Adicionar Refeição"),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.verde),
                      )
                    ],
                  ),
                  if (_planoEmEdicao.refeicoes.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text("Nenhuma refeição adicionada.")),
                  ...(_planoEmEdicao.refeicoes
                        ..sort((a, b) => a.horario.compareTo(b.horario)))
                      .map((ref) => Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppColors.cinzaClaro, width: 1),
                            ),
                            
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(ref.nome,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(ref.horario),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => setState(() =>
                                          _planoEmEdicao.refeicoes.remove(ref)),
                                    ),
                                  ),
                                  const Divider(),
                                  if (ref.alimentos.isEmpty)
                                    const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text("Sem alimentos",
                                            style:
                                                TextStyle(color: Colors.grey))),
                                  ...ref.alimentos.map((ali) => ListTile(
                                        visualDensity: VisualDensity.compact,
                                        title: Text(ali.nome),
                                        subtitle: Text(
                                            "${ali.quantidade.toStringAsFixed(0)}g • ${ali.totalCalorias.toStringAsFixed(0)} kcal"),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.close,
                                              size: 16, color: Colors.grey),
                                          onPressed: () => setState(() =>
                                              ref.alimentos.remove(ali)),
                                        ),
                                      )),
                                  TextButton(
                                      onPressed: () =>
                                          _abrirSelecaoAlimento(ref),
                                      child: const Text("ADICIONAR ALIMENTO"),
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppColors.verde,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        minimumSize: const Size(400, 40),
                                      )),
                                ],
                              ),
                            ),
                          )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DO MODAL DE SELEÇÃO COM PESQUISA ---
class _AlimentoSelectionModal extends StatefulWidget {
  final Function(Alimento) onAlimentoSelected;

  const _AlimentoSelectionModal({required this.onAlimentoSelected});

  @override
  State<_AlimentoSelectionModal> createState() =>
      _AlimentoSelectionModalState();
}

class _AlimentoSelectionModalState extends State<_AlimentoSelectionModal> {
  String _searchText = "";
  List<Alimento> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _filteredList = TacoDB.list; // Carrega lista inicial
  }

  void _filter(String text) {
    setState(() {
      _searchText = text;
      _filteredList = TacoDB.list
          .where((ali) => ali.nome.toLowerCase().contains(text.toLowerCase()))
          .toList();
    });
  }

  void _abrirCriacaoPersonalizada() async {
    // Navega para tela de criação e espera o resultado
    final Alimento? novo = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _CriarAlimentoScreen()),
    );

    if (novo != null) {
      // Se criou, seleciona automaticamente e fecha o modal
      if (!mounted) return;
      Navigator.pop(context); // Fecha o modal atual
      widget.onAlimentoSelected(novo); // Envia para o plano
    }
  }

  void _confirmarQtd(Alimento base) {
    final ctrl = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(base.nome),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Quantidade (g)', suffixText: 'g'),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        actions: [
          ElevatedButton(
              onPressed: () {
                double qtd = double.tryParse(ctrl.text) ?? 100;
                final novo = Alimento(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nome: base.nome,
                    calorias: base.calorias,
                    proteinas: base.proteinas,
                    carboidratos: base.carboidratos,
                    gorduras: base.gorduras,
                    quantidade: qtd,
                    unidade: 'g',
                    categoria: base.categoria);
                
                // CORREÇÃO AQUI:
                Navigator.pop(ctx); // 1. Fecha o DIALOG
                widget.onAlimentoSelected(novo); // 2. Adiciona o alimento
                Navigator.pop(context); // 3. Fecha o MODAL (BottomSheet)
              },
              child: const Text("Adicionar"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      height: MediaQuery.of(context).size.height * 0.85, // Quase tela cheia
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra cinza superior
          Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 15),

          const Text("Adicionar Alimento",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // --- BARRA DE PESQUISA ---
          TextField(
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: "Pesquisar (ex: Frango, Arroz...)",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF5F5F5), // Cinza claro
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),

          const SizedBox(height: 10),

          // --- BOTÃO PERSONALIZADO ---
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _abrirCriacaoPersonalizada,
              icon: const Icon(Icons.edit_note, color: AppColors.verde),
              label: const Text("Criar Alimento Personalizado"),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.verde,
                foregroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const Divider(height: 25),

          // --- LISTA FILTRADA ---
          Expanded(
            child: _filteredList.isEmpty
                ? const Center(child: Text("Nenhum alimento encontrado."))
                : ListView.builder(
                    itemCount: _filteredList.length,
                    itemBuilder: (ctx, idx) {
                      final item = _filteredList[idx];
                      return ListTile(
                        dense: true,
                        title: Text(item.nome),
                        subtitle: Text("${item.calorias} kcal / 100g"),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: AppColors.verde),
                        onTap: () => _confirmarQtd(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- TELA DE CRIAÇÃO DE ALIMENTO PERSONALIZADO ---
class _CriarAlimentoScreen extends StatefulWidget {
  const _CriarAlimentoScreen();

  @override
  State<_CriarAlimentoScreen> createState() => _CriarAlimentoScreenState();
}

class _CriarAlimentoScreenState extends State<_CriarAlimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _caloriasCtrl = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _gordCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController(text: "100");

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      // Cria o alimento
      final novo = Alimento(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeCtrl.text,
        categoria: 'Personalizado',
        calorias: double.tryParse(_caloriasCtrl.text) ?? 0,
        proteinas: double.tryParse(_protCtrl.text) ?? 0,
        carboidratos: double.tryParse(_carbCtrl.text) ?? 0,
        gorduras: double.tryParse(_gordCtrl.text) ?? 0,
        quantidade:
            double.tryParse(_qtdCtrl.text) ?? 100, // Quantidade que será consumida
        unidade: 'g',
      );

      // Retorna para o modal anterior
      Navigator.pop(context, novo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verde,
      appBar: AppBar(
        title: const Text("Novo Alimento"),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
      ),
      body: Form(
        // CORREÇÃO IMPORTANTE: Envolvendo com Form para o validate() funcionar
        key: _formKey,
        child: CustomScrollView(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: const InputDecoration(
                          labelText: "Nome do Alimento",
                          hintText: "Ex: Whey Protein"),
                      validator: (v) =>
                          v!.isEmpty ? "Campo obrigatório" : null,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _caloriasCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: "Kcal (em 100g)"),
                            validator: (v) =>
                                v!.isEmpty ? "Obrigatório" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _qtdCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: "Qtd Consumida (g)"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text("Macronutrientes (por 100g)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _buildMacroInput(_carbCtrl, "Carb (g)")),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildMacroInput(_protCtrl, "Prot (g)")),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildMacroInput(_gordCtrl, "Gord (g)")),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verde,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("ADICIONAR AO PLANO"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInput(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}