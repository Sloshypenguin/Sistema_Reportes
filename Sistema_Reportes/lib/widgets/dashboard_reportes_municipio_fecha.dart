import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboardViewModel.dart';
import '../models/departamentoViewModel.dart';
import '../services/dashboardService.dart';
import '../services/departamentoService.dart';

/// Widget que muestra los reportes por municipio en el dashboard filtrados por fecha
class DashboardReportesPorMunicipioFecha extends StatefulWidget {
  const DashboardReportesPorMunicipioFecha({Key? key}) : super(key: key);

  @override
  State<DashboardReportesPorMunicipioFecha> createState() =>
      _DashboardReportesPorMunicipioFechaState();
}

class _DashboardReportesPorMunicipioFechaState
    extends State<DashboardReportesPorMunicipioFecha> {
  final DashboardService _dashboardService = DashboardService();
  final DepartamentoService _departamentoService = DepartamentoService();
  bool _isLoading = false;
  bool _isLoadingDepartamentos = false;
  String? _errorMessage;
  List<ReportePorMunicipio> _reportesPorMunicipio = [];
  List<Map<String, String>> _departamentos = [];
  String? _departamentoSeleccionado;

  // Fechas por defecto (6 meses atrás hasta hoy)
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 180));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarDepartamentos();
    _cargarDatos();
  }

  Future<void> _cargarDepartamentos() async {
    setState(() {
      _isLoadingDepartamentos = true;
    });

    try {
      // Usar el servicio de departamentos para obtener la lista
      final listaDepartamentos = await _departamentoService.listar();
      
      // Convertir la lista de objetos Departamento a Map<String, String>
      final departamentosMap = listaDepartamentos.map((depa) => {
        'codigo': depa.depa_Codigo,
        'nombre': depa.depa_Nombre,
      }).toList();

      setState(() {
        // Agregar opción "Todos" al inicio de la lista
        _departamentos = [
          {'codigo': 'Todos', 'nombre': 'Todos los departamentos'},
          ...departamentosMap,
        ];
        _departamentoSeleccionado = 'Todos';
        _isLoadingDepartamentos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDepartamentos = false;
        print('Error al cargar departamentos: $e');
      });
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reportes = await _dashboardService
          .obtenerReportesPorMunicipioPorFecha(
            _fechaInicio,
            _fechaFin,
            depaCodigo: _departamentoSeleccionado,
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
      // Eliminar la configuración de locale que causa problemas
      // locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF26C6DA), // Color principal
              onPrimary:
                  Colors.white, // Color del texto sobre el color principal
              onSurface: Colors.black, // Color del texto en la superficie
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                  0xFF26C6DA,
                ), // Color del texto de los botones
              ),
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
      // Eliminar la configuración de locale que causa problemas
      // locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF26C6DA), // Color principal
              onPrimary:
                  Colors.white, // Color del texto sobre el color principal
              onSurface: Colors.black, // Color del texto en la superficie
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                  0xFF26C6DA,
                ), // Color del texto de los botones
              ),
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
                'Reportes por Municipio (filtro)',
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

          // Filtros de fecha y departamento
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarFechaInicio(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha Inicio',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
              const SizedBox(height: 12),
              // Filtro por departamento
              _isLoadingDepartamentos
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                  : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _departamentoSeleccionado,
                        hint: const Text('Seleccione un departamento'),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items:
                            _departamentos.map((departamento) {
                              return DropdownMenuItem<String>(
                                value: departamento['codigo'],
                                child: Text(departamento['nombre']!),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null &&
                              newValue != _departamentoSeleccionado) {
                            setState(() {
                              _departamentoSeleccionado = newValue;
                            });
                            _cargarDatos();
                          }
                        },
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

    // Ordenar los municipios por cantidad de reportes (mayor a menor)
    final sortedReportes = List<ReportePorMunicipio>.from(_reportesPorMunicipio)
      ..sort((a, b) => b.valorCantidad.compareTo(a.valorCantidad));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text(
                'Total municipios: ${sortedReportes.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Total reportes: ${sortedReportes.fold(0, (sum, item) => sum + item.valorCantidad)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PaginatedDataTable(
            header: null,
            rowsPerPage: 10,
            availableRowsPerPage: const [5, 10, 20, 50],
            columns: const [
              DataColumn(
                label: Text(
                  'Municipio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Cantidad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  '% del Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
              ),
            ],
            source: _MunicipioDataSource(sortedReportes),
          ),
        ),
      ],
    );
  }
}

/// Fuente de datos para la tabla paginada de municipios
class _MunicipioDataSource extends DataTableSource {
  final List<ReportePorMunicipio> _reportes;
  final int _totalReportes;

  _MunicipioDataSource(this._reportes)
    : _totalReportes = _reportes.fold(
        0,
        (sum, item) => sum + item.valorCantidad,
      );

  @override
  DataRow getRow(int index) {
    final reporte = _reportes[index];
    final porcentaje =
        _totalReportes > 0
            ? (reporte.valorCantidad / _totalReportes * 100)
            : 0.0;

    return DataRow(
      cells: [
        DataCell(Text(reporte.etiquetaMunicipio)),
        DataCell(Text('${reporte.valorCantidad}')),
        DataCell(Text('${porcentaje.toStringAsFixed(2)}%')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _reportes.length;

  @override
  int get selectedRowCount => 0;
}
