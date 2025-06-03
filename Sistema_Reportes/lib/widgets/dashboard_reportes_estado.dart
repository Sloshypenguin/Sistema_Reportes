import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboardViewModel.dart';

/// Widget que muestra los reportes por estado en el dashboard
class DashboardReportesPorEstado extends StatelessWidget {
  final List<ReportePorEstado> reportesPorEstado;

  const DashboardReportesPorEstado({
    super.key,
    required this.reportesPorEstado,
  });

  @override
  Widget build(BuildContext context) {
    if (reportesPorEstado.isEmpty) {
      return const SizedBox.shrink();
    }

    // Mapa de códigos de estado a nombres y colores
    final Map<String, String> estadoNombres = {
      'P': 'Pendiente',
      'G': 'En Gestión',
      'R': 'Resuelto',
      'C': 'Cancelado',
    };

    final Map<String, Color> estadoColores = {
      'P': Colors.orange,
      'G': Colors.blue,
      'R': Colors.green,
      'C': Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes por Estado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: _generarSecciones(
                        reportesPorEstado,
                        estadoColores,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildLegend(
                    reportesPorEstado,
                    estadoNombres,
                    estadoColores,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generarSecciones(
    List<ReportePorEstado> reportes,
    Map<String, Color> colores,
  ) {
    // Calcular el total para los porcentajes
    final int total = reportes.fold(0, (sum, item) => sum + item.cantidad);

    return reportes.map((reporte) {
      final double porcentaje =
          total > 0 ? (reporte.cantidad / total) * 100 : 0;
      final Color color = colores[reporte.estadoCodigo] ?? Colors.grey;

      return PieChartSectionData(
        color: color,
        value: reporte.cantidad.toDouble(),
        title: '${porcentaje.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(
    List<ReportePorEstado> reportes,
    Map<String, String> nombres,
    Map<String, Color> colores,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          reportes.map((reporte) {
            final String nombre =
                nombres[reporte.estadoCodigo] ?? 'Desconocido';
            final Color color = colores[reporte.estadoCodigo] ?? Colors.grey;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$nombre: ${reporte.cantidad}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
