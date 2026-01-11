import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../classes/antropometria.dart';
import '../../database/antropometria_repository.dart';
import '../../widgets/app_colors.dart';

class NutricionistaAntropometriaScreen extends StatefulWidget {
  final String pacienteId;

  const NutricionistaAntropometriaScreen({super.key, required this.pacienteId});

  @override
  State<NutricionistaAntropometriaScreen> createState() =>
      _NutricionistaAntropometriaScreenState();
}

class _NutricionistaAntropometriaScreenState
    extends State<NutricionistaAntropometriaScreen> {
  // Repositório e Variáveis de Estado
  final AntropometriaRepository _repository = AntropometriaRepository();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  String _generoPaciente = 'Masculino';
  List<Antropometria> _historico = [];

  // Variáveis de Edição
  String? _idAvaliacaoEmEdicao;
  DateTime? _dataOriginalEmEdicao;

  // Controllers
  final _obsCtrl = TextEditingController();
  final _massaCorporalCtrl = TextEditingController();
  final _massaGorduraCtrl = TextEditingController();
  final _percentualGorduraCtrl = TextEditingController();
  final _imcCtrl = TextEditingController();
  final _cmbCtrl = TextEditingController();
  final _rcqCtrl = TextEditingController();

  // Classificações (Valores Padrão)
  String _classMassaCorporal = 'Ideal';
  String _classMassaGordura = 'Ideal';
  String _classPercentualGordura = 'Ideal';
  String _classImc = 'Ideal';
  String _classCmb = 'Ideal';
  String _classRcq = 'Ideal';

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  // --- CARREGAMENTO DE DADOS ---
  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    try {
      // 1. Busca gênero do usuário para cálculos de referência
      final snapshot =
          await FirebaseDatabase.instance
              .ref('usuarios/${widget.pacienteId}')
              .get();

      if (snapshot.exists) {
        final dados = snapshot.value as Map;
        setState(() {
          _generoPaciente = dados['genero'] ?? 'Masculino';
        });
      }

      // 2. Busca histórico via Repositório
      final lista = await _repository.buscarHistorico(widget.pacienteId);

      // Ordena por data (mais recente primeiro)
      lista.sort(
        (a, b) =>
            (b.data ?? DateTime.now()).compareTo(a.data ?? DateTime.now()),
      );

      setState(() {
        _historico = lista;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE NEGÓCIO ---

  void _calcularSugestaoAutomatica(String tipo, String valorTexto) {
    if (valorTexto.isEmpty) return;
    double? valor = double.tryParse(valorTexto.replaceAll(',', '.'));
    if (valor == null) return;

    String sugestao = 'Ideal';
    bool isFem = _generoPaciente == 'Feminino';

    switch (tipo) {
      case 'IMC':
        if (valor < 18.5)
          sugestao = 'Abaixo';
        else if (valor >= 25.0)
          sugestao = 'Acima';
        setState(() => _classImc = sugestao);
        break;
      case 'Gordura':
        double min = isFem ? 18.0 : 10.0;
        double max = isFem ? 28.0 : 20.0;
        if (valor < min)
          sugestao = 'Abaixo';
        else if (valor > max)
          sugestao = 'Acima';
        setState(() => _classPercentualGordura = sugestao);
        break;
      case 'MassaGorda':
        if (valor < 5)
          sugestao = 'Abaixo';
        else if (valor > 30)
          sugestao = 'Acima';
        setState(() => _classMassaGordura = sugestao);
        break;
      case 'RCQ':
        double limiteAlto = isFem ? 0.85 : 0.95;
        double limiteBaixo = isFem ? 0.70 : 0.80;
        if (valor > limiteAlto)
          sugestao = 'Acima';
        else if (valor < limiteBaixo)
          sugestao = 'Abaixo';
        setState(() => _classRcq = sugestao);
        break;
      case 'CMB':
        double min = isFem ? 20.0 : 23.0;
        double max = isFem ? 29.0 : 34.0;
        if (valor < min)
          sugestao = 'Abaixo';
        else if (valor > max)
          sugestao = 'Acima';
        setState(() => _classCmb = sugestao);
        break;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    DateTime dataFinal =
        (_idAvaliacaoEmEdicao != null && _dataOriginalEmEdicao != null)
            ? _dataOriginalEmEdicao!
            : DateTime.now();

    final novaAvaliacao = Antropometria(
      id_avaliacao: _idAvaliacaoEmEdicao,
      massaCorporal: double.tryParse(
        _massaCorporalCtrl.text.replaceAll(',', '.'),
      ),
      massaGordura: double.tryParse(
        _massaGorduraCtrl.text.replaceAll(',', '.'),
      ),
      percentualGordura: double.tryParse(
        _percentualGorduraCtrl.text.replaceAll(',', '.'),
      ),
      massaEsqueletica: null, // Campo removido na branch dados-cadastro
      imc: double.tryParse(_imcCtrl.text.replaceAll(',', '.')),
      cmb: double.tryParse(_cmbCtrl.text.replaceAll(',', '.')),
      relacaoCinturaQuadril: double.tryParse(
        _rcqCtrl.text.replaceAll(',', '.'),
      ),

      // Classificações
      classMassaCorporal: _classMassaCorporal,
      classMassaGordura: _classMassaGordura,
      classPercentualGordura: _classPercentualGordura,
      classMassaEsqueletica: null,
      classImc: _classImc,
      classCmb: _classCmb,
      classRcq: _classRcq,

      observacoes: _obsCtrl.text,
      data: dataFinal,
    );

    await _repository.salvarAvaliacao(widget.pacienteId, novaAvaliacao);

    _limparCampos();
    await _carregarDadosIniciais();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Salvo com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deletarAvaliacao(String idAvaliacao) async {
    try {
      await _repository.excluirAvaliacao(widget.pacienteId, idAvaliacao);
      await _carregarDadosIniciais();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avaliação excluída.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    }
  }

  void _limparCampos() {
    setState(() {
      _idAvaliacaoEmEdicao = null;
      _dataOriginalEmEdicao = null;
      _classMassaCorporal =
          _classMassaGordura =
              _classPercentualGordura =
                  _classImc = _classCmb = _classRcq = 'Ideal';
    });
    _massaCorporalCtrl.clear();
    _massaGorduraCtrl.clear();
    _percentualGorduraCtrl.clear();
    _imcCtrl.clear();
    _cmbCtrl.clear();
    _rcqCtrl.clear();
    _obsCtrl.clear();
  }

  void _carregarParaEdicao(Antropometria item) {
    setState(() {
      _idAvaliacaoEmEdicao = item.id_avaliacao;
      _dataOriginalEmEdicao = item.data;

      _classMassaCorporal = item.classMassaCorporal ?? 'Ideal';
      _classMassaGordura = item.classMassaGordura ?? 'Ideal';
      _classPercentualGordura = item.classPercentualGordura ?? 'Ideal';
      _classImc = item.classImc ?? 'Ideal';
      _classCmb = item.classCmb ?? 'Ideal';
      _classRcq = item.classRcq ?? 'Ideal';
    });

    _massaCorporalCtrl.text = item.massaCorporal?.toString() ?? '';
    _massaGorduraCtrl.text = item.massaGordura?.toString() ?? '';
    _percentualGorduraCtrl.text = item.percentualGordura?.toString() ?? '';
    _imcCtrl.text = item.imc?.toString() ?? '';
    _cmbCtrl.text = item.cmb?.toString() ?? '';
    _rcqCtrl.text = item.relacaoCinturaQuadril?.toString() ?? '';
    _obsCtrl.text = item.observacoes ?? '';
  }

  // --- INTERFACE (BUILD) ---

  @override
  Widget build(BuildContext context) {
    String dataExibida =
        _dataOriginalEmEdicao != null
            ? DateFormat('dd/MM/yyyy').format(_dataOriginalEmEdicao!)
            : DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.roxo,
      appBar: AppBar(
        backgroundColor: AppColors.roxo,
        elevation: 0,
        title: const Text(
          'Avaliação Antropométrica',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildHeaderCard(dataExibida),
                        const SizedBox(height: 25),

                        _buildSecaoTitulo(),
                        const SizedBox(height: 15),

                        // Campos de Input
                        _buildInputComStatus(
                          'Massa Corporal (kg)',
                          _massaCorporalCtrl,
                          _classMassaCorporal,
                          (val) => setState(() => _classMassaCorporal = val),
                          null,
                        ),
                        _buildInputComStatus(
                          'Massa de Gordura (kg)',
                          _massaGorduraCtrl,
                          _classMassaGordura,
                          (val) => setState(() => _classMassaGordura = val),
                          (v) => _calcularSugestaoAutomatica('MassaGorda', v),
                        ),
                        _buildInputComStatus(
                          'Percentual Gordura (%)',
                          _percentualGorduraCtrl,
                          _classPercentualGordura,
                          (val) =>
                              setState(() => _classPercentualGordura = val),
                          (v) => _calcularSugestaoAutomatica('Gordura', v),
                        ),
                        _buildInputComStatus(
                          'IMC (kg/m²)',
                          _imcCtrl,
                          _classImc,
                          (val) => setState(() => _classImc = val),
                          (v) => _calcularSugestaoAutomatica('IMC', v),
                        ),
                        _buildInputComStatus(
                          'Relação Cintura/Quadril',
                          _rcqCtrl,
                          _classRcq,
                          (val) => setState(() => _classRcq = val),
                          (v) => _calcularSugestaoAutomatica('RCQ', v),
                        ),
                        _buildInputComStatus(
                          'CMB (cm)',
                          _cmbCtrl,
                          _classCmb,
                          (val) => setState(() => _classCmb = val),
                          (v) => _calcularSugestaoAutomatica('CMB', v),
                        ),

                        const SizedBox(height: 20),
                        _buildBotoesAcao(),

                        const SizedBox(height: 30),
                        _buildHistoricoList(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderCard(String data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _idAvaliacaoEmEdicao != null
                    ? 'Editando Avaliação'
                    : 'Nova Avaliação',
                style: const TextStyle(
                  color: AppColors.roxo,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(data, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _obsCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Observações...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoTitulo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Classificação dos Índices',
              style: TextStyle(
                color: AppColors.roxo,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Perfil: $_generoPaciente',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: AppColors.roxo),
          onPressed: () => _mostrarLegenda(context),
        ),
      ],
    );
  }

  Widget _buildInputComStatus(
    String label,
    TextEditingController ctrl,
    String statusAtual,
    Function(String) onStatusChanged,
    Function(String)? onChangedInput,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                height: 35,
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: onChangedInput,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(bottom: 10),
                    hintText: '0.0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChoiceChip(
                'Abaixo',
                const Color(0xFF5E6EE6),
                statusAtual,
                onStatusChanged,
              ),
              _buildChoiceChip(
                'Ideal',
                const Color(0xFF4CAF50),
                statusAtual,
                onStatusChanged,
              ),
              _buildChoiceChip(
                'Acima',
                const Color(0xFFFF7043),
                statusAtual,
                onStatusChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    Color color,
    String current,
    Function(String) onSelect,
  ) {
    bool selected = current == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_idAvaliacaoEmEdicao != null)
          TextButton(
            onPressed: _limparCampos,
            child: const Text(
              'Cancelar Edição',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoricoList() {
    if (_historico.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico',
          style: TextStyle(
            color: AppColors.roxo,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _historico.length,
          itemBuilder: (ctx, i) => _buildHistoricoItem(_historico[i]),
        ),
      ],
    );
  }

  Widget _buildHistoricoItem(Antropometria item) {
    return Dismissible(
      key: Key(item.id_avaliacao ?? DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("Confirmar Exclusão"),
                content: const Text(
                  "Deseja realmente apagar esta avaliação do histórico?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      "Apagar",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) {
        if (item.id_avaliacao != null) {
          _deletarAvaliacao(item.id_avaliacao!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(item.data!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Peso: ${item.massaCorporal ?? '-'} | IMC: ${item.imc ?? '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => _carregarParaEdicao(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roxo,
                minimumSize: const Size(60, 30),
              ),
              child: const Text(
                'Editar',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarLegenda(BuildContext context) {
    bool isFem = _generoPaciente == 'Feminino';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Referência (${_generoPaciente})",
              style: const TextStyle(
                color: AppColors.roxo,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabelaRow("IMC", "< 18.5", "18.5-24.9", "≥ 25.0"),
                  _buildTabelaRow(
                    "% Gordura",
                    isFem ? "< 18%" : "< 10%",
                    isFem ? "18-28%" : "10-20%",
                    isFem ? "> 28%" : "> 20%",
                  ),
                  _buildTabelaRow(
                    "RCQ",
                    isFem ? "< 0.70" : "< 0.80",
                    isFem ? "0.70-0.85" : "0.80-0.95",
                    isFem ? "> 0.85" : "> 0.95",
                  ),
                  _buildTabelaRow(
                    "CMB",
                    isFem ? "< 20" : "< 23",
                    isFem ? "20-29" : "23-34",
                    isFem ? "> 29" : "> 34",
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fechar"),
              ),
            ],
          ),
    );
  }

  Widget _buildTabelaRow(String label, String b, String i, String a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.roxo,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _badge(b, const Color(0xFF5E6EE6)),
              _badge(i, const Color(0xFF4CAF50)),
              _badge(a, const Color(0xFFFF7043)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String txt, Color c) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      txt,
      style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold),
    ),
  );
}
