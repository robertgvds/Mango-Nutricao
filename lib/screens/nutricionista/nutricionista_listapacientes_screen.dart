import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import do Realtime DB
import 'package:app/widgets/app_colors.dart';
import 'package:app/services/auth_service.dart';
import 'package:provider/provider.dart';

// Importante: certifique-se que o caminho está correto
import 'nutricionista_detalhes_paciente_screen.dart';

class NutricionistaListaPacientesScreen extends StatefulWidget {
  const NutricionistaListaPacientesScreen({super.key});

  @override
  State<NutricionistaListaPacientesScreen> createState() =>
      _NutricionistaListaPacientesScreenState();
}

class _NutricionistaListaPacientesScreenState
    extends State<NutricionistaListaPacientesScreen> {
  // Controller para o campo de texto
  final TextEditingController _nomeController = TextEditingController();

  // Variável para armazenar o texto da busca em tempo real
  String _filtroBusca = "";

  // Função para navegar
  void _navegarParaRelatorio(String idPaciente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                NutricionistaAntropometriaScreen(pacienteId: idPaciente),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pega o ID do nutricionista logado
    final String? nutricionistaUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Meus Pacientes",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.roxo,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: AppColors.roxo,
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- SEÇÃO 1: CAMPO DE BUSCA INSTANTÂNEA ---
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filtrar Pacientes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: "Digite o nome...",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _filtroBusca.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _nomeController.clear();
                                      _filtroBusca = "";
                                    });
                                  },
                                )
                                : null,
                      ),
                      // Atualiza o estado a cada letra digitada
                      onChanged: (value) {
                        setState(() {
                          _filtroBusca = value.toLowerCase();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // --- SEÇÃO 2: LISTA REAL-TIME (COM FILTRO) ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _filtroBusca.isEmpty
                    ? "Todos os Pacientes"
                    : "Resultados da busca",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.roxo,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              // StreamBuilder mantém a conexão aberta com o Firebase
              child: StreamBuilder(
                stream:
                    FirebaseDatabase.instance
                        .ref()
                        .child('usuarios')
                        .orderByChild('nutricionistaId')
                        .equalTo(nutricionistaUid)
                        .onValue,
                builder: (context, snapshot) {
                  // 1. Carregando
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 2. Erro
                  if (snapshot.hasError) {
                    return const Center(child: Text("Erro ao carregar lista."));
                  }

                  // 3. Verifica dados vazios
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Sua lista está vazia.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // 4. Converte e Filtra os dados
                  final dadosMap = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  final List<Map<String, dynamic>> listaPacientes = [];

                  dadosMap.forEach((key, value) {
                    final dadosUsuario = Map<String, dynamic>.from(value);

                    // Verifica se é paciente
                    if (dadosUsuario['tipo'] == 'paciente') {
                      final String nome =
                          (dadosUsuario['nome'] ?? 'Sem Nome').toString();

                      // *** AQUI ACONTECE O FILTRO DA BUSCA ***
                      // Se o filtro estiver vazio OU o nome conter o filtro, adiciona na lista
                      if (_filtroBusca.isEmpty ||
                          nome.toLowerCase().contains(_filtroBusca)) {
                        listaPacientes.add({
                          'id': key,
                          'nome': nome,
                          'email': dadosUsuario['email'] ?? 'Sem Email',
                        });
                      }
                    }
                  });

                  if (listaPacientes.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhum paciente encontrado com '$_filtroBusca'.",
                      ),
                    );
                  }

                  // 5. Ordena alfabeticamente
                  listaPacientes.sort(
                    (a, b) =>
                        a['nome'].toString().compareTo(b['nome'].toString()),
                  );

                  // 6. Renderiza
                  return ListView.builder(
                    itemCount: listaPacientes.length,
                    itemBuilder: (context, index) {
                      final paciente = listaPacientes[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.roxo.withOpacity(0.2),
                            child: Text(
                              paciente['nome'].isNotEmpty
                                  ? paciente['nome'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: AppColors.roxo),
                            ),
                          ),
                          title: Text(
                            paciente['nome'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(paciente['email']),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.assessment,
                              color: AppColors.roxo,
                            ),
                            tooltip: "Ver Avaliação",
                            onPressed:
                                () => _navegarParaRelatorio(paciente['id']),
                          ),
                          onTap: () => _navegarParaRelatorio(paciente['id']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
