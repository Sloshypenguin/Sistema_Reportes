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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Principal')),
      body: RefreshIndicator(
        onRefresh: _refrescarReportes,
        child:
            _isLoading
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
                          itemBuilder:
                              (context, item, index) => _buildReporteCard(item),
                          noItemsFoundIndicatorBuilder:
                              (context) =>
                                  const Center(child: Text('No hay reportes.')),
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
                    child: const Center(child: CircularProgressIndicator()),
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
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white, // Fondo blanco como Facebook
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _mostrarDetallesReporte(reporte);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera estilo Facebook con avatar y datos del autor
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar del usuario
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      reporte.persona.isNotEmpty
                          ? reporte.persona[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Información del autor y reporte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del autor
                        Text(
                          reporte.persona,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        // Badge de estado en línea separada
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorEstado(reporte.repo_Estado),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getIconoEstado(reporte.repo_Estado),
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getTextoEstado(reporte.repo_Estado),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ID del reporte
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'ID: ${reporte.repo_Id}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Fecha y servicio
                        Row(
                          children: [
                            Icon(
                              Icons.build,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reporte.serv_Nombre,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Acciones rápidas
                  Row(
                    children: [
                      // Botón editar
                      Container(
                        margin: const EdgeInsets.only(right: 8),
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
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          tooltip: 'Editar reporte',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      // Menú de más opciones
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'detalles',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Ver detalles'),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (value) {
                          if (value == 'detalles') {
                            _mostrarDetallesReporte(reporte);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Divider
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            // Contenido del reporte
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  
                  // Ubicación del reporte
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
                          child: const Icon(
                            Icons.build,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Servicio: ${reporte.serv_Nombre}',
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SECCIÓN DE OBSERVACIONES MEJORADA
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  // Botón para ver observaciones en página separada
                  ListTile(
                    onTap: () {
                      // Usando una pantalla separada para mostrar las observaciones
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlantillaBase(
                            titulo: 'Observaciones del Reporte',
                            mostrarBotonRegresar: true,
                            child: _ObservacionesScreen(reporte: reporte),
                          ),
                        ),
                      );
                    },
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
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
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
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PlantillaBase(
                                  titulo: 'Agregar Observación',
                                  mostrarBotonRegresar: true,
                                  child: ReporteDetalleCrear(
                                    titulo: 'Crear Observación',
                                    reporte:
                                        reporte, // Pasas el objeto reporte completo
                                  ),
                                ),
                          ),
                        );
                      },
                      leading: Icon(
                        Icons.note_add,
                        color: Colors.green.shade700,
                      ),
                      title: Text(
                        'Agregar observación',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer con prioridad mejorado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            reporte.repo_Prioridad
                                ? [Colors.red.shade600, Colors.red.shade400]
                                : [Colors.green.shade600, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              reporte.repo_Prioridad
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
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
                          'Prioridad: ${reporte.prioridad}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Indicador para ver más detalles
                  InkWell(
                    onTap: () => _mostrarDetallesReporte(reporte),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver detalles',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.blue.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra los detalles del reporte en un diálogo
  void _mostrarDetallesReporte(Reporte reporte) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

// Pantalla para mostrar las observaciones de un reporte
class _ObservacionesScreen extends StatelessWidget {
  final Reporte reporte;
  
  const _ObservacionesScreen({Key? key, required this.reporte}) : super(key: key);

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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error al cargar observaciones: ${snapshot.error}',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade700,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay observaciones para este reporte',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final detalle = snapshot.data![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade50,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.comment,
                                  size: 18,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Observación #${index + 1}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      detalle.rdet_Observacion,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Eliminamos la referencia a la fecha que causaba el error
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Botón flotante para agregar observación
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantillaBase(
                      titulo: 'Agregar Observación',
                      mostrarBotonRegresar: true,
                      child: ReporteDetalleCrear(
                        titulo: 'Crear Observación',
                        reporte: reporte,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Observación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
