import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';
import 'dart:math' as math;

/// Widget que muestra el resumen de estado por servicio en el dashboard
class DashboardResumenEstadoServicio extends StatefulWidget {
  final List<ResumenEstadoPorServicio> resumenEstadoPorServicio;

  const DashboardResumenEstadoServicio({
    super.key,
    required this.resumenEstadoPorServicio,
  });

  @override
  State<DashboardResumenEstadoServicio> createState() =>
      _DashboardResumenEstadoServicioState();
}

class _DashboardResumenEstadoServicioState
    extends State<DashboardResumenEstadoServicio>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _servicioSeleccionado;
  bool _mostrarDetalle = false;

  @override
  void initState() {
    super.initState();
    // Agrupar datos por servicio
    final servicios = _obtenerServicios();
    _tabController = TabController(length: servicios.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _servicioSeleccionado = servicios[_tabController.index];
          _mostrarDetalle = true;
        });
      }
    });

    if (servicios.isNotEmpty) {
      _servicioSeleccionado = servicios.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _obtenerServicios() {
    final Set<String> servicios = {};
    for (var item in widget.resumenEstadoPorServicio) {
      servicios.add(item.servicioNombre);
    }
    return servicios.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resumenEstadoPorServicio.isEmpty) {
      return const SizedBox.shrink();
    }

    final servicios = _obtenerServicios();

    // Agrupar datos por servicio
    final Map<String, Map<String, int>> serviciosPorEstado = {};
    final Set<String> todosLosEstados = {};

    for (var item in widget.resumenEstadoPorServicio) {
      if (!serviciosPorEstado.containsKey(item.servicioNombre)) {
        serviciosPorEstado[item.servicioNombre] = {};
      }
      serviciosPorEstado[item.servicioNombre]![item.estadoCodigo] =
          item.cantidad;
      todosLosEstados.add(item.estadoCodigo);
    }

    // Convertir a lista ordenada de estados
    final List<String> estadosOrdenados = todosLosEstados.toList()..sort();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen de Estado por Servicio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  _mostrarDetalle ? Icons.view_list : Icons.pie_chart,
                  color: Colors.blue.shade700,
                ),
                onPressed: () {
                  setState(() {
                    _mostrarDetalle = !_mostrarDetalle;
                  });
                },
                tooltip:
                    _mostrarDetalle
                        ? 'Ver tabla completa'
                        : 'Ver gráficos por servicio',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selector de servicios con tabs
          if (_mostrarDetalle && servicios.isNotEmpty)
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.blue.shade700,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade700,
                ),
                tabs:
                    servicios.map((servicio) {
                      return Tab(text: servicio);
                    }).toList(),
              ),
            ),

          const SizedBox(height: 16),

          // Vista detallada por servicio seleccionado
          if (_mostrarDetalle && _servicioSeleccionado != null)
            _buildServicioDetalle(
              _servicioSeleccionado!,
              serviciosPorEstado[_servicioSeleccionado!] ?? {},
              estadosOrdenados,
            )
          else
            // Vista de tabla general
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey.shade100,
                ),
                columnSpacing: 20,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                columns: [
                  const DataColumn(label: Text('Servicio')),
                  ...estadosOrdenados.map((estado) {
                    return DataColumn(
                      label: Tooltip(
                        message: _obtenerDescripcionEstado(estado),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: _obtenerColorEstado(estado),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const DataColumn(label: Text('Total')),
                ],
                rows:
                    serviciosPorEstado.entries.map((entry) {
                      final String servicio = entry.key;
                      final Map<String, int> estadosCantidad = entry.value;
                      int total = 0;

                      // Calcular total por servicio
                      estadosCantidad.forEach((_, cantidad) {
                        total += cantidad;
                      });

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              servicio,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              // Seleccionar este servicio para ver detalle
                              final index = servicios.indexOf(servicio);
                              if (index >= 0) {
                                _tabController.animateTo(index);
                                setState(() {
                                  _servicioSeleccionado = servicio;
                                  _mostrarDetalle = true;
                                });
                              }
                            },
                          ),
                          ...estadosOrdenados.map((estado) {
                            final int cantidad = estadosCantidad[estado] ?? 0;
                            return DataCell(
                              Text(
                                cantidad.toString(),
                                style: TextStyle(
                                  color:
                                      cantidad > 0
                                          ? _obtenerColorEstado(estado)
                                          : Colors.grey.shade400,
                                  fontWeight:
                                      cantidad > 0
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          DataCell(
                            Text(
                              total.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),

          const SizedBox(height: 12),

          // Leyenda de estados
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ...estadosOrdenados.map((estado) {
                  return _buildLegendItem(
                    estado,
                    _obtenerDescripcionEstado(estado),
                    _obtenerColorEstado(estado),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar el detalle de un servicio específico
  Widget _buildServicioDetalle(
    String servicio,
    Map<String, int> estadosCantidad,
    List<String> estadosOrdenados,
  ) {
    // Calcular el total de reportes para este servicio
    int totalReportes = 0;
    estadosCantidad.forEach((_, cantidad) {
      totalReportes += cantidad;
    });

    // Preparar datos para el gráfico
    final List<_EstadoData> chartData = [];
    for (var estado in estadosOrdenados) {
      final cantidad = estadosCantidad[estado] ?? 0;
      if (cantidad > 0) {
        chartData.add(
          _EstadoData(
            estado: estado,
            cantidad: cantidad,
            color: _obtenerColorEstado(estado),
            descripcion: _obtenerDescripcionEstado(estado),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del servicio
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                servicio,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total de reportes: $totalReportes',
                style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gráfico de barras horizontal
        if (chartData.isNotEmpty)
          SizedBox(
            height: math.max(chartData.length * 50.0, 100),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chartData.length,
              itemBuilder: (context, index) {
                final data = chartData[index];
                final double porcentaje =
                    totalReportes > 0
                        ? (data.cantidad / totalReportes) * 100
                        : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: data.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                data.estado,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data.descripcion,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${data.cantidad} (${porcentaje.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: data.color,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Barra de progreso
                      Stack(
                        children: [
                          // Fondo
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          // Barra de progreso
                          FractionallySizedBox(
                            widthFactor: porcentaje / 100,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: data.color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No hay datos para mostrar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegendItem(String codigo, String descripcion, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$codigo: $descripcion', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _obtenerDescripcionEstado(String codigo) {
    switch (codigo) {
      case 'P':
        return 'Pendiente';
      case 'R':
        return 'Realizado';
      case 'A':
        return 'Asignado';
      case 'E':
        return 'En Proceso';
      case 'G':
        return 'Gestionado';
      case 'C':
        return 'Cerrado';
      case 'X':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  Color _obtenerColorEstado(String codigo) {
    switch (codigo) {
      case 'P':
        return Colors.orange;
      case 'R':
        return Colors.blue;
      case 'A':
        return Colors.purple;
      case 'E':
        return Colors.amber.shade700;
      case 'G':
        return Colors.teal;
      case 'C':
        return Colors.green;
      case 'X':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Clase para almacenar datos de estado para visualización
class _EstadoData {
  final String estado;
  final int cantidad;
  final Color color;
  final String descripcion;

  _EstadoData({
    required this.estado,
    required this.cantidad,
    required this.color,
    required this.descripcion,
  });
}
