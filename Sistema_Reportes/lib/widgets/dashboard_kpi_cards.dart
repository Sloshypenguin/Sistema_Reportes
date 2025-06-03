import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';

/// Widget que muestra las tarjetas de resumen (KPI) del dashboard
class DashboardKpiCards extends StatelessWidget {
  final ResumenReportes resumenReportes;

  const DashboardKpiCards({Key? key, required this.resumenReportes})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKpiCard(
          title: 'Total Reportes',
          value: resumenReportes.datoTotalReportes.toString(),
          icon: Icons.assignment,
          color: Colors.blue,
        ),
        _buildKpiCard(
          title: 'Pendientes',
          value: resumenReportes.datoPendientes.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _buildKpiCard(
          title: 'Resueltos',
          value: resumenReportes.datoResueltos.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildKpiCard(
          title: 'En Gestión',
          value: resumenReportes.datoEnGestion.toString(),
          icon: Icons.sync,
          color: Colors.purple,
        ),
        _buildKpiCard(
          title: 'Cancelados',
          value: resumenReportes.datoCancelados.toString(),
          icon: Icons.cancel,
          color: Colors.red,
        ),
        _buildKpiCard(
          title: 'Reportes Hoy',
          value: resumenReportes.datoHoy.toString(),
          icon: Icons.today,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
