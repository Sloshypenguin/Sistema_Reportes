import 'package:flutter/material.dart';
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

    // Ordenar los municipios por cantidad de reportes (mayor a menor)
    final sortedReportes = List<ReportePorMunicipio>.from(reportesPorMunicipio)
      ..sort((a, b) => b.valorCantidad.compareTo(a.valorCantidad));

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
      ),
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
