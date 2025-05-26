import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:another_flushbar/flushbar.dart';
import '../services/usuarioService.dart';
import '../services/estadoCivilService.dart';
import '../services/connectivityService.dart';
import '../models/estadoCivilViewModel.dart';
import '../screens/login.dart';

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

  // Para manejar la suscripción a cambios de conectividad
  late Stream<List<ConnectivityResult>> _connectivityStream;

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

    // Configurar la escucha de cambios en la conectividad
    _connectivityStream = _connectivityService.onConnectivityChanged();
    _connectivityStream.listen(_handleConnectivityChange);
  }

  /// Maneja los cambios en la conectividad
  void _handleConnectivityChange(List<ConnectivityResult> result) async {
    // Si hay alguna conexión y no tenemos estados civiles cargados
    // intentamos cargar los datos nuevamente
    if (!result.contains(ConnectivityResult.none) &&
        _cargandoEstadosCiviles == false &&
        _estadosCiviles.isEmpty) {
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

  /// Carga los estados civiles desde la API
  Future<void> _cargarEstadosCiviles() async {
    // Verificamos primero si hay conexión a internet
    final hasConnection = await _connectivityService.hasConnection();

    setState(() {
      _cargandoEstadosCiviles = true;
    });

    if (!hasConnection) {
      setState(() {
        _cargandoEstadosCiviles = false;
      });

      // Mostrar notificación de error
      _mostrarError(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
      return;
    }

    try {
      final estadosCiviles = await _estadoCivilService.listar();

      // Verificamos si el widget todavía está montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _estadosCiviles = estadosCiviles;
          // No seleccionamos ninguno por defecto, dejamos null para que se muestre "Seleccione una opción"
          _estadoCivilSeleccionado = null;
          _cargandoEstadosCiviles = false;
        });
      }
    } catch (e) {
      // Verificamos si el widget todavía está montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _cargandoEstadosCiviles = false;
        });

        // Mostrar notificación de error
        _mostrarError(
          'No se pudieron cargar las opciones de estado civil. Por favor, intenta nuevamente.',
        );
      }
    }
  }

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
    // Cerrar la notificación anterior si existe
    _currentFlushbar?.dismiss();

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
    )..show(context);
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
    // Cerrar cualquier notificación pendiente
    _currentFlushbar?.dismiss();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    if (!_formkey.currentState!.validate()) return;

    if (_contrasenaController.text != _confirmarContrasenaController.text) {
      _mostrarError('Las contraseñas no coinciden.');
      return;
    }

    // Verificar conectividad antes de realizar la solicitud
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      _mostrarError(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    // Verificamos que el estado civil esté seleccionado y sea válido
    if (_estadoCivilSeleccionado == null || _estadoCivilSeleccionado == 0) {
      setState(() {
        _cargando = false;
      });
      _mostrarError('Por favor, seleccione un estado civil válido.');
      return;
    }

    // Mostrar notificación de carga con barra de progreso
    _mostrarCargando('Procesando registro...');

    try {
      final resultado = await _usuarioService.registro(
        usuario: _usuarioController.text.trim(),
        contrasena: _contrasenaController.text,
        usuaCreacion: 1,
        dni: _dniController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        sexo: _sexoSeleccionado,
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
        direccion: _direccionController.text.trim(),
        municipioCodigo: _municipioController.text.trim(),
        estadoCivilId: _estadoCivilSeleccionado!,
      );

      // Cerrar cualquier notificación anterior para evitar conflictos
      _currentFlushbar?.dismiss();
      
      // Obtener el código de estado y mensaje
      final codeStatus = resultado['code_Status'] ?? 0;
      final messageStatus = resultado['message_Status'] ?? 'Sin mensaje';
      
      // Manejar la respuesta según el código de estado
      // 1 = Éxito, -1 = Advertencia, 0 = Error
      if (codeStatus == 1) {
        // Éxito: Mostrar mensaje y navegar al login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageStatus),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 1),
          ),
        );

        // Esperar un momento breve y luego navegar
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pushReplacement(
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

                  return SlideTransition(position: offsetAnimation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
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
        // Error: Mostrar mensaje de error
        _mostrarError(messageStatus);
      }
    } catch (e) {
      _mostrarError(
        'No se pudo completar el registro. Por favor, verifica tu conexión e intenta nuevamente.',
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
          onChanged: (_) {
            _formkey.currentState!.validate(); // Vuelve a validar el campo
          },
          decoration: InputDecoration(
            labelText: 'DNI / Identidad',
            hintText: 'Ej: 0801199812345',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),

          validator: (value) {
            if (value == null || value.isEmpty) return 'El DNI es requerido.';
            if (value.length < 13)
              return 'El DNI debe tener al menos 13 caracteres.';
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Nombre
        TextFormField(
          controller: _nombreController,
          onChanged: (_) {
            _formkey.currentState!.validate(); // Vuelve a validar el campo
          },
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: 'Tu nombre',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator:
              (value) => value?.isEmpty ?? true ? 'Nombre requerido' : null,
        ),
        const SizedBox(height: 15),

        // Apellido
        TextFormField(
          controller: _apellidoController,
          onChanged: (_) {
            _formkey.currentState!.validate(); // Vuelve a validar el campo
          },
          decoration: InputDecoration(
            labelText: 'Apellido',
            hintText: 'Tu apellido',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator:
              (value) => value?.isEmpty ?? true ? 'Apellido requerido' : null,
        ),
        const SizedBox(height: 15),

        // Sexo (Radio Buttons en fila)
        Column(
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
        const SizedBox(
          height: 5,
        ), // Espacio reducido ya que los radio buttons ocupan más espacio
        const SizedBox(height: 15),

        // Estado Civil
        _cargandoEstadosCiviles
            ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(),
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
              items: [
                // Opción por defecto
                const DropdownMenuItem<int?>(
                  value: 0,
                  child: Text('Seleccione una opción'),
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
                _formkey.currentState!.validate();
              },
            ),
        const SizedBox(height: 15),

        // Teléfono
        TextFormField(
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          onChanged: (_) {
            _formkey.currentState!.validate(); // Vuelve a validar el campo
          },
          decoration: InputDecoration(
            labelText: 'Teléfono',
            hintText: 'Ej: 98765432',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'El teléfono es requerido.';
            if (value.length < 8)
              return 'Teléfono debe tener al menos 8 dígitos.';
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Correo
        TextFormField(
          controller: _correoController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            _formkey.currentState!.validate(); // Vuelve a validar el campo
          },
          decoration: InputDecoration(
            labelText: 'Correo Electrónico',
            hintText: 'ejemplo@correo.com',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'El correo es requerido.';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
              return 'Correo inválido.';
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
          decoration: InputDecoration(
            labelText: 'Dirección',
            hintText: 'Tu dirección completa',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator:
              (value) =>
                  value?.isEmpty ?? true ? 'La dirección es requerida.' : null,
        ),
        const SizedBox(height: 15),
        // Municipio
        TextFormField(
          controller: _municipioController,
          decoration: InputDecoration(
            labelText: 'Código de Municipio',
            hintText: 'Ej: 0801',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'El código de municipio es requerido.';
            if (value.length != 4) return 'El código debe tener 4 dígitos.';
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
          decoration: InputDecoration(
            labelText: 'Nombre de Usuario',
            hintText: 'Ej: usuario123',
            prefixIcon: const Icon(Icons.account_circle),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'El usuario es requerido.';
            if (value.length < 3)
              return 'El usuario debe tener al menos 3 caracteres.';
            return null;
          },
        ),
        const SizedBox(height: 15),
        // Contraseña
        TextFormField(
          controller: _contrasenaController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            hintText: 'Mínimo 6 caracteres',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'La contraseña es requerida.';
            if (value.length < 6)
              return 'La contraseña debe tener al menos 6 caracteres.';
            return null;
          },
        ),
        const SizedBox(height: 15),
        // Confirmar Contraseña
        TextFormField(
          controller: _confirmarContrasenaController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirmar Contraseña',
            hintText: 'Repite tu contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Debe confirmar la contraseña.';
            if (value != _contrasenaController.text)
              return 'Las contraseñas no coinciden.';
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
                                  Navigator.pushReplacement(
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
