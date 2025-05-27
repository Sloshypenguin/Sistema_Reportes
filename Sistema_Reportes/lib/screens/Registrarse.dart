import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../services/usuarioService.dart';
import '../services/estadoCivilService.dart';
import '../services/departamentoService.dart';
import '../services/municipioService.dart';
import '../services/connectivityService.dart';
import '../models/estadoCivilViewModel.dart';
import '../models/departamentoViewModel.dart';
import '../models/municipioViewModel.dart';
import '../screens/login.dart';

// Claves para SharedPreferences
const String kEstadosCivilesKey = 'estados_civiles_cache';
const String kDepartamentosKey = 'departamentos_cache';
const String kCacheExpiryKey = 'cache_expiry_timestamp';
const String kMunicipiosPrefixKey = 'municipios_';

// Tiempo de expiración de la caché (24 horas en milisegundos)
const int kCacheExpiryDuration = 24 * 60 * 60 * 1000; // 24 horas

class RegistrarseScreen extends StatefulWidget {
  const RegistrarseScreen({super.key});

  @override
  State<RegistrarseScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistrarseScreen> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final UsuarioService _usuarioService = UsuarioService();
  final EstadoCivilService _estadoCivilService = EstadoCivilService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final DepartamentoService _departamentoService = DepartamentoService();
  final MunicipioService _municipioService = MunicipioService();

  List<Departamento> _departamentos = [];
  int? _departamentoSeleccionado;
  bool _cargandoDepartamentos = true;

  List<Municipio> _municipios = [];
  String? _municipioSeleccionado;
  bool _cargandoMunicipios = false;

  // Para manejar la suscripción a cambios de conectividad
  late Stream<ConnectivityResult> _connectivityStream;

  // Controladores para campos de usuario
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();

  // Controladores para campos de persona
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();

  // Variables de estado
  bool _cargando = false;
  String _sexoSeleccionado = 'M';
  int? _estadoCivilSeleccionado;
  bool _cargandoEstadosCiviles = true;

  // Opciones para sexo (ahora como radio buttons)
  final List<Map<String, dynamic>> _opcionesSexo = [
    {'valor': 'M', 'texto': 'M'},
    {'valor': 'F', 'texto': 'F'},
  ];

  // Lista para almacenar los estados civiles cargados desde la API
  List<EstadoCivil> _estadosCiviles = [];

  // Estado del formulario por pasos
  int _pasoActual = 0;
  final int _totalPasos = 3;

  List<String> _titulosPasos = [
    'Datos Personales',
    'Dirección y Ubicación',
    'Datos de Usuario',
  ];

  List<String> _descripcionesPasos = [
    'Ingresa tus datos personales.',
    'Proporciona tu dirección y código de municipio.',
    'Elige un nombre de usuario y contraseña.',
  ];

  @override
  void initState() {
    super.initState();
    _pasoActual = 0;
    _cargarEstadosCiviles();
    _cargarDepartamentos();

    // Configurar la escucha de cambios en la conectividad
    _connectivityStream = _connectivityService.onConnectivityChanged;
    _connectivityStream.listen(_handleConnectivityChange);
  }

  /// Maneja los cambios en la conectividad
  void _handleConnectivityChange(ConnectivityResult result) async {
    // Si hay alguna conexión y no tenemos estados civiles cargados
    // intentamos cargar los datos nuevamente
    if (result != ConnectivityResult.none && _estadosCiviles.isEmpty) {
      // Esperamos un momento para asegurarnos de que la conexión sea estable
      await Future.delayed(const Duration(seconds: 1));
      // Verificamos si realmente hay conexión a internet
      final hasConnection = await _connectivityService.hasConnection();
      if (hasConnection) {
        // Mostrar notificación de carga con barra de progreso
        _mostrarCargando('Reconectando...');

        // Cargar los estados civiles
        _cargarEstadosCiviles().then((_) {
          // Si la carga fue exitosa, mostrar una notificación de éxito
          if (_estadosCiviles.isNotEmpty && mounted) {
            _mostrarExito('Conexión restablecida exitosamente');
          }
        });
      }
    }
  }

  /// Carga los estados civiles desde la caché local o API
  Future<void> _cargarEstadosCiviles() async {
    setState(() {
      _cargandoEstadosCiviles = true;
    });

    // Intentar cargar desde la caché primero
    final estadosCivilesCached = await _cargarEstadosCivilesDesdeCache();
    if (estadosCivilesCached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _estadosCiviles = estadosCivilesCached;
          _estadoCivilSeleccionado =
              null; // No seleccionamos ninguno por defecto
          _cargandoEstadosCiviles = false;
        });
        debugPrint(
          'Estados civiles cargados desde caché: ${estadosCivilesCached.length}',
        );
      }
      return;
    }

    // Verificamos si hay conexión a internet para cargar desde la API
    final hasConnection = await _connectivityService.hasConnection();

    if (!hasConnection) {
      setState(() {
        _cargandoEstadosCiviles = false;
      });

      // Mostrar notificación de error amigable
      _mostrarError(
        'No hay conexión a internet. Por favor verifique su conexión e intente nuevamente.',
      );
      return;
    }

    try {
      // Cargar desde la API
      final estadosCiviles = await _estadoCivilService.listar();

      // Guardar en caché para uso futuro
      await _guardarEstadosCivilesEnCache(estadosCiviles);

      // Verificamos si el widget todavía está montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _estadosCiviles = estadosCiviles;
          _estadoCivilSeleccionado = null;
          _cargandoEstadosCiviles = false;
        });
        debugPrint(
          'Estados civiles cargados desde API: ${estadosCiviles.length}',
        );
      }
    } catch (e) {
      // Verificamos si el widget todavía está montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _cargandoEstadosCiviles = false;
        });

        // Mostrar notificación de error amigable
        _mostrarError(
          'No se pudieron cargar las opciones de estado civil. Por favor intente nuevamente.',
        );
        debugPrint('Error al cargar estados civiles: $e');
      }
    }
  }

  /// Carga los estados civiles desde la caché local
  Future<List<EstadoCivil>> _cargarEstadosCivilesDesdeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar si la caché existe y no ha expirado
      final cacheExpiry = prefs.getInt(kCacheExpiryKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime > cacheExpiry) {
        debugPrint('Caché expirada');
        return [];
      }

      final jsonString = prefs.getString(kEstadosCivilesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      // Decodificar JSON a lista de objetos
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<EstadoCivil> estadosCiviles =
          jsonList
              .map((json) => EstadoCivil.fromJson(json as Map<String, dynamic>))
              .toList();

      return estadosCiviles;
    } catch (e) {
      debugPrint('Error al cargar estados civiles desde caché: $e');
      return [];
    }
  }

  /// Guarda los estados civiles en la caché local
  Future<void> _guardarEstadosCivilesEnCache(
    List<EstadoCivil> estadosCiviles,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir lista a JSON
      final List<Map<String, dynamic>> jsonList =
          estadosCiviles.map((estadoCivil) => estadoCivil.toJson()).toList();
      final String jsonString = jsonEncode(jsonList);

      // Establecer tiempo de expiración (24 horas desde ahora)
      final int expiryTime =
          DateTime.now().millisecondsSinceEpoch + kCacheExpiryDuration;

      // Guardar en SharedPreferences
      await prefs.setString(kEstadosCivilesKey, jsonString);
      await prefs.setInt(kCacheExpiryKey, expiryTime);

      debugPrint(
        'Estados civiles guardados en caché: ${estadosCiviles.length}',
      );
    } catch (e) {
      debugPrint('Error al guardar estados civiles en caché: $e');
    }
  }

  /// Carga los departamentos desde la caché local o API
  Future<void> _cargarDepartamentos() async {
    setState(() {
      _cargandoDepartamentos = true;
    });

    // Intentar cargar desde la caché primero
    final departamentosCached = await _cargarDepartamentosDesdeCache();
    if (departamentosCached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _departamentos = departamentosCached;
          _departamentoSeleccionado = null;
          _cargandoDepartamentos = false;
        });
        debugPrint(
          'Departamentos cargados desde caché: ${departamentosCached.length}',
        );
      }
      return;
    }

    // Verificamos si hay conexión a internet para cargar desde la API
    final hasConnection = await _connectivityService.hasConnection();

    if (!hasConnection) {
      setState(() {
        _cargandoDepartamentos = false;
      });
      _mostrarError(
        'No hay conexión a internet para cargar departamentos. Intente nuevamente más tarde.',
      );
      return;
    }

    try {
      // Cargar desde la API
      final departamentos = await _departamentoService.listar();

      // Guardar en caché para uso futuro
      await _guardarDepartamentosEnCache(departamentos);

      if (mounted) {
        setState(() {
          _departamentos = departamentos;
          _departamentoSeleccionado = null;
          _cargandoDepartamentos = false;
        });
        debugPrint('Departamentos cargados desde API: ${departamentos.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDepartamentos = false;
        });
        _mostrarError(
          'No se pudieron cargar los departamentos. Por favor intente nuevamente.',
        );
        debugPrint('Error al cargar departamentos: $e');
      }
    }
  }

  /// Carga los departamentos desde la caché local
  Future<List<Departamento>> _cargarDepartamentosDesdeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar si la caché existe y no ha expirado
      final cacheExpiry = prefs.getInt(kCacheExpiryKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime > cacheExpiry) {
        debugPrint('Caché expirada para departamentos');
        return [];
      }

      final jsonString = prefs.getString(kDepartamentosKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      // Decodificar JSON a lista de objetos
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<Departamento> departamentos =
          jsonList
              .map(
                (json) => Departamento.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      return departamentos;
    } catch (e) {
      debugPrint('Error al cargar departamentos desde caché: $e');
      return [];
    }
  }

  /// Guarda los departamentos en la caché local
  Future<void> _guardarDepartamentosEnCache(
    List<Departamento> departamentos,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir lista a JSON
      final List<Map<String, dynamic>> jsonList =
          departamentos.map((departamento) => departamento.toJson()).toList();
      final String jsonString = jsonEncode(jsonList);

      // Establecer tiempo de expiración (24 horas desde ahora) si no existe ya
      final int expiryTime =
          prefs.getInt(kCacheExpiryKey) ??
          DateTime.now().millisecondsSinceEpoch + kCacheExpiryDuration;

      // Guardar en SharedPreferences
      await prefs.setString(kDepartamentosKey, jsonString);
      await prefs.setInt(kCacheExpiryKey, expiryTime);

      debugPrint('Departamentos guardados en caché: ${departamentos.length}');
    } catch (e) {
      debugPrint('Error al guardar departamentos en caché: $e');
    }
  }

  Future<void> _cargarMunicipiosPorDepartamento() async {
    if (_departamentoSeleccionado == null) return;

    final String departamentoCodigo = _departamentoSeleccionado!
        .toString()
        .padLeft(2, '0');

    setState(() {
      _cargandoMunicipios = true;
    });

    // Intentar cargar desde la caché primero
    final municipiosCached = await _cargarMunicipiosDesdeCache(
      departamentoCodigo,
    );
    if (municipiosCached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _municipios = municipiosCached;
          _municipioSeleccionado = null;
          _cargandoMunicipios = false;
        });
        debugPrint(
          'Municipios cargados desde caché: ${municipiosCached.length}',
        );
      }
      return;
    }

    // Verificar conexión a internet
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      setState(() {
        _cargandoMunicipios = false;
      });
      _mostrarError(
        'No hay conexión a internet para cargar municipios. Intente nuevamente más tarde.',
      );
      return;
    }

    try {
      // Cargar desde la API
      final municipios = await _municipioService.listarPorDepartamento(
        departamentoCodigo,
      );

      // Guardar en caché para uso futuro
      await _guardarMunicipiosEnCache(departamentoCodigo, municipios);

      if (mounted) {
        setState(() {
          _municipios = municipios;
          _municipioSeleccionado = null;
          _cargandoMunicipios = false;
        });
        debugPrint('Municipios cargados desde API: ${municipios.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoMunicipios = false;
        });
        _mostrarError(
          'No se pudieron cargar los municipios. Por favor intente nuevamente.',
        );
        debugPrint('Error al cargar municipios: $e');
      }
    }
  }

  /// Carga los municipios desde la caché local
  Future<List<Municipio>> _cargarMunicipiosDesdeCache(
    String departamentoCodigo,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar si la caché existe y no ha expirado
      final cacheExpiry = prefs.getInt(kCacheExpiryKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime > cacheExpiry) {
        debugPrint('Caché expirada para municipios');
        return [];
      }

      // Usamos una clave única para cada departamento
      final String municipioKey = '$kMunicipiosPrefixKey$departamentoCodigo';
      final jsonString = prefs.getString(municipioKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      // Decodificar JSON a lista de objetos
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<Municipio> municipios =
          jsonList
              .map((json) => Municipio.fromJson(json as Map<String, dynamic>))
              .toList();

      return municipios;
    } catch (e) {
      debugPrint('Error al cargar municipios desde caché: $e');
      return [];
    }
  }

  /// Guarda los municipios en la caché local
  Future<void> _guardarMunicipiosEnCache(
    String departamentoCodigo,
    List<Municipio> municipios,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir lista a JSON
      final List<Map<String, dynamic>> jsonList =
          municipios.map((municipio) => municipio.toJson()).toList();
      final String jsonString = jsonEncode(jsonList);

      // Establecer tiempo de expiración (24 horas desde ahora) si no existe ya
      final int expiryTime =
          prefs.getInt(kCacheExpiryKey) ??
          DateTime.now().millisecondsSinceEpoch + kCacheExpiryDuration;

      // Usamos una clave única para cada departamento
      final String municipioKey = '$kMunicipiosPrefixKey$departamentoCodigo';

      // Guardar en SharedPreferences
      await prefs.setString(municipioKey, jsonString);
      await prefs.setInt(kCacheExpiryKey, expiryTime);

      debugPrint('Municipios guardados en caché: ${municipios.length}');
    } catch (e) {
      debugPrint('Error al guardar municipios en caché: $e');
    }
  }

  // El método limpiarCache() ha sido movido a la pantalla principal
  // para ser llamado cuando el usuario cierra sesión

  // Referencia para la Flushbar actual
  Flushbar? _currentFlushbar;

  /// Muestra una notificación en la parte superior de la pantalla
  void _mostrarNotificacion({
    required String mensaje,
    required Color color,
    required IconData icono,
    bool mostrarProgreso = false,
    int duracionSegundos = 3,
  }) {
    // Evitar mostrar notificaciones si el widget no está montado
    if (!mounted) return;

    // Cerrar la notificación anterior de manera segura
    if (_currentFlushbar != null) {
      // Usar try-catch para evitar errores si la notificación ya está cerrada
      try {
        _currentFlushbar?.dismiss();
      } catch (e) {
        // Ignorar errores al cerrar la notificación
        print('Error al cerrar notificación: $e');
      }
      // Asegurar que la referencia se limpie
      _currentFlushbar = null;
    }

    // Crear y mostrar la nueva notificación
    _currentFlushbar = Flushbar(
      message: mensaje,
      icon: Icon(icono, size: 28.0, color: Colors.white),
      duration: Duration(seconds: duracionSegundos),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: color,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 2),
          blurRadius: 3,
        ),
      ],
      // Mostrar barra de progreso si es necesario
      showProgressIndicator: mostrarProgreso,
      progressIndicatorBackgroundColor: Colors.white.withOpacity(0.3),
      progressIndicatorValueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      // Manejar el evento de descarte para limpiar la referencia
      onStatusChanged: (status) {
        if (status == FlushbarStatus.DISMISSED) {
          _currentFlushbar = null;
        }
      },
    );

    // Mostrar la notificación de manera segura
    try {
      _currentFlushbar!.show(context);
    } catch (e) {
      print('Error al mostrar notificación: $e');
      _currentFlushbar = null;
    }
  }

  /// Muestra una notificación de error
  void _mostrarError(String mensaje) {
    _mostrarNotificacion(
      mensaje: mensaje,
      color: Colors.red.shade700,
      icono: Icons.error_outline,
      duracionSegundos: 4,
    );
  }

  /// Muestra una notificación de éxito
  void _mostrarExito(String mensaje) {
    _mostrarNotificacion(
      mensaje: mensaje,
      color: Colors.green.shade700,
      icono: Icons.check_circle_outline,
      duracionSegundos: 3,
    );
  }

  /// Muestra una notificación de carga con barra de progreso
  void _mostrarCargando(String mensaje) {
    _mostrarNotificacion(
      mensaje: mensaje,
      color: Colors.blue.shade700,
      icono: Icons.info_outline,
      mostrarProgreso: true,
      duracionSegundos: 30, // Tiempo largo por defecto, se cerrará manualmente
    );
  }

  @override
  void dispose() {
    // Liberar controladores
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    _dniController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _municipioController.dispose();

    // Cerrar cualquier notificación pendiente de manera segura
    if (_currentFlushbar != null) {
      try {
        _currentFlushbar?.dismiss();
      } catch (e) {
        print('Error al cerrar notificación en dispose: $e');
      }
      _currentFlushbar = null;
    }

    super.dispose();
  }

  /// Registra un nuevo usuario con los datos ingresados en el formulario
  ///
  /// Este método valida todos los campos del formulario, verifica la conexión a internet,
  /// y envía los datos al servidor. Muestra mensajes amigables en caso de error.
  Future<void> _registrarUsuario() async {
    // Validar el formulario completo
    if (!_formkey.currentState!.validate()) {
      _mostrarError(
        'Por favor complete todos los campos requeridos correctamente',
      );
      return;
    }

    // Verificar que las contraseñas coincidan
    if (_contrasenaController.text != _confirmarContrasenaController.text) {
      _mostrarError(
        'Las contraseñas no coinciden. Por favor verifique e intente nuevamente',
      );
      return;
    }

    // Verificar conectividad antes de realizar la solicitud
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      _mostrarError(
        'No hay conexión a internet. Por favor verifique su conexión e intente nuevamente',
      );
      return;
    }

    // Activar indicador de carga
    setState(() {
      _cargando = true;
    });

    // Verificamos que todos los datos obligatorios estén completos
    if (_estadoCivilSeleccionado == null || _estadoCivilSeleccionado == 0) {
      setState(() {
        _cargando = false;
      });
      _mostrarError('Por favor seleccione un estado civil válido');
      return;
    }

    if (_departamentoSeleccionado == null) {
      setState(() {
        _cargando = false;
      });
      _mostrarError('Por favor seleccione un departamento');
      return;
    }

    if (_municipioSeleccionado == null && _municipios.isNotEmpty) {
      setState(() {
        _cargando = false;
      });
      _mostrarError('Por favor seleccione un municipio');
      return;
    }

    // Mostrar notificación de carga con barra de progreso
    _mostrarCargando('Procesando su registro...');

    try {
      // Preparar datos para el registro
      final userData = {
        'usuario': _usuarioController.text.trim(),
        'contrasena': _contrasenaController.text,
        'usuaCreacion': 1,
        'dni': _dniController.text.trim(),
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'sexo': _sexoSeleccionado,
        'telefono': _telefonoController.text.trim(),
        'correo': _correoController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'municipioCodigo': _municipioSeleccionado ?? '',
        'estadoCivilId': _estadoCivilSeleccionado!,
      };

      // Realizar la solicitud de registro
      final resultado = await _usuarioService.registro(
        usuario: userData['usuario'] as String,
        contrasena: userData['contrasena'] as String,
        usuaCreacion: userData['usuaCreacion'] as int,
        dni: userData['dni'] as String,
        nombre: userData['nombre'] as String,
        apellido: userData['apellido'] as String,
        sexo: userData['sexo'] as String,
        telefono: userData['telefono'] as String,
        correo: userData['correo'] as String,
        direccion: userData['direccion'] as String,
        municipioCodigo: userData['municipioCodigo'] as String,
        estadoCivilId: userData['estadoCivilId'] as int,
      );

      // Cerrar cualquier notificación anterior de manera segura
      if (_currentFlushbar != null) {
        try {
          _currentFlushbar?.dismiss();
        } catch (e) {
          debugPrint('Error al cerrar notificación: $e');
        }
        _currentFlushbar = null;
      }

      // Obtener el código de estado y mensaje
      final codeStatus = resultado['code_Status'] ?? 0;
      final messageStatus = resultado['message_Status'] ?? 'Sin mensaje';

      // Manejar la respuesta según el código de estado
      // 1 = Éxito, -1 = Advertencia, 0 = Error
      if (codeStatus == 1) {
        // Éxito: Mostrar mensaje de éxito
        _mostrarExito('¡Registro completado exitosamente!');

        // Navegar al login después de un breve momento
        // Usamos Future.microtask para asegurar que la navegación
        // ocurra después de que se complete el frame actual
        Future.microtask(() {
          // Verificar que el widget siga montado antes de navegar
          if (!mounted) return;

          // Usar WidgetsBinding para asegurar que la navegación ocurra
          // después de que el primer frame sea renderizado
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  var begin = const Offset(-1.0, 0.0); // Desde la izquierda
                  var end = Offset.zero;
                  var curve = Curves.easeInOutQuart;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
              (route) => false, // Borra todo el historial previo
            );
          });
        });
      } else if (codeStatus == -1) {
        // Advertencia: Mostrar mensaje de advertencia pero no navegar
        _mostrarNotificacion(
          mensaje: messageStatus,
          color: Colors.orange.shade700,
          icono: Icons.warning_amber_outlined,
          duracionSegundos: 5,
        );
      } else {
        // Error: Mostrar mensaje de error amigable
        _mostrarError(
          messageStatus.contains('usuario ya existe')
              ? 'El nombre de usuario ya está en uso. Por favor elija otro nombre de usuario'
              : messageStatus.contains('correo ya existe')
              ? 'El correo electrónico ya está registrado. ¿Olvidó su contraseña?'
              : 'No se pudo completar el registro. Por favor intente nuevamente',
        );
      }
    } catch (e) {
      debugPrint('Error en registro: $e');
      _mostrarError(
        'No se pudo completar el registro. Por favor verifique su conexión e intente nuevamente',
      );
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _pasoAnterior() {
    if (_pasoActual > 0) {
      setState(() {
        _pasoActual--;
      });
    }
  }

  void _siguientePaso() {
    if (!_formkey.currentState!.validate()) return;

    if (_pasoActual < _totalPasos - 1) {
      setState(() {
        _pasoActual++;
      });
    } else {
      _registrarUsuario(); // último paso
    }
  }

  Widget _construirContenidoPaso() {
    switch (_pasoActual) {
      case 0:
        return _construirPasoDatosPersonales();
      case 1:
        return _construirPasoDireccionMunicipio();
      case 2:
        return _construirPasoDatosUsuario();
      default:
        return const Text('Error');
    }
  }

  Widget _construirPasoDatosPersonales() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DNI
        TextFormField(
          controller: _dniController,
          keyboardType: TextInputType.text,
          textInputAction:
              TextInputAction.next, // Permite avanzar al siguiente campo
          textCapitalization:
              TextCapitalization.characters, // Mayúsculas automáticas
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'DNI / Identidad',
            hintText: 'Ej: 0801199812345',
            helperText: 'Ingrese los 13 dígitos sin guiones',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El DNI es requerido';
            }
            if (value.length < 13) {
              return 'El DNI debe tener al menos 13 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Nombre
        TextFormField(
          controller: _nombreController,
          textInputAction: TextInputAction.next,
          textCapitalization:
              TextCapitalization
                  .words, // Primera letra de cada palabra en mayúscula
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ingrese su nombre',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Apellido
        TextFormField(
          controller: _apellidoController,
          textInputAction: TextInputAction.next,
          textCapitalization:
              TextCapitalization
                  .words, // Primera letra de cada palabra en mayúscula
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Apellido',
            hintText: 'Ingrese su apellido',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El apellido es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Sexo (Radio Buttons en fila)
        // Mantenemos los radio buttons como prefiere el usuario
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text('Sexo', style: TextStyle(fontSize: 16)),
              ),
              Row(
                children:
                    _opcionesSexo.map((opcion) {
                      return Expanded(
                        child: RadioListTile<String>(
                          title: Text(opcion['texto']),
                          value: opcion['valor'],
                          groupValue: _sexoSeleccionado,
                          activeColor: primaryColor,
                          onChanged: (valor) {
                            setState(() {
                              _sexoSeleccionado = valor!;
                            });
                          },
                          dense: true,
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // Estado Civil
        // Mantenemos la opción por defecto "Seleccione una opción" como prefiere el usuario
        _cargandoEstadosCiviles
            ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Cargando estados civiles...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
            : DropdownButtonFormField<int?>(
              value: _estadoCivilSeleccionado,
              decoration: InputDecoration(
                labelText: 'Estado Civil',
                prefixIcon: const Icon(Icons.favorite),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              hint: const Text('Seleccione una opción'),
              isExpanded:
                  true, // Asegura que el dropdown ocupe todo el ancho disponible
              items: [
                // Opción por defecto
                const DropdownMenuItem<int?>(
                  value: 0,
                  child: Text(
                    'Seleccione una opción',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                // Resto de opciones de estados civiles
                ..._estadosCiviles.map((estadoCivil) {
                  return DropdownMenuItem<int?>(
                    value: estadoCivil.esCi_Id,
                    child: Text(estadoCivil.esCi_Nombre),
                  );
                }).toList(),
              ],
              validator: (value) {
                if (value == null || value == 0) {
                  return 'Por favor seleccione un estado civil';
                }
                return null;
              },
              onChanged: (valor) {
                setState(() {
                  _estadoCivilSeleccionado = valor;
                });
                // Eliminamos la validación en cada cambio para optimizar rendimiento
              },
            ),
        const SizedBox(height: 15),

        // Teléfono
        TextFormField(
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Teléfono',
            hintText: 'Ej: 98765432',
            helperText: 'Ingrese su número de teléfono sin guiones',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El teléfono es requerido';
            }
            if (value.length < 8) {
              return 'El teléfono debe tener al menos 8 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Correo
        TextFormField(
          controller: _correoController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Correo Electrónico',
            hintText: 'ejemplo@correo.com',
            helperText: 'Ingrese un correo electrónico válido',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El correo es requerido';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Ingrese un correo electrónico válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _construirPasoDireccionMunicipio() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dirección
        TextFormField(
          controller: _direccionController,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          textCapitalization:
              TextCapitalization
                  .sentences, // Primera letra de cada oración en mayúscula
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Dirección',
            hintText: 'Ingrese su dirección completa',
            helperText: 'Calle, número, colonia, referencias',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La dirección es requerida';
            }
            if (value.length < 5) {
              return 'Ingrese una dirección más detallada';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Departamento
        _cargandoDepartamentos
            ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Cargando departamentos...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
            : DropdownButtonFormField<int?>(
              value: _departamentoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Departamento',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              hint: const Text('Seleccione un departamento'),
              isExpanded:
                  true, // Asegura que el dropdown ocupe todo el ancho disponible
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Seleccione un departamento',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ..._departamentos.map((depa) {
                  return DropdownMenuItem<int?>(
                    value: int.tryParse(depa.depa_Codigo),
                    child: Text(
                      depa.depa_Nombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _departamentoSeleccionado = value;
                  _municipioSeleccionado = null;
                  _municipios = [];
                  _cargarMunicipiosPorDepartamento();
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor seleccione un departamento';
                }
                return null;
              },
            ),
        const SizedBox(height: 15),

        // Municipio
        _cargandoMunicipios
            ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Cargando municipios...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
            : DropdownButtonFormField<String?>(
              value: _municipioSeleccionado,
              decoration: InputDecoration(
                labelText: 'Municipio',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              hint: const Text('Seleccione un municipio'),
              isExpanded:
                  true, // Asegura que el dropdown ocupe todo el ancho disponible
              items:
                  _municipios.isEmpty
                      ? [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'No se encontraron municipios',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ]
                      : [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Seleccione un municipio',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ..._municipios.map((muni) {
                          return DropdownMenuItem<String?>(
                            value: muni.muni_Codigo,
                            child: Text(
                              muni.muni_Nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
              onChanged:
                  _municipios.isEmpty
                      ? null
                      : (value) {
                        setState(() {
                          _municipioSeleccionado = value;
                        });
                      },
              validator: (value) {
                if (_municipios.isEmpty) {
                  return null; // No validamos si no hay municipios disponibles
                }
                if (value == null) {
                  return 'Por favor seleccione un municipio';
                }
                return null;
              },
            ),
      ],
    );
  }

  Widget _construirPasoDatosUsuario() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Usuario
        TextFormField(
          controller: _usuarioController,
          textInputAction: TextInputAction.next,
          textCapitalization:
              TextCapitalization
                  .none, // Sin mayúsculas automáticas para nombre de usuario
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Nombre de Usuario',
            hintText: 'Ej: usuario123',
            helperText: 'Mínimo 3 caracteres, sin espacios',
            prefixIcon: const Icon(Icons.account_circle),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese un nombre de usuario';
            }
            if (value.length < 3) {
              return 'El nombre de usuario debe tener al menos 3 caracteres';
            }
            if (value.contains(' ')) {
              return 'El nombre de usuario no debe contener espacios';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Contraseña
        TextFormField(
          controller: _contrasenaController,
          obscureText: true, // Oculta el texto para contraseñas
          textInputAction: TextInputAction.next,
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Contraseña',
            hintText: 'Ingrese su contraseña',
            helperText: 'Mínimo 6 caracteres, use letras y números',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese una contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            // Podemos agregar validaciones adicionales de seguridad si se requieren
            // Por ejemplo: verificar que contenga al menos un número y una letra
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Confirmar Contraseña
        TextFormField(
          controller: _confirmarContrasenaController,
          obscureText: true, // Oculta el texto para contraseñas
          textInputAction: TextInputAction.done,
          // Eliminamos la validación en cada cambio para optimizar rendimiento
          decoration: InputDecoration(
            labelText: 'Confirmar Contraseña',
            hintText: 'Repita su contraseña',
            helperText: 'Debe coincidir con la contraseña anterior',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor confirme su contraseña';
            }
            if (value != _contrasenaController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sistema de Reportes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // TAB DE NAVEGACIÓN
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const LoginScreen(),
                                      transitionsBuilder: (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        var begin = const Offset(
                                          -1.0,
                                          0.0,
                                        ); // Desde la izquierda
                                        var end = Offset.zero;
                                        var curve = Curves.easeInOutQuart;

                                        var tween = Tween(
                                          begin: begin,
                                          end: end,
                                        ).chain(CurveTween(curve: curve));
                                        var offsetAnimation = animation.drive(
                                          tween,
                                        );

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(
                                        milliseconds: 500,
                                      ),
                                    ),
                                    (route) =>
                                        false, // Borra todo el historial previo
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Registrarse',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Indicador de progreso
                      Row(
                        children: List.generate(
                          _totalPasos,
                          (index) => Expanded(
                            child: Container(
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color:
                                    index <= _pasoActual
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Título y descripción del paso actual
                      Text(
                        _titulosPasos[_pasoActual],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _descripcionesPasos[_pasoActual],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _construirContenidoPaso(),
                            const SizedBox(height: 25),
                            // Botones de navegación
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_pasoActual > 0)
                                  ElevatedButton.icon(
                                    onPressed: _pasoAnterior,
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Anterior'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 120),
                                ElevatedButton.icon(
                                  onPressed: _cargando ? null : _siguientePaso,
                                  icon:
                                      _cargando
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Icon(
                                            _pasoActual < _totalPasos - 1
                                                ? Icons.arrow_forward
                                                : Icons.check,
                                          ),
                                  label: Text(
                                    _pasoActual < _totalPasos - 1
                                        ? 'Siguiente'
                                        : 'Registrarse',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _pasoActual < _totalPasos - 1
                                            ? Colors.blue.shade700
                                            : Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Espacio adicional al final
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
