import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/reporteService.dart';
import '../models/reporteViewModel.dart';


class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  final _storage = FlutterSecureStorage();
  final ReporteService _reporteService = ReporteService();

  // Datos del usuario
  String nombreUsuario = 'Usuario';
  String correoUsuario = '';
  String rolUsuario = 'Rol no disponible';
  int usuarioId = 0;
  int persId = 0;
  int roleId = 0;
  bool esAdmin = false;
  bool esEmpleado = false;

  // Variables para los reportes
  List<Reporte> _reportes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarReportes();
  }

  /// Carga los reportes desde el servicio
  Future<void> _cargarReportes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reportes = await _reporteService.listarReportes();
      
      setState(() {
        _reportes = reportes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Refresca la lista de reportes
  Future<void> _refrescarReportes() async {
    await _cargarReportes();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final nombre = await _storage.read(key: 'usuario_nombre');
      final rol = await _storage.read(key: 'usuario_rol');
      final correo = await _storage.read(key: 'usuario_correo');
      final idStr = await _storage.read(key: 'usuario_id');
      final persIdStr = await _storage.read(key: 'pers_id');
      final roleIdStr = await _storage.read(key: 'role_id');
      final esAdminStr = await _storage.read(key: 'usuario_es_admin');
      final esEmpleadoStr = await _storage.read(key: 'usuario_es_empleado');

      setState(() {
        nombreUsuario = nombre ?? 'Usuario';
        correoUsuario = correo ?? '';
        rolUsuario = rol ?? 'Rol no disponible';
        usuarioId = int.tryParse(idStr ?? '') ?? 0;
        persId = int.tryParse(persIdStr ?? '') ?? 0;
        roleId = int.tryParse(roleIdStr ?? '') ?? 0;
        esAdmin = esAdminStr == 'true';
        esEmpleado = esEmpleadoStr == 'true';
      });
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }

  /// Retorna el color basado en la prioridad del reporte
  Color _getColorPrioridad(bool esPrioritario) {
    return esPrioritario ? Colors.red.shade100 : Colors.blue.shade50;
  }

  /// Retorna el icono basado en el estado del reporte
  IconData _getIconoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'P':
        return Icons.pending;
      case 'C':
        return Icons.check_circle;
      case 'R':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Retorna el color del icono basado en el estado
  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'P':
        return Colors.orange;
      case 'C':
        return Colors.green;
      case 'R':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Retorna el texto del estado
  String _getTextoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'P':
        return 'Pendiente';
      case 'C':
        return 'Completado';
      case 'R':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }

  /// Widget para construir cada tarjeta de reporte
  Widget _buildReporteCard(Reporte reporte) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _getColorPrioridad(reporte.repo_Prioridad),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _mostrarDetallesReporte(reporte);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ID y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${reporte.repo_Id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _getIconoEstado(reporte.repo_Estado),
                        color: _getColorEstado(reporte.repo_Estado),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTextoEstado(reporte.repo_Estado),
                        style: TextStyle(
                          color: _getColorEstado(reporte.repo_Estado),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Descripción del reporte
              Text(
                reporte.repo_Descripcion,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Información del servicio
              Row(
                children: [
                  Icon(Icons.build, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reporte.serv_Nombre,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Información de la persona reportante
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reportado por: ${reporte.persona}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Footer con prioridad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reporte.repo_Prioridad ? Colors.red.shade600 : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reporte.repo_Prioridad ? Icons.priority_high : Icons.low_priority,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reporte.prioridad,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra los detalles del reporte en un diálogo
  void _mostrarDetallesReporte(Reporte reporte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reporte #${reporte.repo_Id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('Descripción:', reporte.repo_Descripcion),
              _buildDetalleItem('Servicio:', reporte.serv_Nombre),
              _buildDetalleItem('Reportado por:', reporte.persona),
              _buildDetalleItem('Estado:', _getTextoEstado(reporte.repo_Estado)),
              _buildDetalleItem('Prioridad:', reporte.prioridad),
              if (reporte.repo_Ubicacion != null && reporte.repo_Ubicacion!.isNotEmpty)
                _buildDetalleItem('Ubicación:', reporte.repo_Ubicacion!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Widget helper para mostrar detalles en el diálogo
  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// Widget para mostrar estadísticas en el header
  Widget _buildEstadisticaItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando reportes...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar reportes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refrescarReportes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Intentar nuevamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _reportes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay reportes disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refrescarReportes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refrescarReportes,
                      child: Column(
                        children: [
                          // Header con información de estadísticas
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade600, Colors.blue.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade200,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Resumen de Reportes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildEstadisticaItem(
                                      'Total',
                                      _reportes.length.toString(),
                                      Icons.list_alt,
                                    ),
                                    _buildEstadisticaItem(
                                      'Prioritarios',
                                      _reportes.where((r) => r.repo_Prioridad).length.toString(),
                                      Icons.priority_high,
                                    ),
                                    _buildEstadisticaItem(
                                      'Pendientes',
                                      _reportes.where((r) => r.repo_Estado.toUpperCase() == 'P').length.toString(),
                                      Icons.pending,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Lista de reportes
                          Expanded(
                            child: ListView.builder(
                              itemCount: _reportes.length,
                              itemBuilder: (context, index) {
                                return _buildReporteCard(_reportes[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'crear_reporte',
        onPressed: () {
          Navigator.pushNamed(context, '/CrearReporte');
        },
        tooltip: 'Crear nuevo reporte',
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Crear Reporte',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}