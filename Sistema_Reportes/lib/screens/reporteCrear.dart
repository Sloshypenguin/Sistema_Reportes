import 'package:flutter/material.dart';
import 'package:sistema_reportes/services/auth_service.dart';
import '../services/reporteService.dart';
import 'google_maps.dart';
import '../models/servicioViewModel.dart';
import '../services/servicioService.dart';

class reporteCrear extends StatefulWidget {
  final String titulo;

  const reporteCrear({super.key, required this.titulo});

  @override
  State<reporteCrear> createState() => _reporteCrearState();
}

class _reporteCrearState extends State<reporteCrear>
    with TickerProviderStateMixin {
  // Controllers para los campos del formulario
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _personaIdController = TextEditingController();
  final TextEditingController _servicioIdController = TextEditingController();

  // Variables para almacenar las coordenadas de la ubicación seleccionada
  double? _latitud;
  double? _longitud;

  // Variables para el dropdown de servicios
  List<Servicio> _servicios = [];
  Servicio? _servicioSeleccionado;

  // Variables de estado
  bool _cargando = false;
  bool _guardando = false;
  bool _prioridad = false;
  bool _redirigiendo = false;
  bool _cargandoServicios = false;

  // Valores fijos temporales
  final int _usuaCreacion = 1; // Usuario fijo por ahora

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Cargar datos después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _cargando = true;
        _cargandoServicios = true;
      });

      // Cargar servicios desde la API
      final servicioService = ServicioService();
      final servicios = await servicioService.listarServiciosActivos();

      print('=== DEBUG CARGAR SERVICIOS ===');
      print('Servicios cargados: ${servicios.length}');
      for (var servicio in servicios) {
        print('ID: ${servicio.serv_Id}, Nombre: ${servicio.serv_Nombre}');
      }
      print('==============================');

      setState(() {
        _servicios = servicios;
        _cargandoServicios = false;
        _cargando = false;
      });

      // Si no hay servicios, mostrar mensaje
      if (servicios.isEmpty) {
        _mostrarError('No hay servicios disponibles');
      }
    } catch (e) {
      setState(() {
        _cargando = false;
        _cargandoServicios = false;
        _servicios = []; // Asegurar que la lista esté vacía en caso de error
      });
      print('Error al cargar servicios: $e');
      _mostrarError('Error al cargar servicios: $e');
    }
  }

  Future<void> _guardarReporte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que se haya seleccionado una ubicación
    if (_ubicacionController.text.isEmpty) {
      _mostrarError('Por favor selecciona una ubicación en el mapa');
      return;
    }

    try {
      setState(() {
        _guardando = true;
      });

      // Crear instancia del servicio
      final reporteService = ReporteService();
      final personaId = await AuthService.obtenerPersonaId();

      // Preparar información de ubicación
      String ubicacionInfo = _ubicacionController.text.trim();

      // Si tenemos coordenadas, añadirlas a la información de ubicación
      if (_latitud != null && _longitud != null) {
        ubicacionInfo += ' [Lat: $_latitud, Lng: $_longitud]';
      }

      // Llamar al método real del servicio
      final resultado = await reporteService.crearReporte(
        personaId: int.tryParse(personaId ?? "") ?? 0,
        servicioId: _servicioSeleccionado?.serv_Id ?? 0,
        descripcion: _descripcionController.text.trim(),
        ubicacion: ubicacionInfo,
        esPrioritario: _prioridad,
        usuarioCreacion: _usuaCreacion,
      );

      setState(() {
        _guardando = false;
      });

      // Verificar si fue exitoso
      if (resultado['success'] == true) {
        _mostrarExito(
          'Reporte creado exitosamente. ID: ${resultado['reporteId']}',
        );
        _limpiarFormulario();

        // Mostrar estado de redirección
        setState(() {
          _redirigiendo = true;
        });

        // Redirigir a la lista de reportes después de un breve delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/principal');
        });
      } else {
        _mostrarError('Error: ${resultado['message']}');
      }
    } catch (e) {
      setState(() {
        _guardando = false;
      });

      // Manejo de errores más específico
      String mensajeError = 'Error desconocido';

      if (e.toString().contains('Sin conexión a internet')) {
        mensajeError = 'Sin conexión a internet. Verifica tu conexión.';
      } else if (e.toString().contains('Error al crear reporte')) {
        mensajeError = 'Error del servidor al crear el reporte.';
      } else {
        mensajeError = 'Error: ${e.toString()}';
      }

      _mostrarError(mensajeError);
      debugPrint('Error completo en _guardarReporte: $e');
    }
  }

  void _limpiarFormulario() {
    _descripcionController.clear();
    _ubicacionController.clear();
    _personaIdController.clear();
    _servicioIdController.clear();
    setState(() {
      _prioridad = false;
      _servicioSeleccionado = null;
    });
  }

  Future<void> _refrescarServicios() async {
    await _cargarDatos();
  }

  void _debugServicios() {
    print('=== DEBUG ESTADO SERVICIOS ===');
    print('_cargandoServicios: $_cargandoServicios');
    print('_servicios.length: ${_servicios.length}');
    print(
      '_servicioSeleccionado: ${_servicioSeleccionado?.serv_Nombre ?? 'null'}',
    );
    if (_servicios.isNotEmpty) {
      print('Primer servicio: ${_servicios.first.serv_Nombre}');
    }
    print('==============================');
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
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDropdownServicios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Servicio'),
        const SizedBox(height: 10),

        // Mostrar indicador de carga o dropdown
        _cargandoServicios
            ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Cargando servicios...'),
                ],
              ),
            )
            : DropdownButtonFormField<Servicio>(
              value: _servicioSeleccionado,
              decoration: InputDecoration(
                hintText:
                    _servicios.isEmpty
                        ? 'No hay servicios disponibles'
                        : 'Selecciona un servicio',
                prefixIcon: const Icon(Icons.build, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items:
                  _servicios.isEmpty
                      ? null
                      : _servicios
                          .map(
                            (servicio) => DropdownMenuItem<Servicio>(
                              value: servicio,
                              child: Text(
                                servicio.serv_Nombre,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
              onChanged:
                  _servicios.isEmpty
                      ? null
                      : (Servicio? servicio) {
                        setState(() {
                          _servicioSeleccionado = servicio;
                        });
                        print(
                          'Servicio seleccionado: ${servicio?.serv_Nombre} (ID: ${servicio?.serv_Id})',
                        );
                      },
              validator: (value) {
                if (value == null) {
                  return 'Debes seleccionar un servicio';
                }
                return null;
              },
              isExpanded: true,
            ),
      ],
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _personaIdController.dispose();
    _servicioIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cargando datos...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[700]!, Colors.blue[500]!],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta de información
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_add,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nuevo Reporte',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Completa la información requerida',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Formulario
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Campo Servicio - DROPDOWN CORREGIDO
                        _buildDropdownServicios(),

                        const SizedBox(height: 20),

                        // Campo Descripción
                        _buildSectionTitle('Descripción'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descripcionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Describe detalladamente el problema o situación...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(
                                Icons.description,
                                color: Colors.green,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
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

                        const SizedBox(height: 20),

                        // Campo Ubicación
                        Row(
                          children: [
                            Expanded(child: _buildSectionTitle('Ubicación')),
                            InkWell(
                              onTap: () async {
                                // Navegar a la pantalla de Google Maps en modo selección
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const GoogleMapsScreen(
                                          seleccionarUbicacion: true,
                                        ),
                                  ),
                                );

                                // Si se seleccionó una ubicación, actualizar el campo
                                if (resultado != null &&
                                    resultado is Map<String, dynamic>) {
                                  setState(() {
                                    // Guardar las coordenadas para usarlas al enviar el reporte
                                    _latitud = resultado['latitud'];
                                    _longitud = resultado['longitud'];

                                    // Mostrar la dirección en el campo de texto
                                    _ubicacionController.text =
                                        resultado['direccion'];
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.map,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Seleccionar en mapa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _ubicacionController,
                          readOnly:
                              true, // Hacerlo de solo lectura para que se seleccione desde el mapa
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor selecciona una ubicación';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Selecciona la ubicación del problema...',
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.map, color: Colors.blue),
                              onPressed: () async {
                                // Navegar a la pantalla de Google Maps en modo selección
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const GoogleMapsScreen(
                                          seleccionarUbicacion: true,
                                        ),
                                  ),
                                );

                                // Si se seleccionó una ubicación, actualizar el campo
                                if (resultado != null &&
                                    resultado is Map<String, dynamic>) {
                                  setState(() {
                                    // Guardar las coordenadas para usarlas al enviar el reporte
                                    _latitud = resultado['latitud'];
                                    _longitud = resultado['longitud'];

                                    // Mostrar la dirección en el campo de texto
                                    _ubicacionController.text =
                                        resultado['direccion'];
                                  });
                                }
                              },
                              tooltip: 'Seleccionar en el mapa',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onTap: () async {
                            // Al tocar el campo, abrir el mapa
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const GoogleMapsScreen(
                                      seleccionarUbicacion: true,
                                    ),
                              ),
                            );

                            // Si se seleccionó una ubicación, actualizar el campo
                            if (resultado != null &&
                                resultado is Map<String, dynamic>) {
                              setState(() {
                                // Guardar las coordenadas para usarlas al enviar el reporte
                                _latitud = resultado['latitud'];
                                _longitud = resultado['longitud'];

                                // Mostrar la dirección en el campo de texto
                                _ubicacionController.text =
                                    resultado['direccion'];
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        // Switch de Prioridad
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.priority_high,
                                color: Colors.orange[600],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Marcar como prioritario',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Los reportes prioritarios tienen atención inmediata',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _prioridad,
                                onChanged: (value) {
                                  setState(() {
                                    _prioridad = value;
                                  });
                                },
                                activeColor: Colors.orange[600],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Botones de acción
                        Row(
                          children: [
                            // Botón Cancelar
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _guardando
                                        ? null
                                        : () {
                                          Navigator.pop(context);
                                        },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 15),

                            // Botón Guardar
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed:
                                    (_guardando || _redirigiendo)
                                        ? null
                                        : _guardarReporte,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                child:
                                    _guardando
                                        ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Guardando...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                        : _redirigiendo
                                        ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Redirigiendo...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                        : const Text(
                                          'Crear Reporte',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
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
      ),
    );
  }
}
