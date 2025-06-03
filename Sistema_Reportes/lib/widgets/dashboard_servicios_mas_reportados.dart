import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';
import 'dart:math' as math;

/// Widget que muestra los servicios más reportados en el dashboard
class DashboardServiciosMasReportados extends StatelessWidget {
  final List<ServicioMasReportado> serviciosMasReportados;

  const DashboardServiciosMasReportados({
    super.key,
    required this.serviciosMasReportados,
  });

  @override
  Widget build(BuildContext context) {
    if (serviciosMasReportados.isEmpty) {
      return const SizedBox.shrink();
    }

    // Obtener el servicio más reportado (el primero de la lista)
    final servicioMasReportado = serviciosMasReportados.first;
    
    // Generar un color aleatorio pero consistente basado en el nombre del servicio
    final int colorSeed = servicioMasReportado.etiquetaServicio.hashCode;
    final Color serviceColor = Color(0xFF000000 + (math.Random(colorSeed).nextInt(0xFFFFFF) & 0xFFFFFF));
    // Asegurar que el color sea lo suficientemente oscuro para el texto blanco
    final Color adjustedColor = HSLColor.fromColor(serviceColor)
        .withLightness(0.4)
        .withSaturation(0.7)
        .toColor();

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
            'Servicio Más Reportado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200, // Aumentado para evitar desbordamiento
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  adjustedColor,
                  adjustedColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: adjustedColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Mostrar más información o navegar a detalles
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Servicio: ${servicioMasReportado.etiquetaServicio}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.05),
                child: Stack(
                  children: [
                    // Círculo decorativo
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Círculo decorativo pequeño
                    Positioned(
                      left: 20,
                      top: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icono
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.report_problem_outlined,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Nombre del servicio
                          Text(
                            servicioMasReportado.etiquetaServicio,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Cantidad de reportes
                          Row(
                            children: [
                              Text(
                                '${servicioMasReportado.valorCantidad}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'reportes',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
