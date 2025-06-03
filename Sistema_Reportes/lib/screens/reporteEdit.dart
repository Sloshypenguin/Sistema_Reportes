import 'package:flutter/material.dart';
import '../models/reporteViewModel.dart';
import '../widgets/plantilla_widget.dart';
import '../layout/plantilla_base.dart';
import '../services/servicioService.dart';
import '../services/reporteService.dart';
import '../models/servicioViewModel.dart';
import 'google_maps.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class ReporteEdit extends StatefulWidget {
  final String titulo;
  
  const ReporteEdit({
    super.key,
    required this.titulo,
  });

  @override
  State<ReporteEdit> createState() => _ReporteEditState();
}

class _ReporteEditState extends State<ReporteEdit> with TickerProviderStateMixin {
  // Controladores de formulario
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _personaIdController = TextEditingController();
  
  // Servicios
  final ReporteService _reporteService = ReporteService();
  final ServicioService _servicioService = ServicioService();
  
  // Variables de estado
  bool _cargando = false;
  bool _guardando = false;
  Reporte? _reporteAEditar;
  List<Servicio> _servicios = [];
  
  // Variables del formulario
  int? _servicioSeleccionado;
  bool _esPrioritario = false;
  String _estadoSeleccionado = 'P';
  
  // Variables para Google Maps
  GoogleMapController? _mapController;
  LatLng? _ubicacionActual;
  Set<Marker> _markers = {};
  bool _ubicacionValida = false;
  String? _errorUbicacion;
  String? _direccionLegible; // Nueva variable para mostrar dirección legible
  
  // Animaciones
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  // Opciones de estado con colores
  final List<Map<String, dynamic>> _opcionesEstado = [
    {'value': 'A', 'label': 'Activo', 'color': Colors.green, 'icon': Icons.play_circle_filled},
    {'value': 'P', 'label': 'Pendiente', 'color': Colors.orange, 'icon': Icons.access_time},
    {'value': 'C', 'label': 'Completado', 'color': Colors.blue, 'icon': Icons.check_circle},
    {'value': 'X', 'label': 'Cancelado', 'color': Colors.red, 'icon': Icons.cancel},
    {'value': 'G', 'label': 'Gestión', 'color': Colors.purple, 'icon': Icons.settings},
  ];

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _cargarDatos();
    _fadeAnimationController.forward();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reporteAEditar == null) {
      _reporteAEditar = ModalRoute.of(context)?.settings.arguments as Reporte?;
      if (_reporteAEditar != null) {
        _llenarFormulario();
      }
    }
  }
  
  void _llenarFormulario() {
    if (_reporteAEditar != null) {
      _descripcionController.text = _reporteAEditar!.repo_Descripcion;
      _ubicacionController.text = _reporteAEditar!.repo_Ubicacion ?? '';
      _servicioSeleccionado = _reporteAEditar!.serv_Id;
      _esPrioritario = _reporteAEditar!.repo_Prioridad;
      _estadoSeleccionado = _reporteAEditar!.repo_Estado;
      _personaIdController.text = _reporteAEditar!.pers_Id.toString();
      
      _procesarUbicacion(_reporteAEditar!.repo_Ubicacion ?? '');
    }
  }

  void _procesarUbicacion(String ubicacion) {
    if (ubicacion.isEmpty) {
      setState(() {
        _ubicacionValida = false;
        _errorUbicacion = null;
        _ubicacionActual = null;
        _markers.clear();
        _direccionLegible = null;
      });
      return;
    }

    try {
      final RegExp coordRegex = RegExp(r'\[Lat:\s*(-?\d+\.?\d*),\s*Lng:\s*(-?\d+\.?\d*)\]');
      final match = coordRegex.firstMatch(ubicacion);
      
      if (match != null) {
        final double lat = double.parse(match.group(1)!);
        final double lng = double.parse(match.group(2)!);
        
        if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          setState(() {
            _ubicacionActual = LatLng(lat, lng);
            _ubicacionValida = true;
            _errorUbicacion = null;
            _actualizarMarcador();
          });
          _obtenerDireccionLegible(lat, lng);
        } else {
          setState(() {
            _ubicacionValida = false;
            _errorUbicacion = 'Coordenadas fuera de rango válido';
            _ubicacionActual = null;
            _markers.clear();
            _direccionLegible = null;
          });
        }
      } else {
        setState(() {
          _ubicacionValida = false;
          _errorUbicacion = 'Formato de ubicación no válido';
          _ubicacionActual = null;
          _markers.clear();
          _direccionLegible = null;
        });
      }
    } catch (e) {
      setState(() {
        _ubicacionValida = false;
        _errorUbicacion = 'Error al procesar la ubicación: $e';
        _ubicacionActual = null;
        _markers.clear();
        _direccionLegible = null;
      });
    }
  }

  Future<void> _obtenerDireccionLegible(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String direccion = '';
        if (place.street != null && place.street!.isNotEmpty) {
          direccion += place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          direccion += direccion.isEmpty ? place.locality! : ', ${place.locality!}';
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          direccion += direccion.isEmpty ? place.administrativeArea! : ', ${place.administrativeArea!}';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          direccion += direccion.isEmpty ? place.country! : ', ${place.country!}';
        }
        
        setState(() {
          _direccionLegible = direccion.isEmpty ? 'Ubicación seleccionada' : direccion;
        });
      }
    } catch (e) {
      setState(() {
        _direccionLegible = 'Ubicación seleccionada';
      });
    }
  }

  void _actualizarMarcador() {
    if (_ubicacionActual != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('ubicacion_reporte'),
            position: _ubicacionActual!,
            infoWindow: InfoWindow(
              title: 'Ubicación del Reporte',
              snippet: 'Lat: ${_ubicacionActual!.latitude.toStringAsFixed(6)}, Lng: ${_ubicacionActual!.longitude.toStringAsFixed(6)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _ubicacionActual!,
              zoom: 15.0,
            ),
          ),
        );
      }
    }
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _cargando = true;
      });
      
      _servicios = await _servicioService.listarServicios();
      
      setState(() {
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      _mostrarError('Error al cargar datos: $e');
      debugPrint('Error en _cargarDatos: $e');
    }
  }
  
  Future<void> _actualizarReporte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_reporteAEditar == null) {
      _mostrarError('No hay reporte para actualizar');
      return;
    }
    
    if (_servicioSeleccionado == null) {
      _mostrarError('Debe seleccionar un servicio');
      return;
    }
    
    try {
      setState(() {
        _guardando = true;
      });
      
      const int usuarioModificacion = 1;
      
      final resultado = await _reporteService.actualizarReporte(
        reporteId: _reporteAEditar!.repo_Id,
        servicioId: _servicioSeleccionado!,
        descripcion: _descripcionController.text.trim(),
        ubicacion: _ubicacionController.text.trim(),
        esPrioritario: _esPrioritario,
        estado: _estadoSeleccionado,
        personaId: int.tryParse(_personaIdController.text.trim()) ?? 0,
        usuarioModificacion: usuarioModificacion,
      );
      
      setState(() {
        _guardando = false;
      });
      
      if (resultado['success'] == true) {
        _mostrarExito(resultado['message'] ?? 'Reporte actualizado correctamente');
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        _mostrarError(resultado['message'] ?? 'Error al actualizar el reporte');
      }
      
    } catch (e) {
      setState(() {
        _guardando = false;
      });
      _mostrarError('Error al actualizar reporte: $e');
      debugPrint('Error en _actualizarReporte: $e');
    }
  }
  
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    final opcion = _opcionesEstado.firstWhere(
      (o) => o['value'] == estado,
      orElse: () => _opcionesEstado[0],
    );
    return opcion['color'];
  }

  IconData _getEstadoIcon(String estado) {
    final opcion = _opcionesEstado.firstWhere(
      (o) => o['value'] == estado,
      orElse: () => _opcionesEstado[0],
    );
    return opcion['icon'];
  }
  
  @override
  Widget build(BuildContext context) {
    if (_cargando || _reporteAEditar == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando datos...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Contenido principal
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header con información del reporte
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.edit_document, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Editando Reporte',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'ID: ${_reporteAEditar!.repo_Id}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person, color: Colors.white70, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Creado por: ${_reporteAEditar!.persona}',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, color: Colors.white70, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Fecha: ${_reporteAEditar!.repo_FechaCreacion}',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Dropdown de servicios
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _servicioSeleccionado,
                            decoration: InputDecoration(
                              labelText: 'Servicio',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.build, color: Theme.of(context).primaryColor),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            items: _servicios.map((servicio) {
                              return DropdownMenuItem<int>(
                                value: servicio.serv_Id,
                                child: Text(servicio.serv_Nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _servicioSeleccionado = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Debe seleccionar un servicio';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Campo de descripción
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _descripcionController,
                            decoration: InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.description, color: Theme.of(context).primaryColor),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La descripción es obligatoria';
                              }
                              if (value.trim().length < 10) {
                                return 'La descripción debe tener al menos 10 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Campo de ubicación mejorado
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _ubicacionController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Ubicación',
                              hintText: _direccionLegible ?? 'Toca el mapa para seleccionar ubicación',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _ubicacionValida 
                                    ? Colors.green.withOpacity(0.1)
                                    : Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _ubicacionValida ? Icons.location_on : Icons.location_off,
                                  color: _ubicacionValida ? Colors.green : Theme.of(context).primaryColor,
                                ),
                              ),
                              suffixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.map, color: Colors.white),
                                  tooltip: 'Seleccionar en mapa',
                                  onPressed: () async {
                                    final resultado = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const GoogleMapsScreen(seleccionarUbicacion: true),
                                      ),
                                    );

                                    if (resultado != null && resultado is Map<String, dynamic>) {
                                      final direccion = resultado['direccion'] as String;
                                      final latitud = resultado['latitud'] as double;
                                      final longitud = resultado['longitud'] as double;
                                      
                                      setState(() {
                                        _ubicacionController.text = '$latitud,$longitud';
                                        _direccionLegible = direccion;
                                        _ubicacionActual = LatLng(latitud, longitud);
                                        _ubicacionValida = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Debe seleccionar una ubicación';
                              }
                              return null;
                            },
                          ),
                        ),

                        // Mostrar dirección legible si existe
                        if (_direccionLegible != null && _ubicacionValida) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _direccionLegible!,
                                    style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Mostrar error de ubicación si existe
                        if (_errorUbicacion != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorUbicacion!,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Mapa de vista previa mejorado
                        if (_ubicacionActual != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.map, color: Colors.green, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Vista Previa de Ubicación',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                            Text(
                                              'Lat: ${_ubicacionActual!.latitude.toStringAsFixed(6)}, Lng: ${_ubicacionActual!.longitude.toStringAsFixed(6)}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 180,
                                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GoogleMap(
                                      onMapCreated: (GoogleMapController controller) {
                                        _mapController = controller;
                                        Future.delayed(const Duration(milliseconds: 500), () {
                                          _actualizarMarcador();
                                        });
                                      },
                                      initialCameraPosition: CameraPosition(
                                        target: _ubicacionActual!,
                                        zoom: 15.0,
                                      ),
                                      markers: _markers,
                                      zoomControlsEnabled: false,
                                      myLocationButtonEnabled: false,
                                      mapToolbarEnabled: false,
                                      scrollGesturesEnabled: false,
                                      zoomGesturesEnabled: false,
                                      rotateGesturesEnabled: false,
                                      tiltGesturesEnabled: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Dropdown de estado mejorado
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _estadoSeleccionado,
                            decoration: InputDecoration(
                              labelText: 'Estado',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(_estadoSeleccionado).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_getEstadoIcon(_estadoSeleccionado), color: _getEstadoColor(_estadoSeleccionado)),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            items: _opcionesEstado.map((opcion) {
                              return DropdownMenuItem<String>(
                                value: opcion['value'],
                                child: Row(
                                  children: [
                                    Icon(opcion['icon'], color: opcion['color'], size: 20),
                                    const SizedBox(width: 8),
                                    Text(opcion['label']!),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _estadoSeleccionado = value!;
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Switch de prioridad mejorado
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Reporte Prioritario',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _esPrioritario ? Colors.red.shade700 : Colors.grey.shade700,
                              ),
                            ),
                            subtitle: Text(
                              _esPrioritario 
                                ? 'Este reporte requiere atención inmediata'
                                : 'Marcar si requiere atención inmediata',
                              style: TextStyle(
                                color: _esPrioritario ? Colors.red.shade600 : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            value: _esPrioritario,
                            onChanged: (value) {
                              setState(() {
                                _esPrioritario = value;
                              });
                            },
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (_esPrioritario ? Colors.red : Colors.grey).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _esPrioritario ? Icons.priority_high : Icons.low_priority,
                                color: _esPrioritario ? Colors.red : Colors.grey.shade600,
                              ),
                            ),
                            activeColor: Colors.red,
                            contentPadding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        
                        // Espacio adicional para evitar que los botones se oculten
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Botones de acción fijos en la parte inferior
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: _guardando ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: _guardando 
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
                          ),
                          boxShadow: _guardando ? [] : [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _guardando ? null : _actualizarReporte,
                          icon: _guardando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save, size: 20, color: Colors.white),
                          label: Text(
                            _guardando ? 'Guardando...' : 'Guardar Cambios',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _personaIdController.dispose();
    _mapController?.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }
}