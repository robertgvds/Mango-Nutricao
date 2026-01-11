import 'package:app/classes/planoalimentar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Certifique-se de ter este pacote
import '../../widgets/app_colors.dart';

// Classes e Repos
import '../../classes/antropometria.dart';
import '../../classes/refeicao.dart';
import '../../database/antropometria_repository.dart';
import '../../database/plano_alimentar_repository.dart';

// Telas de Criação/Edição e Histórico
import 'nutricionista_nova_avaliacao.dart'; 
import 'nutricionista_editor_plano_screen.dart';
import 'nutricionista_antropometria_screen.dart'; // Tela de histórico Antropometria
import 'nutricionista_historico_planos_screen.dart'; // Tela de histórico Planos
import '../../classes/paciente.dart'; // Para passar objeto paciente se necessário

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
  int _tabSelecionada = 0; // 0 = Antropometria, 1 = Plano Alimentar

  // Dados do Paciente
  Map<String, dynamic> _dadosPaciente = {};
  int _idade = 0;

  // Dados Antropometria
  Antropometria? _ultimaAvaliacao;
  List<Antropometria> _historicoAntro = [];

  // Dados Plano Alimentar
  PlanoAlimentar? _ultimoPlano;

  @override
  void initState() {
    super.initState();
    _carregarDadosCompletos();
  }

  Future<void> _carregarDadosCompletos() async {
    setState(() => _isLoading = true);
    try {
      // 1. Dados do Usuário
      final userSnap = await FirebaseDatabase.instance
          .ref('usuarios/${widget.pacienteId}')
          .get();
      
      if (userSnap.exists) {
        _dadosPaciente = Map<String, dynamic>.from(userSnap.value as Map);
        _calcularIdade(_dadosPaciente['dataNascimento']);
      }

      // 2. Dados Antropometria
      final listaAntro = await _antroRepo.buscarHistorico(widget.pacienteId);
      // Ordena: mais recente primeiro para pegar a última
      listaAntro.sort((a, b) => (b.data ?? DateTime(2000)).compareTo(a.data ?? DateTime(2000)));
      
      // Para o gráfico, precisamos da ordem cronológica (mais antigo primeiro)
      _historicoAntro = List.from(listaAntro.reversed); 
      _ultimaAvaliacao = listaAntro.isNotEmpty ? listaAntro.first : null;

      // 3. Dados Plano Alimentar
      final listaPlanos = await _planoRepo.listarPlanos(widget.pacienteId);
      // O repositório já deve retornar ordenado, mas garantindo pegar o primeiro (mais atual)
      if (listaPlanos.isNotEmpty) {
        _ultimoPlano = listaPlanos.first;
      } else {
        _ultimoPlano = null;
      }

    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calcularIdade(String? dataNasc) {
    if (dataNasc == null) return;
    try {
      // Tenta formato dd/MM/yyyy
      final parts = dataNasc.split('/');
      if (parts.length == 3) {
        final dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        final hoje = DateTime.now();
        int idade = hoje.year - dt.year;
        if (hoje.month < dt.month || (hoje.month == dt.month && hoje.day < dt.day)) {
          idade--;
        }
        _idade = idade;
      }
    } catch (_) {}
  }

  // --- AÇÕES DO FAB (Botão Flutuante) ---
  void _acaoBotaoFlutuante() {
    if (_tabSelecionada == 0) {
      // Criar Nova Avaliação
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NovaAvaliacaoScreen(pacienteId: widget.pacienteId),
        ),
      ).then((_) => _carregarDadosCompletos());
    } else {
      // Criar Novo Plano
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NutricionistaEditorPlanoScreen(
            pacienteId: widget.pacienteId,
            plano: null, // Null = Criar novo
          ),
        ),
      ).then((_) => _carregarDadosCompletos());
    }
  }

  // --- NAVEGAÇÃO PARA HISTÓRICO/EDIÇÃO ---
  void _abrirGerenciamentoHistorico() {
    // Cria objeto paciente auxiliar apenas com ID e Nome para passar para as telas
    final pacienteObj = Paciente(
      id: widget.pacienteId,
      nome: _dadosPaciente['nome'] ?? 'Paciente', 
      email: '', senha: '', codigo: '', dataNascimento: '',
    );

    if (_tabSelecionada == 0) {
      // Tela de Lista de Antropometria (onde tem editar/excluir)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NutricionistaAntropometriaScreen(pacienteId: widget.pacienteId),
        ),
      ).then((_) => _carregarDadosCompletos());
    } else {
      // Tela de Histórico de Planos (onde tem editar/excluir)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NutricionistaHistoricoPlanosScreen(paciente: pacienteObj),
        ),
      ).then((_) => _carregarDadosCompletos());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roxo,
      appBar: AppBar(
        title: const Text("Perfil do Paciente", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.roxo,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _acaoBotaoFlutuante,
        backgroundColor: AppColors.laranja,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabSelecionada == 0 ? "Nova Avaliação" : "Novo Plano",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // 1. CARD DE CABEÇALHO (Informações do Paciente)
                _buildHeaderPaciente(),

                // 2. ABAS (Selector)
                _buildTabSelector(),

                // 3. CONTEÚDO (Antropometria ou Plano)
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Botão de Histórico no topo do conteúdo
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _abrirGerenciamentoHistorico,
                              icon: const Icon(Icons.history, size: 18),
                              label: const Text("Gerenciar Histórico Completo"),
                              style: TextButton.styleFrom(foregroundColor: AppColors.roxo),
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 10),

                          // Conteúdo Dinâmico
                          _tabSelecionada == 0
                              ? _buildConteudoAntropometria()
                              : _buildConteudoPlanoAlimentar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- WIDGETS DE UI ---

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
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dadosPaciente['nome'] ?? 'Nome Indisponível',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "$_idade anos • ${_dadosPaciente['genero'] ?? 'Gênero n/a'}",
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
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
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabButton("Antropometria", 0),
          _buildTabButton("Plano Alimentar", 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = _tabSelecionada == index;
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
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.roxo : Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- CONTEÚDO DA ANTROPOMETRIA ---
  Widget _buildConteudoAntropometria() {
    if (_ultimaAvaliacao == null) {
      return _buildEmptyState("Nenhuma avaliação cadastrada.", Icons.monitor_weight_outlined);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Última Avaliação: ${_formatDate(_ultimaAvaliacao!.data)}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.roxo),
        ),
        const SizedBox(height: 15),
        
        // Barras de Progresso (Visual do Paciente)
        _buildIndicadorBarra('Massa Corporal Total', _ultimaAvaliacao!.massaCorporal, 'kg', _ultimaAvaliacao!.classMassaCorporal, maxVal: 150),
        _buildIndicadorBarra('Massa de Gordura', _ultimaAvaliacao!.massaGordura, 'kg', _ultimaAvaliacao!.classMassaGordura, maxVal: 50),
        _buildIndicadorBarra('% de Gordura', _ultimaAvaliacao!.percentualGordura, '%', _ultimaAvaliacao!.classPercentualGordura, maxVal: 50),
        _buildIndicadorBarra('IMC', _ultimaAvaliacao!.imc, '', _ultimaAvaliacao!.classImc, maxVal: 50),
        
        const SizedBox(height: 30),
        
        // Gráfico de Evolução (Se houver histórico)
        if (_historicoAntro.length > 1) ...[
          const Text("Evolução do Peso", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.roxo)),
          const SizedBox(height: 10),
          _buildGraficoPeso(),
        ]
      ],
    );
  }

  // --- CONTEÚDO DO PLANO ALIMENTAR ---
  Widget _buildConteudoPlanoAlimentar() {
    if (_ultimoPlano == null) {
      return _buildEmptyState("Nenhum plano alimentar ativo.", Icons.restaurant_menu);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Plano Atual: ${_ultimoPlano!.nome}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.roxo),
            ),
            Text(
              _formatDate(_ultimoPlano!.dataCriacao),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (_ultimoPlano!.refeicoes.isEmpty)
          const Text("Este plano não possui refeições.", style: TextStyle(color: Colors.grey))
        else
          ..._ultimoPlano!.refeicoes.map((r) => _buildRefeicaoCardStyle(r)),
      ],
    );
  }

  // --- COMPONENTES VISUAIS REUTILIZADOS ---

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(msg, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadorBarra(String label, double? valor, String unidade, String? classificacao, {double maxVal = 100.0}) {
    Color cor = const Color(0xFF4CAF50); // Verde (Ideal)
    if (classificacao?.contains('Abaixo') ?? false) cor = const Color(0xFF5E6EE6); // Azul
    if (classificacao?.contains('Acima') ?? false) cor = const Color(0xFFFF7043); // Laranja

    double v = valor ?? 0;
    double percent = (v / maxVal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              Text('${v.toStringAsFixed(1)}$unidade', style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(cor),
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
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
          title: Text(refeicao.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text('${refeicao.horario} • ${cal.toStringAsFixed(0)} kcal', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
                  ...refeicao.alimentos.map((alimento) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(alimento.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text("${alimento.calorias} kcal / 100g"),
                    trailing: Text("${alimento.quantidade.toStringAsFixed(0)}g", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.verde)),
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

  Widget _buildGraficoPeso() {
    List<FlSpot> spots = [];
    double minW = 200, maxW = 0;
    
    for (int i = 0; i < _historicoAntro.length; i++) {
      double w = _historicoAntro[i].massaCorporal ?? 0;
      if (w > maxW) maxW = w;
      if (w < minW && w > 0) minW = w;
      spots.add(FlSpot(i.toDouble(), w));
    }
    
    if (spots.isEmpty) return const SizedBox();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: LineChart(
        LineChartData(
          minY: minW - 5, maxY: maxW + 5,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots, isCurved: true, color: AppColors.roxo, barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.roxo.withOpacity(0.1)),
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "--/--/----";
    return DateFormat('dd/MM/yyyy').format(date);
  }
}