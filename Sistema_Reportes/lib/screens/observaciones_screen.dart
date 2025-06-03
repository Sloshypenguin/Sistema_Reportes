import 'package:flutter/material.dart';
import '../models/reporteViewModel.dart';
import '../models/reporteDetalleViewModel.dart';
import '../services/reporteDetalleService.dart';

/// Pantalla para mostrar las observaciones de un reporte
class ObservacionesScreen extends StatelessWidget {
  final Reporte reporte;
  
  const ObservacionesScreen({Key? key, required this.reporte}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reporteDetalleService = ReporteDetalleService();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y detalles del reporte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporte #${reporte.repo_Id}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reporte.repo_Descripcion,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Título de observaciones
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.comment,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Observaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lista de observaciones
          Expanded(
            child: FutureBuilder<List<ReporteDetalle>>(
              future: reporteDetalleService.listarPorReporte(reporte.repo_Id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error al cargar observaciones: ${snapshot.error}',
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final observaciones = snapshot.data ?? [];

                if (observaciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay observaciones para este reporte',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: observaciones.length,
                  itemBuilder: (context, index) {
                    final observacion = observaciones[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Encabezado con información de la persona
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    observacion.usua_Creacion.toString().substring(0, 1),
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Usuario: ${observacion.usua_Creacion}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Fecha: ${_formatearFecha(observacion.rdet_FechaCreacion)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Contenido de la observación
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(observacion.rdet_Observacion),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Formatea una fecha a un formato legible
  String _formatearFecha(dynamic fecha) {
    try {
      // Si es un string, convertirlo a DateTime
      DateTime fechaObj;
      if (fecha is String) {
        fechaObj = DateTime.parse(fecha);
      } else if (fecha is DateTime) {
        fechaObj = fecha;
      } else {
        return 'Fecha no válida';
      }

      // Verificar si es la fecha por defecto (0001-01-01)
      if (fechaObj.year <= 1) {
        return 'No disponible';
      }

      return '${fechaObj.day}/${fechaObj.month}/${fechaObj.year}';
    } catch (e) {
      return 'Fecha no válida';
    }
  }
}
