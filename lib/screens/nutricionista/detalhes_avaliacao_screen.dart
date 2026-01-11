import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../classes/antropometria.dart';
import '../../widgets/app_colors.dart';
import 'nutricionista_antropometria_screen.dart'; // Tela de Edição

class DetalhesAvaliacaoScreen extends StatelessWidget {
  final String pacienteId;
  final Antropometria avaliacao;

  const DetalhesAvaliacaoScreen({
    super.key,
    required this.pacienteId,
    required this.avaliacao,
  });

  void _navegarParaEdicao(BuildContext context) {
    // Navega para a tela de formulário (AntropometriaScreen) passando os dados
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NutricionistaAntropometriaScreen(
          pacienteId: pacienteId,
          avaliacaoParaEditar: avaliacao, // Vamos adaptar a tela de antropometria para aceitar isso
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo de Massa Magra (Peso - Gordura) para exibição
    double peso = avaliacao.massaCorporal ?? 0;
    double gorduraKg = avaliacao.massaGordura ?? 0;
    double massaMagra = peso - gorduraKg;

    return Scaffold(
      backgroundColor: AppColors.roxo,
      appBar: AppBar(
        title: const Text("Detalhes da Avaliação", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.roxo,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DATA E TÍTULO
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.assessment, size: 50, color: AppColors.roxo),
                          const SizedBox(height: 10),
                          Text(
                            "Avaliação de ${_formatDate(avaliacao.data)}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.roxo),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // GRID DE DADOS
                    const Text("Dados Corporais", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 15),
                    _buildGridDados(peso, gorduraKg, massaMagra),

                    const SizedBox(height: 25),
                    const Divider(),
                    const SizedBox(height: 15),

                    // OBSERVAÇÕES
                    const Text("Observações", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        (avaliacao.observacoes != null && avaliacao.observacoes!.isNotEmpty)
                            ? avaliacao.observacoes!
                            : "Nenhuma observação registrada.",
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // BOTÃO EDITAR
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _navegarParaEdicao(context),
                        icon: const Icon(Icons.edit),
                        label: const Text("EDITAR AVALIAÇÃO"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roxo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridDados(double peso, double gordura, double magra) {
    return Column(
      children: [
        Row(
          children: [
            _buildInfoCard("Massa Corporal", "${peso.toStringAsFixed(1)} kg", Icons.scale),
            const SizedBox(width: 15),
            _buildInfoCard("IMC", "${avaliacao.imc?.toStringAsFixed(1)}", Icons.calculate),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildInfoCard("Massa Gorda", "${gordura.toStringAsFixed(1)} kg", Icons.opacity),
            const SizedBox(width: 15),
            _buildInfoCard("Massa Magra", "${magra.toStringAsFixed(1)} kg", Icons.fitness_center), // Calculado
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildInfoCard("% Gordura", "${avaliacao.percentualGordura?.toStringAsFixed(1)}%", Icons.pie_chart),
            const SizedBox(width: 15),
            _buildInfoCard("RCQ", "${avaliacao.relacaoCinturaQuadril?.toStringAsFixed(2)}", Icons.accessibility),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String valor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.roxo, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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