import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/app_colors.dart';

// Classes e Repos
import '../../classes/antropometria.dart';
import '../../classes/plano_alimentar.dart';
import '../../classes/refeicao.dart';
import '../../database/antropometria_repository.dart';
import '../../database/plano_alimentar_repository.dart';

// Telas de Edição
import 'nutricionista_antropometria_screen.dart';
import 'nutricionista_editor_plano_screen.dart';

class NutricionistaPerfilPacienteScreen extends StatefulWidget {
  final String pacienteId;

  const NutricionistaPerfilPacienteScreen({super.key, required this.pacienteId});

  @override
  State<NutricionistaPerfilPacienteScreen> createState() =>
      _NutricionistaPerfilPacienteScreenState();
}

class _NutricionistaPerfilPacienteScreenState
    extends State<NutricionistaPerfilPacienteScreen> {
  
  final _antroRepo = AntropometriaRepository();
  final _planoRepo = PlanoAlimentarRepository();

  bool _isLoading = true;
  int _tabSelecionada = 0; // 0 = Antropometria, 1 = Planos

  // Dados
  Map<String, dynamic> _dadosPaciente = {};
  int _idade = 0;
  List<Antropometria> _historicoAntro = [];
  List<PlanoAlimentar> _historicoPlanos = [];

  // Cor Dinâmica
  Color get _corAtiva => _tabSelecionada == 0 ? AppColors.roxo : AppColors.verde;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      // 1. Paciente
      final userSnap = await FirebaseDatabase.instance.ref('usuarios/${widget.pacienteId}').get();
      if (userSnap.exists) {
        _dadosPaciente = Map<String, dynamic>.from(userSnap.value as Map);
        _calcularIdade(_dadosPaciente['dataNascimento']);
      }

      // 2. Antropometria
      final listaAntro = await _antroRepo.buscarHistorico(widget.pacienteId);
      listaAntro.sort((a, b) => (b.data ?? DateTime(2000)).compareTo(a.data ?? DateTime(2000)));
      _historicoAntro = listaAntro.reversed.toList(); // Mais recente no topo (index 0)

      // 3. Planos
      final listaPlanos = await _planoRepo.listarPlanos(widget.pacienteId);
      listaPlanos.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      _historicoPlanos = listaPlanos;

    } catch (e) {
      debugPrint("Erro: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calcularIdade(String? dataNasc) {
    if (dataNasc == null || dataNasc.isEmpty) return;
    try {
      DateTime nascimento;
      if (dataNasc.contains('/')) {
        final parts = dataNasc.split('/');
        nascimento = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else {
        nascimento = DateTime.parse(dataNasc);
      }
      final hoje = DateTime.now();
      int idade = hoje.year - nascimento.year;
      if (hoje.month < nascimento.month || (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
        idade--;
      }
      setState(() => _idade = idade);
    } catch (_) {}
  }

  // --- NAVEGAÇÃO ---

  void _acaoFAB() {
    if (_tabSelecionada == 0) {
      // Criar Antropometria (null)
      _navegarAntropometria(null);
    } else {
      // Criar Plano (null)
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => NutricionistaEditorPlanoScreen(pacienteId: widget.pacienteId, plano: null),
      )).then((_) => _carregarDados());
    }
  }

  // Correção: Agora aceita um item (para edição) ou null (para criação)
  void _navegarAntropometria(Antropometria? item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => NutricionistaAntropometriaScreen(
        pacienteId: widget.pacienteId,
        avaliacaoParaEditar: item, // Passa o objeto para a tela de edição
      ),
    )).then((_) => _carregarDados());
  }

  void _excluirAntropometria(String id) async {
    await _antroRepo.excluirAvaliacao(widget.pacienteId, id);
    _carregarDados();
  }

  void _navegarPlano(PlanoAlimentar item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => NutricionistaEditorPlanoScreen(pacienteId: widget.pacienteId, plano: item),
    )).then((_) => _carregarDados());
  }

  void _excluirPlano(String id) async {
    await _planoRepo.excluirPlano(widget.pacienteId, id);
    _carregarDados();
  }

  // --- AUXILIARES LÓGICA ---
  Color _calcularCorPredominante(Antropometria item) {
    int ideal = 0;
    int fora = 0; 

    List<String?> classificacoes = [
      item.classImc, item.classMassaCorporal, item.classPercentualGordura,
      item.classMassaGordura, item.classCmb, item.classRcq
    ];

    for (var c in classificacoes) {
      if (c == null) continue;
      if (c.contains('Ideal')) ideal++;
      else fora++;
    }

    if (ideal >= fora) return const Color(0xFF4CAF50); // Verde
    
    // Se não é verde, checa se tem "Acima" para definir Laranja, senão Azul
    bool temAcima = classificacoes.any((c) => c?.contains('Acima') ?? false);
    return temAcima ? const Color(0xFFFF7043) : const Color(0xFF5E6EE6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corAtiva,
      appBar: AppBar(
        title: const Text("Perfil do Paciente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _corAtiva,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _acaoFAB,
        backgroundColor: Colors.white,
        foregroundColor: _corAtiva,
        icon: Icon(_tabSelecionada == 0 ? Icons.add : Icons.add_circle_outline),
        label: Text(
          _tabSelecionada == 0 ? "Nova Avaliação" : "Novo Plano",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _buildHeaderPaciente(),
                _buildTabSelector(),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _tabSelecionada == 0
                        ? _buildAbaAntropometria()
                        : _buildAbaPlanos(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderPaciente() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _dadosPaciente['nome']?.toString().substring(0, 1).toUpperCase() ?? 'P',
              style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dadosPaciente['nome'] ?? 'Nome não informado',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.cake, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text("$_idade anos", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                  const SizedBox(width: 12),
                  const Icon(Icons.person, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(_dadosPaciente['genero'] ?? 'N/A', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
      child: Row(children: [_buildTabItem(0, "Antropometria"), _buildTabItem(1, "Planos")]),
    );
  }

  Widget _buildTabItem(int index, String label) {
    bool isSelected = _tabSelecionada == index;
    IconData icon = index == 0 ? Icons.accessibility_new : Icons.restaurant_menu;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabSelecionada = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? _corAtiva : Colors.white.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? _corAtiva : Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // === ABA ANTROPOMETRIA =====================================================
  // ===========================================================================
  
  Widget _buildAbaAntropometria() {
    if (_historicoAntro.isEmpty) return _buildEmpty("Nenhuma avaliação cadastrada.");

    final atual = _historicoAntro.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CARD RESUMO (Bonequinho + Infos + Obs)
          const Text("Resumo da Avaliação", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.roxo)),
          const SizedBox(height: 10),
          _buildCardResumoBonequinho(atual),
          
          const SizedBox(height: 25),

          // 2. INDICADORES (Todos, com sombra restaurada)
          const Text("Indicadores Atuais", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.roxo)),
          const SizedBox(height: 10),
          _buildBarraProgressoSombreada('Massa Corporal', atual.massaCorporal, 'kg', atual.classMassaCorporal, 150),
          _buildBarraProgressoSombreada('Massa Gorda', atual.massaGordura, 'kg', atual.classMassaGordura, 60),
          _buildBarraProgressoSombreada('Gordura Corporal', atual.percentualGordura, '%', atual.classPercentualGordura, 50),
          _buildBarraProgressoSombreada('IMC', atual.imc, 'kg/m²', atual.classImc, 50),
          _buildBarraProgressoSombreada('CMB', atual.cmb, 'cm', atual.classCmb, 60),
          _buildBarraProgressoSombreada('RCQ', atual.relacaoCinturaQuadril, '', atual.classRcq, 1.5),
          
          const SizedBox(height: 25),

          // 3. EVOLUÇÃO (Gráficos)
          if (_historicoAntro.length > 1) ...[
            const Text("Evolução", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.roxo)),
            const SizedBox(height: 10),
            _buildGraficoEvolucao("Evolução do Peso (kg)", (item) => item.massaCorporal ?? 0, AppColors.roxo),
            const SizedBox(height: 15),
            _buildGraficoEvolucao("Evolução Gordura (%)", (item) => item.percentualGordura ?? 0, const Color(0xFFFF7043)),
            const SizedBox(height: 15),
            _buildGraficoEvolucao("Evolução IMC", (item) => item.imc ?? 0, AppColors.verde),
            const SizedBox(height: 15),
            _buildGraficoEvolucao("Evolução CMB (cm)", (item) => item.cmb ?? 0, const Color(0xFF5E6EE6)),
            const SizedBox(height: 15),
            _buildGraficoEvolucao("Evolução RCQ", (item) => item.relacaoCinturaQuadril ?? 0, const Color(0xFF9C27B0)),
          ],

          const Divider(),
          const SizedBox(height: 10),

          // 4. TODAS AS AVALIAÇÕES (Histórico)
          const Text("Histórico Completo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          
          ..._historicoAntro.map((item) {
            final isAtual = item == _historicoAntro.first;
            return _buildCardHistorico(
              titulo: "Avaliação de ${_formatDate(item.data)}",
              subtitulo: "${item.massaCorporal} kg • IMC ${item.imc}",
              icone: Icons.accessibility_new,
              corTema: AppColors.roxo,
              isAtual: isAtual,
              onTap: () => _navegarAntropometria(item),
              onEdit: () => _navegarAntropometria(item),
              onDelete: () => _excluirAntropometria(item.id_avaliacao!),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCardResumoBonequinho(Antropometria item) {
    Color corBoneco = _calcularCorPredominante(item);
    double peso = item.massaCorporal ?? 0;
    double gordura = item.massaGordura ?? 0;
    double magra = peso - gordura;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBoneco.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: corBoneco.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: corBoneco.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.accessibility_new, color: corBoneco, size: 40),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(item.data), style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoResumo("Peso", "${peso.toStringAsFixed(1)}kg"),
                        _infoResumo("Gordura", "${item.percentualGordura}%"),
                        _infoResumo("M. Magra", "${magra.toStringAsFixed(1)}kg"),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          if (item.observacoes != null && item.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 8),
            Text("Observações:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text(item.observacoes!, style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic)),
          ]
        ],
      ),
    );
  }

  Widget _infoResumo(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  // ===========================================================================
  // === ABA PLANOS ALIMENTARES ================================================
  // ===========================================================================

  Widget _buildAbaPlanos() {
    if (_historicoPlanos.isEmpty) return _buildEmpty("Nenhum plano alimentar.");

    final atual = _historicoPlanos.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Título do Plano Ativo (Com quebra de linha)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Plano Ativo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.verde)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Atualizado em:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(_formatDate(atual.dataCriacao), style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 2. Refeições Detalhadas
          if (atual.refeicoes.isEmpty)
            const Text("Este plano não tem refeições.", style: TextStyle(color: Colors.grey))
          else
            ...atual.refeicoes.map((ref) => _buildRefeicaoCardStyle(ref)),

          const SizedBox(height: 25),
          const Divider(),
          const SizedBox(height: 10),

          // 3. Histórico Completo
          const Text("Histórico Completo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          
          ..._historicoPlanos.map((item) {
            final isAtual = item == _historicoPlanos.first;
            return _buildCardHistorico(
              titulo: item.nome,
              subtitulo: "Criado em ${_formatDate(item.dataCriacao)} • ${item.refeicoes.length} refeições",
              icone: Icons.restaurant_menu,
              corTema: AppColors.verde,
              isAtual: isAtual,
              onTap: () => _navegarPlano(item),
              onEdit: () => _navegarPlano(item),
              onDelete: () => _excluirPlano(item.id),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // === COMPONENTES VISUAIS ===================================================
  // ===========================================================================

  Widget _buildCardHistorico({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color corTema,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    bool isAtual = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isAtual ? 4 : 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAtual ? BorderSide(color: corTema, width: 2) : BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isAtual ? corTema : Colors.grey[100],
          child: Icon(icone, color: isAtual ? Colors.white : Colors.grey, size: 20),
        ),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: isAtual ? Colors.black : Colors.grey[700])),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitulo),
            if (isAtual) 
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("ATUAL", style: TextStyle(color: corTema, fontSize: 10, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'del') onDelete();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text("Editar")),
            const PopupMenuItem(value: 'del', child: Text("Excluir", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraProgressoSombreada(String label, double? valor, String unidade, String? classificacao, double maxVal) {
    double v = valor ?? 0;
    double percent = (v / maxVal).clamp(0.0, 1.0);
    
    Color cor = Colors.grey;
    if (classificacao?.contains('Abaixo') ?? false) cor = const Color(0xFF5E6EE6); 
    else if (classificacao?.contains('Ideal') ?? false) cor = const Color(0xFF4CAF50); 
    else if (classificacao?.contains('Acima') ?? false) cor = const Color(0xFFFF7043); 

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              Row(
                children: [
                  Text("${v.toStringAsFixed(1)}$unidade", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cor)),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(classificacao ?? '-', style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(color: cor.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3)),
                  ]
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGraficoEvolucao(String titulo, double Function(Antropometria) getValor, Color corLinha) {
    final dadosCronologicos = _historicoAntro.reversed.toList();
    List<FlSpot> spots = [];
    double minV = 9999, maxV = 0;
    
    for (int i = 0; i < dadosCronologicos.length; i++) {
      double val = getValor(dadosCronologicos[i]);
      if (val > maxV) maxV = val;
      if (val < minV && val > 0) minV = val;
      spots.add(FlSpot(i.toDouble(), val));
    }
    
    if (spots.isEmpty) return const SizedBox();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: (minV - 5).clamp(0, 999), 
                maxY: maxV + 5,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots, isCurved: true, color: corLinha, barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: corLinha.withOpacity(0.1)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefeicaoCardStyle(Refeicao refeicao) {
    double cal = refeicao.totalCalorias;
    double prot = refeicao.totalProteinas;
    double carb = refeicao.totalCarboidratos;
    double gord = refeicao.totalGorduras;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.verde.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.restaurant, color: AppColors.verde),
          ),
          title: Text(refeicao.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text('${refeicao.horario} • ${cal.toStringAsFixed(0)} kcal', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          children: [
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge("Carb", "${carb.toStringAsFixed(1)}g", Colors.orange),
                      _buildMacroBadge("Prot", "${prot.toStringAsFixed(1)}g", Colors.blue),
                      _buildMacroBadge("Gord", "${gord.toStringAsFixed(1)}g", Colors.red),
                    ],
                  ),
                  const Divider(height: 20),
                  ...refeicao.alimentos.map((ali) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(ali.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text("${ali.calorias} kcal / 100g"),
                    trailing: Text("${ali.quantidade.toStringAsFixed(0)}g", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.verde)),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text("$label: $value", style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "--/--/----";
    return DateFormat('dd/MM/yyyy').format(date);
  }
}