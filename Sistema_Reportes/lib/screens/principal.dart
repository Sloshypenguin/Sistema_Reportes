import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../services/reporteService.dart';
import '../models/reporteViewModel.dart';
import '../models/reporteDetalleViewModel.dart';
import '../services/reporteDetalleService.dart';
import '../screens/reporteDetalleCrear.dart';
import '../layout/plantilla_base.dart';



class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
  }


class _PrincipalScreenState extends State<PrincipalScreen> {
  final _storage = FlutterSecureStorage();
  final ReporteService _reporteService = ReporteService();
  final ReporteDetalleService _reporteDetalleService = ReporteDetalleService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Principal'),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescarReportes,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      // Estadísticas
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEstadisticaCard(
                              icon: Icons.list_alt,
                              label: 'Total',
                              value: _totalReportes.toString(),
                              color: Colors.blue,
                            ),
                            _buildEstadisticaCard(
                              icon: Icons.priority_high,
                              label: 'Prioritarios',
                              value: _reportesPrioritarios.toString(),
                              color: Colors.red,
                            ),
                            _buildEstadisticaCard(
                              icon: Icons.pending,
                              label: 'Pendientes',
                              value: _reportesPendientes.toString(),
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      // Lista de reportes
                      Expanded(
                        child: PagedListView<int, Reporte>(
                          pagingController: _pagingController,
                          builderDelegate: PagedChildBuilderDelegate<Reporte>(
                            itemBuilder: (context, item, index) =>
                                _buildReporteCard(item),
                            noItemsFoundIndicatorBuilder: (context) =>
                                const Center(
                              child: Text('No hay reportes.'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/CrearReporte');
        },
        child: const Icon(Icons.add),
        tooltip: 'Crear nuevo reporte',
      ),
    );
  }

  Widget _buildEstadisticaCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // Datos del usuario
  String nombreUsuario = 'Usuario';
  String correoUsuario = '';
  String rolUsuario = 'Rol no disponible';
  int usuarioId = 0;
  int persId = 0;
  int roleId = 0;
  bool esAdmin = false;
  bool esEmpleado = false;

  // Variables para estadísticas
  int _totalReportes = 0;
  int _reportesPrioritarios = 0;
  int _reportesPendientes = 0;
  bool _isLoading = true;
  String? _error;

  // Constantes para paginación
  static const _pageSize = 10;

  // Controlador de paginación
  final PagingController<int, Reporte> _pagingController = PagingController(
    firstPageKey: 1,
  );

  // Mapa para almacenar las imágenes de cada reporte
  Map<int, List<Map<String, dynamic>>> _imagenesPorReporte = {};
  bool _cargandoImagenes = false;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    _cargarDatosUsuario();
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  /// Carga las estadísticas generales de reportes
  Future<void> _cargarEstadisticas() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener todos los reportes para calcular estadísticas
      final reportes = await _reporteService.listarReportes(
        page: 1,
        pageSize: 1000,
      );

      if (!mounted) return;
      setState(() {
        _totalReportes = reportes.length;
        _reportesPrioritarios = reportes.where((r) => r.repo_Prioridad).length;
        _reportesPendientes =
            reportes.where((r) => r.repo_Estado.toUpperCase() == 'P').length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Carga una página de reportes para el infinite scroll
  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;

    try {
      final reportes = await _reporteService.listarReportes(
        page: pageKey,
        pageSize: _pageSize,
      );

      // Cargar las imágenes de los reportes de esta página
      _cargarImagenesReportes(reportes);

      final isLastPage = reportes.length < _pageSize;

      if (isLastPage) {
        _pagingController.appendLastPage(reportes);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(reportes, nextPageKey);
      }
    } catch (e) {
      if (!mounted) return;
      _pagingController.error = e;
      setState(() {
        _error = e.toString();
      });
    }
  }

  /// Carga las imágenes para cada reporte
  Future<void> _cargarImagenesReportes(List<Reporte> reportes) async {
    if (!mounted) return;

    try {
      setState(() {
        _cargandoImagenes = true;
      });

      final imagenesMap = <int, List<Map<String, dynamic>>>{};

      for (final reporte in reportes) {
        if (!mounted) return;

        try {
          final imagenes = await _reporteService.obtenerImagenesPorReporte(
            reporte.repo_Id,
          );
          imagenesMap[reporte.repo_Id] = imagenes;
        } catch (e) {
          debugPrint(
            'Error al cargar imágenes para reporte ${reporte.repo_Id}: $e',
          );
          // Continuar con el siguiente reporte si hay un error
        }
      }

      if (!mounted) return;
      setState(() {
        _imagenesPorReporte.addAll(imagenesMap);
        _cargandoImagenes = false;
      });
    } catch (e) {
      debugPrint('Error al cargar imágenes de reportes: $e');
      if (!mounted) return;
      setState(() {
        _cargandoImagenes = false;
      });
    }
  }

  /// Refresca la lista de reportes
  Future<void> _refrescarReportes() async {
    if (!mounted) return;

    try {
      // Mostrar indicador de carga
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Actualizar estadísticas
      await _cargarEstadisticas();

      // Reiniciar el controlador de paginación
      _pagingController.refresh();

      return Future.value();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      return Future.error(e);
    }
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
        return Icons.pending; // Pendiente
      case 'G':
        return Icons.build_circle; // En Gestión
      case 'R':
        return Icons.check_circle; // Resuelto
      case 'C':
        return Icons.cancel; // Cancelado
      default:
        return Icons.help_outline;
    }
  }

  /// Retorna el color del icono basado en el estado
  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'P':
        return Colors.orange; // Pendiente
      case 'G':
        return Colors.blue; // En Gestión
      case 'R':
        return Colors.green; // Resuelto
      case 'C':
        return Colors.red; // Cancelado
      default:
        return Colors.grey;
    }
  }

  /// Retorna el texto del estado
  String _getTextoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'P':
        return 'Pendiente';
      case 'G':
        return 'En Gestión';
      case 'R':
        return 'Resuelto';
      case 'C':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  /// Widget para mostrar las imágenes del reporte
  Widget _buildImagenesReporte(int reporteId) {
    final imagenes = _imagenesPorReporte[reporteId] ?? [];
    
    if (imagenes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          final imagen = imagenes[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagen['url'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReporteCard(Reporte reporte) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _getColorPrioridad(reporte.repo_Prioridad),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _mostrarDetallesReporte(reporte);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ID, estado y botón editar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                      // Estado con animación
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getColorEstado(reporte.repo_Estado).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getColorEstado(reporte.repo_Estado),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconoEstado(reporte.repo_Estado),
                              color: _getColorEstado(reporte.repo_Estado),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTextoEstado(reporte.repo_Estado),
                              style: TextStyle(
                                color: _getColorEstado(reporte.repo_Estado),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón editar mejorado
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context, 
                              '/EditarReporte',
                              arguments: reporte,
                            );
                          },
                          icon: Icon(Icons.edit, size: 18, color: Colors.orange.shade700),
                          tooltip: 'Editar',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Descripción del reporte con mejor tipografía
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  reporte.repo_Descripcion,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 16),

              // Imágenes del reporte
              _buildImagenesReporte(reporte.repo_Id),

              const SizedBox(height: 12),

              // Información del servicio con iconos mejorados
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.build, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reporte.serv_Nombre,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Información de la persona reportante
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reportado por: ${reporte.persona}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dirección
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.map, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ubicación: ${reporte.repo_Ubicacion ?? 'No especificada'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SECCIÓN DE OBSERVACIONES MEJORADA
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.grey.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ExpansionTile para ver observaciones
                    ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        'Ver Observaciones',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(12),
                      children: [
                        FutureBuilder<List<ReporteDetalle>>(
                          future: _reporteDetalleService.listarPorReporte(reporte.repo_Id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(12),
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
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error al cargar observaciones',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No hay observaciones para este reporte',
                                        style: TextStyle(
                                          color: Colors.amber.shade800,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              children: snapshot.data!.map((detalle) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade50,
                                        blurRadius: 3,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.comment,
                                          size: 16,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          detalle.rdet_Observacion,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    // Divisor elegante
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey.shade300,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    
                    // Botón Agregar Observación mejorado
                   Container(
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantillaBase(
                titulo: 'Agregar Observación',
                mostrarBotonRegresar: true,
                child: ReporteDetalleCrear(
                  titulo: 'Crear Observación',
                  reporte: reporte, // Pasas el objeto reporte completo
                ),
              ),
            ),
          );
        },
        icon: Icon(Icons.note_add, size: 18, color: Colors.green.shade700),
        tooltip: 'Agregar Observación',
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
      ),
    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Footer con prioridad mejorado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: reporte.repo_Prioridad
                            ? [Colors.red.shade600, Colors.red.shade400]
                            : [Colors.green.shade600, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (reporte.repo_Prioridad 
                              ? Colors.red.shade200 
                              : Colors.green.shade200),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reporte.repo_Prioridad
                              ? Icons.priority_high
                              : Icons.low_priority,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reporte.prioridad,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
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
              _buildDetalleItem(
                'Estado:',
                _getTextoEstado(reporte.repo_Estado),
              ),
              _buildDetalleItem('Prioridad:', reporte.prioridad),
              if (reporte.repo_Ubicacion != null &&
                  reporte.repo_Ubicacion!.isNotEmpty)
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}