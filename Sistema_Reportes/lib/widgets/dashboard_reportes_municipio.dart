import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/dashboardViewModel.dart';

/// Widget que muestra los reportes por municipio en el dashboard (versión móvil)
class DashboardReportesPorMunicipio extends StatelessWidget {
  final List<ReportePorMunicipio> reportesPorMunicipio;

  const DashboardReportesPorMunicipio({
    Key? key,
    required this.reportesPorMunicipio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reportesPorMunicipio.isEmpty) {
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
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes por Municipio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Distribución de reportes según la ubicación geográfica.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: SfCartesianChart(
              title: ChartTitle(
                text: 'Top ${reportesPorMunicipio.length} Municipios',
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              primaryXAxis: CategoryAxis(
                labelIntersectAction: AxisLabelIntersectAction.rotate45,
                labelStyle: const TextStyle(fontSize: 10),
                maximumLabels: 10,
                isVisible: true,
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Cantidad'),
                minimum: 0,
                interval: 1,
                labelFormat: '{value}',
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(width: 0),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<ReportePorMunicipio, String>>[
                ColumnSeries<ReportePorMunicipio, String>(
                  dataSource: reportesPorMunicipio,
                  xValueMapper:
                      (ReportePorMunicipio data, _) => data.etiquetaMunicipio,
                  yValueMapper:
                      (ReportePorMunicipio data, _) => data.valorCantidad,
                  name: 'Reportes',
                  color: const Color(0xFF26C6DA), // Turquesa profesional
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  width: 0.7,
                  spacing: 0.2,
                  animationDuration: 1000,
                ),
              ],
              legend: Legend(isVisible: false),
              plotAreaBorderWidth: 0,
            ),
          ),
        ],
      ),
    );
  }
}
