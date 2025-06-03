import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../models/dashboardViewModel.dart';
import '../services/dashboardService.dart';

/// Widget que muestra los reportes por municipio en el dashboard filtrados por fecha
class DashboardReportesPorMunicipioFecha extends StatefulWidget {
  const DashboardReportesPorMunicipioFecha({
    Key? key,
  }) : super(key: key);

  @override
  State<DashboardReportesPorMunicipioFecha> createState() => _DashboardReportesPorMunicipioFechaState();
}

class _DashboardReportesPorMunicipioFechaState extends State<DashboardReportesPorMunicipioFecha> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = false;
  String? _errorMessage;
  List<ReportePorMunicipio> _reportesPorMunicipio = [];
  
  // Fechas por defecto (6 meses atrás hasta hoy)
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 180));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reportes = await _dashboardService.obtenerReportesPorMunicipioPorFecha(
        _fechaInicio, 
        _fechaFin
      );
      
      setState(() {
        _reportesPorMunicipio = reportes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Mensaje de error amigable para el usuario
        if (e.toString().contains('Sin conexión a internet')) {
          _errorMessage =
              'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.';
        } else {
          _errorMessage =
              'No se pudo cargar la información de reportes por municipio. Por favor, intenta más tarde.';
        }
      });
      print('Error al cargar reportes por municipio por fecha: $e');
    }
  }

  // Función para seleccionar fecha de inicio
  Future<void> _seleccionarFechaInicio(BuildContext context) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: _fechaFin,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF26C6DA), // Color principal
              onPrimary: Colors.white, // Color del texto sobre el color principal
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null && fechaSeleccionada != _fechaInicio) {
      setState(() {
        _fechaInicio = fechaSeleccionada;
      });
      _cargarDatos();
    }
  }

  // Función para seleccionar fecha de fin
  Future<void> _seleccionarFechaFin(BuildContext context) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: _fechaInicio,
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF26C6DA), // Color principal
              onPrimary: Colors.white, // Color del texto sobre el color principal
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null && fechaSeleccionada != _fechaFin) {
      setState(() {
        _fechaFin = fechaSeleccionada;
      });
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reportes por Municipio (Por Fecha)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF26C6DA)),
                onPressed: _cargarDatos,
                tooltip: 'Actualizar datos',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Distribución de reportes según la ubicación geográfica y rango de fechas.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          
          // Filtros de fecha
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFechaInicio(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha Inicio',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(_fechaInicio),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Icon(Icons.calendar_today, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFechaFin(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha Fin',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(_fechaFin),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Icon(Icons.calendar_today, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Mostrar error si existe
          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          
          // Mostrar indicador de carga o gráfico
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _buildChart(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_reportesPorMunicipio.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            'No hay datos disponibles para el período seleccionado',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: SfCartesianChart(
        title: ChartTitle(
          text: 'Top ${_reportesPorMunicipio.length} Municipios',
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
            dataSource: _reportesPorMunicipio,
            xValueMapper: (ReportePorMunicipio data, _) => data.etiquetaMunicipio,
            yValueMapper: (ReportePorMunicipio data, _) => data.valorCantidad,
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
    );
  }
}
