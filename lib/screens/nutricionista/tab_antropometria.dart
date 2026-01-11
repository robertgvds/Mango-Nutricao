import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AntropometriaTab extends StatelessWidget {
  final String nomePaciente;
  final Map<String, dynamic>? avaliacao;
  final Color primaryColor;

  const AntropometriaTab({
    super.key,
    required this.nomePaciente,
    required this.avaliacao,
    required this.primaryColor,
  });

  // Cores semânticas mantidas
  final Color corAbaixo = Colors.orange;
  final Color corIdeal = Colors.green;
  final Color corAcima = Colors.red;

  String _formatarData(String? isoString) {
    if (isoString == null) return "--/--/----";
    try {
      final data = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(data);
    } catch (e) {
      return isoString;
    }
  }

  Color _definirCor(String? classificacao) {
    if (classificacao == null) return Colors.grey;
    final valor = classificacao.toLowerCase();
    if (valor.contains('ideal')) return corIdeal;
    if (valor.contains('abaixo')) return corAbaixo;
    if (valor.contains('acima')) return corAcima;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (avaliacao == null) return _buildEmptyState();
    return _buildContent();
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Text(
          "Paciente: $nomePaciente",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Icon(Icons.note_alt_outlined, size: 60, color: Colors.grey),
        const SizedBox(height: 10),
        const Text(
          "Nenhuma avaliação registrada.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final dataExame = _formatarData(avaliacao!['data']);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryColor.withOpacity(0.1), // COR DINAMICA
                child: Text(
                  nomePaciente.isNotEmpty ? nomePaciente[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ), // COR DINAMICA
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomePaciente,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Data: $dataExame",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _legendaContainer(),
        const SizedBox(height: 25),
        Row(
          children: [
            Icon(
              Icons.bar_chart,
              color: primaryColor,
              size: 22,
            ), // COR DINAMICA
            const SizedBox(width: 8),
            const Text(
              "Resultados",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Seus itens de dados...
        _itemDado(
          "Massa Corporal",
          avaliacao!['massaCorporal'],
          "kg",
          avaliacao!['classMassaCorporal'],
        ),
        _itemDado(
          "Massa Gordura",
          avaliacao!['massaGordura'],
          "kg",
          avaliacao!['classMassaGordura'],
        ),
        _itemDado(
          "% de Gordura",
          avaliacao!['percentualGordura'],
          "%",
          avaliacao!['classPercentualGordura'],
        ),
        _itemDado(
          "Massa Esquelética",
          avaliacao!['massaEsqueletica'],
          "kg",
          avaliacao!['classMassaEsqueletica'],
        ),
        _itemDado("IMC", avaliacao!['imc'], "", avaliacao!['classImc']),
        _itemDado("CMB", avaliacao!['cmb'], "cm", avaliacao!['classCmb']),
        _itemDado(
          "RCQ",
          avaliacao!['relacaoCinturaQuadril'],
          "",
          avaliacao!['classRcq'],
        ),
      ],
    );
  }

  // _legendaContainer, _legenda e _itemDado mantidos iguais aos anteriores
  Widget _legendaContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legenda("Abaixo", corAbaixo),
          _legenda("Ideal", corIdeal),
          _legenda("Acima", corAcima),
        ],
      ),
    );
  }

  Widget _legenda(String texto, Color cor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _itemDado(
    String label,
    dynamic valor,
    String unidade,
    dynamic classificacao,
  ) {
    final String valTexto = valor?.toString() ?? "-";
    final Color corStatus = _definirCor(classificacao?.toString());
    double percent = 0.05;
    String classStr = (classificacao?.toString().toLowerCase() ?? "");
    if (classStr.contains('abaixo'))
      percent = 0.33;
    else if (classStr.contains('ideal') || classStr.contains('normal'))
      percent = 0.66;
    else if (classStr.contains('acima') || classStr.contains('obesidade'))
      percent = 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              corStatus != Colors.grey
                  ? corStatus.withOpacity(0.5)
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$valTexto $unidade",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: corStatus,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
