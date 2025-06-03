import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';

/// Widget que muestra un gráfico de barras con los reportes por servicio (versión móvil)
class DashboardReportesPorServicio extends StatelessWidget {
  final List<ReportePorServicio> reportesPorServicio;

  const DashboardReportesPorServicio({
    Key? key,
    required this.reportesPorServicio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reportesPorServicio.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes por Servicio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Distribución de reportes según el tipo de servicio.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calcularMaximoValorServicio(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final servicio = reportesPorServicio[groupIndex];
                      return BarTooltipItem(
                        '${servicio.etiquetaServicio}\n${servicio.valorCantidad}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0');
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final int index = value.toInt();
                        if (index >= 0 && index < reportesPorServicio.length) {
                          String nombre =
                              reportesPorServicio[index].etiquetaServicio;
                          if (nombre.length > 6) {
                            nombre = '${nombre.substring(0, 6)}...';
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              nombre,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calcularIntervaloGridServicio(),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _crearBarrasServicio(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calcularMaximoValorServicio() {
    if (reportesPorServicio.isEmpty) return 10;
    final max = reportesPorServicio
        .map((s) => s.valorCantidad)
        .reduce((a, b) => a > b ? a : b);
    return max.toDouble() * 1.2; // Añadimos un 20% extra para espacio visual
  }

  double _calcularIntervaloGridServicio() {
    final max = _calcularMaximoValorServicio();
    return max > 10 ? (max / 5).ceilToDouble() : 2;
  }

  List<BarChartGroupData> _crearBarrasServicio() {
    final serviciosMostrados =
        reportesPorServicio.length > 5
            ? reportesPorServicio.sublist(0, 5)
            : reportesPorServicio;

    final colores = const [
      Color(0xFF4A90E2), // Azul profesional
      Color(0xFF66BB6A), // Verde brillante
      Color(0xFFFFA726), // Naranja vibrante
      Color(0xFF9575CD), // Morado elegante
      Color(0xFF26C6DA), // Turquesa fresco
    ];

    return serviciosMostrados.asMap().entries.map((entry) {
      final i = entry.key;
      final servicio = entry.value;
      final color = colores[i % colores.length];

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: servicio.valorCantidad.toDouble(),
            width: 18,
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            borderSide: BorderSide.none,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calcularMaximoValorServicio(),
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      );
    }).toList();
  }
}
