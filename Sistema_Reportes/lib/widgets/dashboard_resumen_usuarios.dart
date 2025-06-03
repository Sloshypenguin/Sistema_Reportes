import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';

/// Widget que muestra el resumen de usuarios en el dashboard
class DashboardResumenUsuarios extends StatelessWidget {
  final ResumenUsuarios resumenUsuarios;

  const DashboardResumenUsuarios({super.key, required this.resumenUsuarios});

  @override
  Widget build(BuildContext context) {
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
            'Resumen de Usuarios',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoCard(
                context,
                'Total Usuarios',
                resumenUsuarios.datoTotalUsuarios.toString(),
                Colors.blue,
                Icons.people,
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                context,
                'Administradores',
                resumenUsuarios.datoAdministradores.toString(),
                Colors.purple,
                Icons.admin_panel_settings,
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                context,
                'Empleados',
                resumenUsuarios.datoEmpleados.toString(),
                Colors.teal,
                Icons.work,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
