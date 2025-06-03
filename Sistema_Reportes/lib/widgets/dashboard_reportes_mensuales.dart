import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';

/// Widget que muestra un gráfico de líneas con los reportes por mes
class DashboardReportesMensuales extends StatelessWidget {
  final List<ReportePorMes> reportesPorMes;

  const DashboardReportesMensuales({
    Key? key, 
    required this.reportesPorMes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reportesPorMes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 300,
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
            'Reportes por Mes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final int index = value.toInt();
                        if (index >= 0 && index < reportesPorMes.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              reportesPorMes[index].etiquetaMes,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _calcularIntervalo(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
                minX: 0,
                maxX: reportesPorMes.length - 1.0,
                minY: 0,
                maxY: _calcularMaximoValor(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _crearPuntos(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.lightBlueAccent.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final int index = barSpot.x.toInt();
                        final mes = reportesPorMes[index].etiquetaMes;
                        final cantidad = reportesPorMes[index].valorCantidad;
                        return LineTooltipItem(
                          '$mes: $cantidad',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calcularMaximoValor() {
    if (reportesPorMes.isEmpty) return 10;
    final maximo = reportesPorMes
        .map((reporte) => reporte.valorCantidad)
        .reduce((curr, next) => curr > next ? curr : next);
    return (maximo * 1.2).ceilToDouble(); // 20% más para espacio
  }

  double _calcularIntervalo() {
    final maximo = _calcularMaximoValor();
    return maximo > 10 ? (maximo / 5).ceilToDouble() : 2;
  }

  List<FlSpot> _crearPuntos() {
    List<FlSpot> spots = [];
    for (int i = 0; i < reportesPorMes.length; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        reportesPorMes[i].valorCantidad.toDouble(),
      ));
    }
    return spots;
  }
}
