import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';

/// Widget que muestra el top de usuarios con más reportes en el dashboard
class DashboardTopUsuarios extends StatelessWidget {
  final List<TopUsuario> topUsuarios;

  const DashboardTopUsuarios({
    super.key,
    required this.topUsuarios,
  });

  @override
  Widget build(BuildContext context) {
    if (topUsuarios.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Top Usuarios con Más Reportes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topUsuarios.length,
            itemBuilder: (context, index) {
              final usuario = topUsuarios[index];
              return _buildUsuarioItem(
                context,
                usuario,
                index + 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioItem(
    BuildContext context,
    TopUsuario usuario,
    int position,
  ) {
    // Colores para las posiciones top
    final Color positionColor = position <= 3
        ? [Colors.amber, Colors.grey.shade400, Colors.brown.shade300][position - 1]
        : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Posición
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: positionColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              position.toString(),
              style: TextStyle(
                color: position <= 3 ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Información del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.personaNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Cantidad de reportes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${usuario.totalReportes} reportes',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
