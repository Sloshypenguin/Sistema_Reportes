import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/dashboardViewModel.dart';

class DashboardDistribucionReportes extends StatelessWidget {
  final ResumenReportes resumenReportes;

  const DashboardDistribucionReportes({Key? key, required this.resumenReportes})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<_EstadisticaReporte> datos = _getChartData();

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
          // Título del gráfico
          const Text(
            'Distribución de Reportes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),

          // Descripción breve
          Text(
            'Estados actuales de los reportes registrados.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Gráfico circular
          SizedBox(
            height: 260,
            child: SfCircularChart(
              title: ChartTitle(
                text: 'Total: ${resumenReportes.datoTotalReportes}',
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              series: <CircularSeries>[
                DoughnutSeries<_EstadisticaReporte, String>(
                  dataSource: datos,
                  xValueMapper: (_EstadisticaReporte data, _) => data.categoria,
                  yValueMapper: (_EstadisticaReporte data, _) => data.valor,
                  pointColorMapper: (_EstadisticaReporte data, _) => data.color,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    connectorLineSettings: ConnectorLineSettings(
                      type: ConnectorType.curve,
                      length: '15%',
                      color: Colors.grey[400],
                    ),
                    labelAlignment: ChartDataLabelAlignment.auto,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  animationDuration: 1200,
                  explode: true,
                  explodeIndex: 0,
                  radius: '80%',
                  innerRadius: '50%',
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
    );
  }

  List<_EstadisticaReporte> _getChartData() {
    return [
      _EstadisticaReporte(
        'Pendientes',
        resumenReportes.datoPendientes,
        const Color(0xFFFFA726),
      ),
      _EstadisticaReporte(
        'Resueltos',
        resumenReportes.datoResueltos,
        const Color(0xFF66BB6A),
      ),
      _EstadisticaReporte(
        'En Gestión',
        resumenReportes.datoEnGestion,
        const Color(0xFF9575CD),
      ),
      _EstadisticaReporte(
        'Cancelados',
        resumenReportes.datoCancelados,
        const Color(0xFFEF5350),
      ),
    ];
  }
}

/// Clase auxiliar para representar los datos en el gráfico
class _EstadisticaReporte {
  final String categoria;
  final int valor;
  final Color color;

  _EstadisticaReporte(this.categoria, this.valor, this.color);
}
