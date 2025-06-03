import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/reporteService.dart';
import '../models/reporteViewModel.dart';
import 'editar_perfil.dart';
import '../config/api_config.dart';
import '../layout/plantilla_base.dart';
import 'observaciones_screen.dart';

class MiPerfil extends StatefulWidget {
  final String titulo;
  final bool mostrarBotonRegresar;

  const MiPerfil({
    super.key,
    required this.titulo,
    this.mostrarBotonRegresar = false,
  });

  @override
  State<MiPerfil> createState() => _MiPerfilState();
}

class _MiPerfilState extends State<MiPerfil> {
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

  String nombreUsuario = 'Usuario';
  String rolUsuario = 'Rol';
  String? imagenPerfil;
  String correoUsuario = '';
  int _usuarioId = 0; // ID del usuario logueado (necesario para cargar datos)
  int _persId =
      0; // ID de la persona asociada al usuario (necesario para cargar reportes)

  // Para los reportes
  final ReporteService _reporteService = ReporteService();
  List<Reporte> _reportesUsuario = [];
  bool _cargandoReportes = true;

  /// Carga los reportes asociados al usuario logueado
  Future<void> _cargarReportesUsuario(int persId) async {
    // Verificar si el widget está montado antes de actualizar el estado
    if (!mounted) return;

    try {
      setState(() {
        _cargandoReportes = true;
      });

      // Obtener los reportes del usuario
      final reportes = await _reporteService.listarReportesPorPersona(persId);

      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;

      setState(() {
        _reportesUsuario = reportes;
        _cargandoReportes = false;
      });
    } catch (e) {
      debugPrint('Error al cargar reportes del usuario: $e');

      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;

      setState(() {
        _cargandoReportes = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final nombre = await AuthService.obtenerNombreUsuario() ?? 'Usuario';
    final rol = await AuthService.obtenerRol() ?? 'Rol';
    final imagen = await AuthService.obtenerImagenPerfil();
    final correo = await AuthService.obtenerCorreoUsuario() ?? '';
    final usuarioId = await AuthService.obtenerUsuarioId();
    final persId = await AuthService.obtenerPersonaId();

    setState(() {
      nombreUsuario = nombre;
      rolUsuario = rol;
      imagenPerfil = imagen;
      correoUsuario = correo;
      _usuarioId = usuarioId != null ? int.parse(usuarioId.toString()) : 0;
      _persId = persId != null ? int.parse(persId.toString()) : 0;

      if (imagenPerfil != null) {
        debugPrint('Imagen de perfil cargada en mi_perfil: $imagenPerfil');
      }
    });

    // Cargar los reportes del usuario una vez que tengamos su ID de persona
    if (_persId > 0) {
      _cargarReportesUsuario(_persId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Portada con imagen de perfil encimada
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/TimelineCovers.pro_ultra-hd-space-facebook-cover.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -50, // sobresale hacia abajo
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    // Mostrar imagen de perfil si está disponible, de lo contrario mostrar una imagen predeterminada
                    backgroundImage:
                        imagenPerfil != null
                            ? NetworkImage(
                              'http://siresp.somee.com${imagenPerfil}',
                            )
                            : const AssetImage(
                                  'assets/images/logoAcademiaSL.png',
                                )
                                as ImageProvider,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60), // espacio extra por el overlap
          // Nombre y usuario con botón de edición
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nombreUsuario,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.blue),
                tooltip: 'Editar perfil',
                onPressed: () {
                  // Navegar a la pantalla de edición de perfil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditarPerfilScreen(),
                    ),
                  ).then((_) {
                    // Recargar datos cuando regrese de la pantalla de edición
                    _cargarDatosUsuario();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('@$nombreUsuario', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),

          // Info adicional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text('Rol: $rolUsuario'),
                Text('Correo: $correoUsuario'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    _cargandoReportes ? '...' : '${_reportesUsuario.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text('Reportes'),
                ],
              ),
              Column(
                children: [
                  Text(
                    _cargandoReportes
                        ? '...'
                        : '${_reportesUsuario.where((r) => r.repo_Prioridad).length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text('Prioritarios'),
                ],
              ),
              Column(
                children: [
                  Text(
                    _cargandoReportes
                        ? '...'
                        : '${_reportesUsuario.where((r) => !r.repo_Prioridad).length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text('No Prioritarios'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón para ver los reportes del usuario en una página separada
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PlantillaBase(
                          titulo: 'Mis Reportes',
                          mostrarBotonRegresar: true,
                          child: _MisReportesScreen(
                            nombreUsuario: nombreUsuario,
                            imagenPerfil: imagenPerfil,
                            persId: _persId,
                          ),
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
                  Icons.list_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(
                'Ver Mis Reportes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              subtitle: Text(
                _cargandoReportes
                    ? 'Cargando reportes...'
                    : _reportesUsuario.isEmpty
                    ? 'No tienes reportes publicados'
                    : '${_reportesUsuario.length} reportes',
                style: TextStyle(fontSize: 12),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Pantalla separada para mostrar los reportes del usuario
class _MisReportesScreen extends StatefulWidget {
  final String nombreUsuario;
  final String? imagenPerfil;
  final int persId;

  const _MisReportesScreen({
    required this.nombreUsuario,
    required this.imagenPerfil,
    required this.persId,
  });

  @override
  State<_MisReportesScreen> createState() => _MisReportesScreenState();
}

class _MisReportesScreenState extends State<_MisReportesScreen> {
  final ReporteService _reporteService = ReporteService();
  List<Reporte> _reportesUsuario = [];
  bool _cargandoReportes = true;
  Map<int, List<Map<String, dynamic>>> _imagenesPorReporte = {};

  @override
  void initState() {
    super.initState();
    _cargarReportesUsuario();
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

  /// Carga los reportes asociados al usuario logueado
  Future<void> _cargarReportesUsuario() async {
    if (!mounted) return;

    try {
      setState(() {
        _cargandoReportes = true;
      });

      // Obtener los reportes del usuario
      final reportes = await _reporteService.listarReportesPorPersona(
        widget.persId,
      );

      // Para cada reporte, obtener sus imágenes
      final imagenesMap = <int, List<Map<String, dynamic>>>{};
      for (final reporte in reportes) {
        if (!mounted) return;
        final imagenes = await _reporteService.obtenerImagenesPorReporte(
          reporte.repo_Id,
        );
        imagenesMap[reporte.repo_Id] = imagenes;
      }

      if (!mounted) return;

      setState(() {
        _reportesUsuario = reportes;
        _imagenesPorReporte = imagenesMap;
        _cargandoReportes = false;
      });
    } catch (e) {
      debugPrint('Error al cargar reportes del usuario: $e');

      if (!mounted) return;

      setState(() {
        _cargandoReportes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Encabezado con información del usuario
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      widget.imagenPerfil != null
                          ? NetworkImage(
                            '${ApiConfig.baseUrl}${widget.imagenPerfil}',
                          )
                          : const AssetImage('assets/images/logoAcademiaSL.png')
                              as ImageProvider,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombreUsuario,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mis reportes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Lista de reportes
          _cargandoReportes
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
              : _reportesUsuario.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.blue.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes reportes publicados',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reportesUsuario.length,
                itemBuilder: (context, index) {
                  final reporte = _reportesUsuario[index];
                  final imagenes = _imagenesPorReporte[reporte.repo_Id] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información del reporte
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    widget.imagenPerfil != null
                                        ? NetworkImage(
                                          '${ApiConfig.baseUrl}${widget.imagenPerfil}',
                                        )
                                        : const AssetImage(
                                              'assets/images/logoAcademiaSL.png',
                                            )
                                            as ImageProvider,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.nombreUsuario,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Servicio: ${reporte.serv_Nombre}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      reporte.repo_Prioridad
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  reporte.repo_Prioridad
                                      ? 'Prioritario'
                                      : 'No Prioritario',
                                  style: TextStyle(
                                    color:
                                        reporte.repo_Prioridad
                                            ? Colors.red.shade900
                                            : Colors.green.shade900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Descripción del reporte
                          Text(
                            reporte.repo_Descripcion,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          // Imágenes del reporte
                          if (imagenes.isNotEmpty)
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: imagenes.length,
                                itemBuilder: (context, imgIndex) {
                                  final imagen = imagenes[imgIndex];
                                  final imagenUrl = imagen['imre_Imagen'];

                                  return Container(
                                    width: 180,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          '${ApiConfig.baseUrl}$imagenUrl',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/TimelineCovers.pro_ultra-hd-space-facebook-cover.jpg',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Estado y fecha
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  reporte.repo_Estado == 'P'
                                      ? 'Pendiente'
                                      : reporte.repo_Estado == 'A'
                                      ? 'Aprobado'
                                      : reporte.repo_Estado == 'R'
                                      ? 'Rechazado'
                                      : 'Desconocido',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Fecha: ${_formatearFecha(reporte.repo_FechaCreacion)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          // Botón para ver observaciones en página separada
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade50,
                                  Colors.grey.shade100,
                                ],
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
                            child: ListTile(
                              onTap: () {
                                // Usando una pantalla separada para mostrar las observaciones
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PlantillaBase(
                                          titulo: 'Observaciones del Reporte',
                                          mostrarBotonRegresar: true,
                                          child: ObservacionesScreen(
                                            reporte: reporte,
                                          ),
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
