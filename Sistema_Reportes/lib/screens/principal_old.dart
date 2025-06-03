import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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
        _imagenesPorReporte = imagenesMap;
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
                            const SizedBox(width: 8),
                          ],
                        ),
                        // Ubicación si existe
                        if (reporte.repo_Ubicacion != null &&
                            reporte.repo_Ubicacion!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reporte.repo_Ubicacion!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
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
                      if (value == 'editar') {
                        Navigator.pushNamed(
                          context,
                          '/EditarReporte',
                          arguments: reporte,
                        );
                      } else if (value == 'detalles') {
                        _mostrarDetallesReporte(reporte);
                      }
                    },
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
                  // Descripción del reporte
                  Text(
                    reporte.repo_Descripcion,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Badge de prioridad
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          reporte.repo_Prioridad
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            reporte.repo_Prioridad
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reporte.repo_Prioridad
                              ? Icons.priority_high
                              : Icons.low_priority,
                          color:
                              reporte.repo_Prioridad
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reporte.prioridad,
                          style: TextStyle(
                            color:
                                reporte.repo_Prioridad
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Imágenes del reporte con estilo mejorado
            _buildImagenesReporteFacebook(reporte.repo_Id),
            // Barra de interacción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de detalles
                  TextButton.icon(
                    onPressed: () => _mostrarDetallesReporte(reporte),
                    icon: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    label: Text(
                      'Ver detalles',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  // Botón de editar
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/EditarReporte',
                        arguments: reporte,
                      );
                    },
                    icon: Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    label: Text(
                      'Editar',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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

  /// Widget para mostrar las imágenes de un reporte con estilo Facebook
  Widget _buildImagenesReporteFacebook(int reporteId) {
    final imagenes = _imagenesPorReporte[reporteId] ?? [];

    if (_cargandoImagenes && imagenes.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (imagenes.isEmpty) {
      return const SizedBox.shrink(); // No mostrar nada si no hay imágenes
    }

    // Si hay solo una imagen, mostrarla a pantalla completa
    if (imagenes.length == 1) {
      final imagen = imagenes[0];
      final imagenUrl = imagen['imre_Imagen'];

      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'http://sistemareportesgob.somee.com$imagenUrl',
            ),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Si hay 2 imágenes, mostrarlas en grid 1x2
    if (imagenes.length == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'http://sistemareportesgob.somee.com${imagenes[0]['imre_Imagen']}',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'http://sistemareportesgob.somee.com${imagenes[1]['imre_Imagen']}',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si hay 3 o más imágenes, mostrar grid 2x2 con indicador de más
    if (imagenes.length >= 3) {
      return SizedBox(
        height: 240,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'http://sistemareportesgob.somee.com${imagenes[0]['imre_Imagen']}',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'http://sistemareportesgob.somee.com${imagenes[1]['imre_Imagen']}',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'http://sistemareportesgob.somee.com${imagenes[2]['imre_Imagen']}',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child:
                        imagenes.length > 3
                            ? Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'http://sistemareportesgob.somee.com${imagenes[3]['imre_Imagen']}',
                                      ),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.4),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                ),
                                if (imagenes.length > 4)
                                  Center(
                                    child: Text(
                                      '+${imagenes.length - 4}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                            : Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'http://sistemareportesgob.somee.com${imagenes[3]['imre_Imagen']}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Fallback al diseño original para otros casos
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          final imagen = imagenes[index];
          final imagenUrl = imagen['imre_Imagen'];

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(
                  'http://sistemareportesgob.somee.com$imagenUrl',
                ),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
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
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
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
              : Column(
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
                              _totalReportes.toString(),
                              Icons.list_alt,
                            ),
                            _buildEstadisticaItem(
                              'Prioritarios',
                              _reportesPrioritarios.toString(),
                              Icons.priority_high,
                            ),
                            _buildEstadisticaItem(
                              'Pendientes',
                              _reportesPendientes.toString(),
                              Icons.pending,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Lista de reportes con paginación
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refrescarReportes,
                      child: PagedListView<int, Reporte>(
                        pagingController: _pagingController,
                        builderDelegate: PagedChildBuilderDelegate<Reporte>(
                          itemBuilder:
                              (context, reporte, index) =>
                                  _buildReporteCard(reporte),
                          firstPageErrorIndicatorBuilder:
                              (_) => Center(
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
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed:
                                          () => _pagingController.refresh(),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Intentar nuevamente'),
                                    ),
                                  ],
                                ),
                              ),
                          noItemsFoundIndicatorBuilder:
                              (_) => Center(
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
                                  ],
                                ),
                              ),
                          newPageProgressIndicatorBuilder:
                              (_) => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}