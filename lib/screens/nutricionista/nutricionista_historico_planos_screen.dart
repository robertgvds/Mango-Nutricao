import 'package:flutter/material.dart';
import '../../classes/paciente.dart';
import '../../widgets/app_colors.dart';
// import '../../database/plano_alimentar_repository.dart'; // Descomente quando tiver o arquivo
// import '../../classes/planoalimentar.dart'; // Descomente quando tiver o arquivo
// import 'nutricionista_editor_plano_screen.dart'; // Descomente quando tiver o arquivo

class NutricionistaHistoricoPlanosScreen extends StatefulWidget {
  final Paciente paciente;
  final bool isEmbedded; // Define se é aba (sem Scaffold) ou tela cheia
  final Color? primaryColor; // Define a cor do tema (Verde ou Laranja)

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
  // final PlanoAlimentarRepository _repo = PlanoAlimentarRepository();
  List<dynamic> _planos = []; // Altere para List<PlanoAlimentar>
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    setState(() => _isLoading = true);

    // SIMULAÇÃO DE DADOS (Substitua pela chamada real do seu repositório)
    // final lista = await _repo.listarPlanos(widget.paciente.id!);
    await Future.delayed(const Duration(milliseconds: 800)); // Fake delay
    final lista =
        []; // Deixe vazio para testar o EmptyState ou preencha para testar lista

    if (mounted) {
      setState(() {
        _planos = lista;
        _isLoading = false;
      });
    }
  }

  void _abrirEditor() {
    // Navigator.push(...);
    debugPrint("Abrir editor de plano");
  }

  @override
  Widget build(BuildContext context) {
    // Define a cor do tema: Se foi passado (Verde da aba), usa ela. Se não, usa Laranja.
    final Color corTema = widget.primaryColor ?? AppColors.laranja;

    // Conteúdo principal (A Lista)
    Widget content =
        _isLoading
            ? Center(child: CircularProgressIndicator(color: corTema))
            : _planos.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
              physics:
                  const NeverScrollableScrollPhysics(), // Importante: Deixa o pai rolar
              shrinkWrap: true, // Importante para caber na aba
              itemCount: _planos.length,
              padding: const EdgeInsets.all(0),
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: corTema.withOpacity(0.1),
                      child: Icon(Icons.restaurant, color: corTema),
                    ),
                    title: Text("Plano Alimentar ${index + 1}"),
                    subtitle: const Text("Clique para ver detalhes"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navegar para detalhes
                    },
                  ),
                );
              },
            );

    // Estrutura do corpo
    Widget body = Column(
      children: [
        content,
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _abrirEditor,
            icon: const Icon(Icons.add),
            label: const Text("CRIAR NOVO PLANO"),
            style: ElevatedButton.styleFrom(
              backgroundColor: corTema, // USA A COR DINÂMICA (VERDE)
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: corTema.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );

    // LÓGICA PRINCIPAL DE EXIBIÇÃO:

    // 1. Modo Embutido (Dentro da Aba)
    if (widget.isEmbedded) {
      return Container(
        color: Colors.white, // Fundo limpo para integrar com a aba
        child: body,
      );
    }

    // 2. Modo Tela Cheia (Se for aberto individualmente)
    return Scaffold(
      backgroundColor: corTema,
      appBar: AppBar(
        title: Text(
          "Planos de ${widget.paciente.nome}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: corTema,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // Ocupa toda a altura
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          // Necessário pois não temos o scroll da tela pai aqui
          child: body,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Nenhum plano alimentar encontrado.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
