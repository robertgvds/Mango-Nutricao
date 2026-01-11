import 'package:flutter/material.dart';
import '../../classes/paciente.dart';
import 'nutricionista_historico_planos_screen.dart';

class PlanosAlimentaresTab extends StatelessWidget {
  final Paciente? paciente;
  final Color primaryColor; // Recebe a cor (Verde)

  const PlanosAlimentaresTab({
    super.key,
    required this.paciente,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (paciente == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("Carregando dados do paciente..."),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      child: NutricionistaHistoricoPlanosScreen(
        paciente: paciente!,
        isEmbedded: true,
        primaryColor: primaryColor, // Passa a cor
      ),
    );
  }
}
