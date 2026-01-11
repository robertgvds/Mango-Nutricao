import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_colors.dart';

// Classes e Repos
import '../../classes/antropometria.dart';
import '../../classes/plano_alimentar.dart';
import '../../classes/refeicao.dart';
import '../../database/antropometria_repository.dart';
import '../../database/plano_alimentar_repository.dart';

// Telas de Edição (Formulários)
import 'nutricionista_antropometria_screen.dart'; // Agora é a tela de Formulário
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

      // 2. Antropometria (Busca histórico completo)
      final listaAntro = await _antroRepo.buscarHistorico(widget.pacienteId);
      // Ordena: Mais recente primeiro
      listaAntro.sort((a, b) => (b.data ?? DateTime(2000)).compareTo(a.data ?? DateTime(2000)));
      _historicoAntro = listaAntro;

      // 3. Planos
      final listaPlanos = await _planoRepo.listarPlanos(widget.pacienteId);
      // Ordena: Mais recente primeiro
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
      final parts = dataNasc.split('/'); // formato dd/MM/yyyy
      if (parts.length == 3) {
        final dia = int.parse(parts[0]);
        final mes = int.parse(parts[1]);
        final ano = int.parse(parts[2]);
        
        final dtNasc = DateTime(ano, mes, dia);
        final hoje = DateTime.now();
        
        int idade = hoje.year - dtNasc.year;
        if (hoje.month < dtNasc.month || (hoje.month == dtNasc.month && hoje.day < dtNasc.day)) {
          idade--;
        }
        setState(() => _idade = idade);
      }
    } catch (_) {}
  }

  // --- NAVEGAÇÃO ---

  // Botão Flutuante (Criar Novo)
  void _acaoFAB() {
    if (_tabSelecionada == 0) {
      // Criar Antropometria -> Vai para NutricionistaAntropometriaScreen (Formulário)
      Navigator.push(context, MaterialPageRoute(
        // Aqui assumo que você vai adaptar a NutricionistaAntropometriaScreen para receber null e criar
        // ou você pode manter a lógica de lista lá, mas o pedido foi usar ela para criar/editar.
        builder: (context) => NutricionistaAntropometriaScreen(pacienteId: widget.pacienteId), 
      )).then((_) => _carregarDados());
    } else {
      // Criar Plano
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => NutricionistaEditorPlanoScreen(pacienteId: widget.pacienteId, plano: null),
      )).then((_) => _carregarDados());
    }
  }

  // Editar / Visualizar Antropometria
  void _navegarAntropometria(Antropometria? item) {
    // Se precisar passar o item para edição, certifique-se que NutricionistaAntropometriaScreen aceita
    // Caso contrário, se ela for apenas uma lista, essa navegação levará para a lista.
    // Mas conforme seu pedido: "editar_antropometria seja A TELA de editar e CRIAR".
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => NutricionistaAntropometriaScreen(pacienteId: widget.pacienteId),
    )).then((_) => _carregarDados());
  }

  void _excluirAntropometria(String id) async {
    await _antroRepo.excluirAvaliacao(widget.pacienteId, id);
    _carregarDados();
  }

  // Editar / Visualizar Plano
  void _navegarPlano(PlanoAlimentar item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => NutricionistaEditorPlanoScreen(pacienteId: widget.pacienteId, plano: item),
    )).then((_) => _carregarDados());
  }

  void _excluirPlano(String id) async {
    await _planoRepo.excluirPlano(widget.pacienteId, id);
    _carregarDados();
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
                // 1. CABEÇALHO (Dados do Paciente)
                _buildHeaderPaciente(),

                // 2. SELETOR DE ABAS
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
                  child: Row(children: [_buildTabItem(0, "Antropometria"), _buildTabItem(1, "Planos")]),
                ),

                // 3. CONTEÚDO (Container Branco)
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

  Widget _buildTabItem(int index, String label) {
    bool isSelected = _tabSelecionada == index;
    // Ícone Pessoa para Antropometria, Garfo/Faca para Planos
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
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _corAtiva : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ABA ANTROPOMETRIA ---
  Widget _buildAbaAntropometria() {
    if (_historicoAntro.isEmpty) return _buildEmpty("Nenhuma avaliação cadastrada.");

    final atual = _historicoAntro.first;
    final historico = _historicoAntro.length > 1 ? _historicoAntro.sublist(1) : <Antropometria>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Última Avaliação Física", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.roxo)),
          const SizedBox(height: 16),
          
          // DASHBOARD (Barras de Progresso) - Estilo do Paciente
          if (atual != null) ...[
            _buildIndicadorBarra('Massa Corporal Total', atual.massaCorporal, 'kg', atual.classMassaCorporal, maxVal: 150),
            _buildIndicadorBarra('Massa de Gordura', atual.massaGordura, 'kg', atual.classMassaGordura, maxVal: 50),
            _buildIndicadorBarra('Percentual de Gordura', atual.percentualGordura, '%', atual.classPercentualGordura, maxVal: 50),
            _buildIndicadorBarra('IMC', atual.imc, '', atual.classImc, maxVal: 50),
            _buildIndicadorBarra('CMB (Braço)', atual.cmb, ' cm', atual.classCmb, maxVal: 60),
            _buildIndicadorBarra('Relação C/Q', atual.relacaoCinturaQuadril, '', atual.classRcq, maxVal: 1.2),
          ],

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // HISTÓRICO (Estilo Card Branco Igual Planos)
          if (historico.isNotEmpty) ...[
            const Text("Histórico", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ...historico.map((item) => _buildCardHistorico(
              titulo: "Avaliação de ${_formatDate(item.data)}",
              subtitulo: "${item.massaCorporal} kg • IMC ${item.imc}",
              icone: Icons.accessibility_new,
              corTema: AppColors.roxo,
              onTap: () => _navegarAntropometria(item),
              onEdit: () => _navegarAntropometria(item),
              onDelete: () => _excluirAntropometria(item.id_avaliacao!),
            )),
          ]
        ],
      ),
    );
  }

  // --- ABA PLANOS ---
  Widget _buildAbaPlanos() {
    if (_historicoPlanos.isEmpty) return _buildEmpty("Nenhum plano alimentar.");

    final atual = _historicoPlanos.first;
    final historico = _historicoPlanos.length > 1 ? _historicoPlanos.sublist(1) : <PlanoAlimentar>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Plano Ativo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.verde)),
          const SizedBox(height: 10),
          
          // CARD DO PLANO ATUAL (Usando mesmo estilo do histórico mas destacado)
          _buildCardHistorico(
            titulo: atual.nome,
            subtitulo: "Criado em ${_formatDate(atual.dataCriacao)}",
            icone: Icons.restaurant_menu,
            corTema: AppColors.verde,
            isAtual: true,
            onTap: () => _navegarPlano(atual),
            onEdit: () => _navegarPlano(atual),
            onDelete: () => _excluirPlano(atual.id),
          ),

          const SizedBox(height: 25),
          const Divider(),
          const SizedBox(height: 10),

          // HISTÓRICO
          if (historico.isNotEmpty) ...[
            const Text("Histórico", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ...historico.map((item) => _buildCardHistorico(
              titulo: item.nome,
              subtitulo: "Criado em ${_formatDate(item.dataCriacao)}",
              icone: Icons.restaurant_menu,
              corTema: AppColors.verde,
              onTap: () => _navegarPlano(item),
              onEdit: () => _navegarPlano(item),
              onDelete: () => _excluirPlano(item.id),
            )),
          ]
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  // CARD DE HISTÓRICO (Genérico para ambas as abas)
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
      elevation: isAtual ? 4 : 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAtual ? BorderSide(color: corTema, width: 2) : BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isAtual ? corTema : Colors.grey[200],
          child: Icon(icone, color: isAtual ? Colors.white : Colors.grey, size: 20),
        ),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: isAtual ? Colors.black : Colors.grey[800])),
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

  // BARRA DE PROGRESSO (Estilo Paciente)
  Widget _buildIndicadorBarra(String label, double? valor, String unidade, String? classificacao, {double maxVal = 100.0}) {
    Color cor;
    if (classificacao == 'Abaixo') {
      cor = const Color(0xFF5E6EE6); // Azul
    } else if (classificacao == 'Acima') {
      cor = const Color(0xFFFF7043); // Laranja
    } else {
      cor = const Color(0xFF4CAF50); // Verde
    }

    double v = valor ?? 0;
    double percent = (v / maxVal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${v.toStringAsFixed(1)}$unidade', style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
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