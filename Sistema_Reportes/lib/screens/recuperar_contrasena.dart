// =============================================================================
// SISTEMA DE REPORTES - PANTALLA DE RECUPERACIÓN DE CONTRASEÑA
// =============================================================================
// Descripción: Este archivo contiene la implementación de la pantalla para
// recuperar la contraseña de un usuario mediante un proceso de verificación.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:sistema_reportes/services/usuarioService.dart';
import 'package:sistema_reportes/services/connectivityService.dart';
import 'package:sistema_reportes/screens/login.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Widget principal de la pantalla de recuperación de contraseña.
///
/// Esta pantalla permite a los usuarios recuperar su contraseña
/// mediante un proceso de verificación.
class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({Key? key}) : super(key: key);

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

/// Estado del widget RecuperarContrasenaScreen.
///
/// Maneja la lógica de recuperación de contraseña y la navegación.
class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  // Controladores para los campos de texto (inicializados en initState)
  late TextEditingController _usuarioController;
  late TextEditingController _codigoController;
  late TextEditingController _nuevaContrasenaController;
  late TextEditingController _confirmarContrasenaController;

  // Stream para el campo de código PIN
  StreamController<ErrorAnimationType>? _errorController;
  bool _hasError = false;

  // Clave para el formulario
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  // Estado de carga
  bool _cargando = false;

  // Paso actual del proceso de recuperación
  int _pasoActual = 1;

  // Datos del usuario en proceso de recuperación
  int _usuarioId = 0;
  String _correoUsuario = '';
  String _tokenGenerado = '';

  // Servicios
  final UsuarioService _usuarioService = UsuarioService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Referencia a la notificación actual
  Flushbar? _currentFlushbar;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores aquí
    _usuarioController = TextEditingController();
    _codigoController = TextEditingController();
    _nuevaContrasenaController = TextEditingController();
    _confirmarContrasenaController = TextEditingController();

    _errorController = StreamController<ErrorAnimationType>();
  }

  @override
  void dispose() {
    try {
      _usuarioController.dispose();
      _codigoController.dispose();
      _nuevaContrasenaController.dispose();
      _confirmarContrasenaController.dispose();
      _errorController?.close();
    } catch (e) {
      debugPrint("Error disposing controllers: $e");
    }

    if (_currentFlushbar != null) {
      try {
        _currentFlushbar!.dismiss();
      } catch (e) {
        debugPrint('Error al cerrar notificación en dispose: $e');
      }
      _currentFlushbar = null;
    }

    super.dispose();
  }

  /// Muestra una notificación en la parte superior de la pantalla
  void _mostrarNotificacion({
    required String mensaje,
    required Color color,
    required IconData icono,
    bool mostrarProgreso = false,
    int duracionSegundos = 3,
  }) {
    if (_currentFlushbar != null) {
      _currentFlushbar!.dismiss();
    }
    _currentFlushbar = Flushbar(
      message: mensaje,
      icon: Icon(icono, size: 28.0, color: Colors.white),
      backgroundColor: color,
      duration: mostrarProgreso ? null : Duration(seconds: duracionSegundos),
      showProgressIndicator: mostrarProgreso,
      progressIndicatorBackgroundColor: Colors.white,
    );
    _currentFlushbar!.show(context);
  }

  /// Muestra una notificación de error
  void _mostrarError(String mensaje) {
    _mostrarNotificacion(
      mensaje: mensaje,
      color: Colors.red.shade700,
      icono: Icons.error_outline,
    );
  }

  /// Muestra una notificación de advertencia
  void _mostrarAdvertencia(String mensaje) {
    _mostrarNotificacion(
      mensaje: mensaje,
      color: Colors.orange.shade700,
      icono: Icons.warning_amber_outlined,
    );
  }

  /// Muestra una notificación de éxito
  void _mostrarExito(String mensaje) {
    _mostrarNotificacion(
      mensaje: mensaje,
      color: Colors.green.shade700,
      icono: Icons.check_circle_outline,
    );
  }

  /// Muestra una notificación de carga con barra de progreso
  void _mostrarCargando(String mensaje) {
    _mostrarNotificacion(
      mensaje: mensaje,
      color: Colors.blue.shade700,
      icono: Icons.info_outline,
      mostrarProgreso: true,
      duracionSegundos: 30,
    );
  }

  /// Cierra cualquier notificación pendiente de manera segura
  void _cerrarNotificacion() {
    if (_currentFlushbar != null) {
      try {
        _currentFlushbar!.dismiss();
      } catch (e) {
        debugPrint('Error al cerrar notificación: $e');
      }
      _currentFlushbar = null;
    }
  }

  /// Maneja el proceso de verificación de usuario (Paso 1)
  Future<void> _verificarUsuario() async {
    if (_usuarioController.text.trim().isEmpty) {
      _mostrarError('Por favor, ingresa tu nombre de usuario');
      return;
    }

    bool tieneConexion = await _connectivityService.hasConnection();
    if (!tieneConexion) {
      _mostrarError(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
      return;
    }

    _mostrarCargando('Verificando usuario...');
    try {
      final resultado = await _usuarioService.verificarUsuario(
        _usuarioController.text.trim(),
      );

      _cerrarNotificacion();

      final codeStatus = resultado['codeStatus'];
      final messageStatus = resultado['messageStatus'];

      if (codeStatus > 0) {
        _usuarioId = codeStatus;
        _correoUsuario = messageStatus;
        await _generarCodigoRecuperacion();
      } else if (codeStatus == -1) {
        _mostrarAdvertencia(messageStatus);
      } else {
        _mostrarError(messageStatus);
      }
    } catch (e) {
      _cerrarNotificacion();
      _mostrarError(
        'No se pudo verificar el usuario. Por favor, intenta nuevamente.',
      );
    }
  }

  /// Valida el código ingresado por el usuario (Paso 2)
  Future<void> _validarCodigo() async {
    if (_codigoController.text.isEmpty) {
      _mostrarError('Por favor, ingresa el código de verificación');
      _errorController?.add(ErrorAnimationType.shake);
      setState(() {
        _hasError = true;
      });
      return;
    }

    bool tieneConexion = await _connectivityService.hasConnection();
    if (!tieneConexion) {
      _mostrarError('No hay conexión a internet.');
      return;
    }

    _mostrarCargando('Validando código...');
    try {
      final codigoIngresado = _codigoController.text.trim();
      final codigoAValidar =
          codigoIngresado.isEmpty && _tokenGenerado.isNotEmpty
              ? _tokenGenerado
              : codigoIngresado;

      final esValido = await _usuarioService.validarCodigo(
        _usuarioId,
        codigoAValidar,
      );

      _cerrarNotificacion();

      if (esValido) {
        setState(() {
          _pasoActual = 3;
        });
      } else {
        _mostrarError(
          'El código ingresado no es válido. Por favor, verifica e intenta nuevamente.',
        );
        _errorController?.add(ErrorAnimationType.shake);
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      _cerrarNotificacion();
      _mostrarError(
        'No se pudo validar el código. Por favor, intenta nuevamente.',
      );
    }
  }

  /// Genera un código de recuperación (Paso 1 -> 2)
  Future<void> _generarCodigoRecuperacion() async {
    _mostrarCargando('Generando código de recuperación...');
    try {
      _tokenGenerado = await _usuarioService.generarCodigoRestablecimiento(
        _usuarioId,
      );
      _cerrarNotificacion();
      setState(() {
        _pasoActual = 2;
      });
      _mostrarExito(
        'Se ha enviado un código de recuperación al correo $_correoUsuario',
      );
    } catch (e) {
      _mostrarError(
        'No se pudo generar el código de recuperación. Por favor, intenta nuevamente.',
      );
    }
  }

  /// Restablece la contraseña del usuario (Paso 3)
  Future<void> _restablecerContrasena() async {
    if (!_formkey.currentState!.validate()) return;

    if (_nuevaContrasenaController.text !=
        _confirmarContrasenaController.text) {
      _mostrarError(
        'Las contraseñas no coinciden. Por favor, verifica e intenta nuevamente.',
      );
      return;
    }

    bool tieneConexion = await _connectivityService.hasConnection();
    if (!tieneConexion) {
      _mostrarError(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
      return;
    }

    _mostrarCargando('Restableciendo contraseña...');

    try {
      final exito = await _usuarioService.restablecerContrasena(
        _usuarioId,
        _nuevaContrasenaController.text.trim(),
      );

      _cerrarNotificacion();

      if (exito) {
        _mostrarExito('Contraseña restablecida correctamente.');

        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, animation, __, child) {
                var begin = const Offset(-1.0, 0.0);
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
            (route) => false, // Borra todo el historial previo
          );
        }
      } else {
        _mostrarError(
          'No se pudo restablecer la contraseña. Por favor, intenta nuevamente.',
        );
      }
    } catch (e) {
      _mostrarError(
        'Ocurrió un error al restablecer la contraseña. Por favor, intenta nuevamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue.shade700;
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
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
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_reset,
                          size: 60,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Recuperar Contraseña',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Ingresa tu nombre de usuario para recibir instrucciones de recuperación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 30),
                        Form(
                          key: _formkey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Contenido dinámico según el paso actual
                              if (_pasoActual == 1) ...[
                                TextFormField(
                                  controller: _usuarioController,
                                  decoration: InputDecoration(
                                    labelText: 'Usuario',
                                    hintText: 'Ingrese su nombre de usuario',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El campo usuario es requerido.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        _cargando
                                            ? null
                                            : () {
                                              if (_formkey.currentState
                                                      ?.validate() ??
                                                  false) {
                                                _verificarUsuario();
                                              }
                                            },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        _cargando
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              'Verificar Usuario',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ),
                              ] else if (_pasoActual == 2) ...[
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 60,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Verificar Código',
                                  style: TextStyle(
                                      color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Hemos enviado un código de verificación a $_correoUsuario',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 30),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: PinCodeTextField(
                                    appContext: context,
                                    length: 5,
                                    obscureText: false,
                                    animationType: AnimationType.fade,
                                    pinTheme: PinTheme(
                                      shape: PinCodeFieldShape.box,
                                      borderRadius: BorderRadius.circular(5),
                                      fieldHeight: 50,
                                      fieldWidth: 40,
                                      activeFillColor: Colors.white,
                                      inactiveFillColor: Colors.white,
                                      selectedFillColor: Colors.white,
                                      activeColor:
                                          _hasError ? Colors.red : Colors.blue,
                                      inactiveColor: Colors.grey,
                                      selectedColor: Colors.blue,
                                      errorBorderColor: Colors.red,
                                    ),
                                    animationDuration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    enableActiveFill: true,
                                    errorAnimationController: _errorController,
                                    controller: _codigoController,
                                    onCompleted: (v) {
                                      _validarCodigo();
                                    },
                                    onChanged: (value) {
                                      if (_hasError) {
                                        setState(() {
                                          _hasError = false;
                                        });
                                      }
                                    },
                                    beforeTextPaste: (text) {
                                      return text
                                              ?.replaceAll(
                                                RegExp(r'[^a-zA-Z0-9]'),
                                                '',
                                              )
                                              ?.isNotEmpty ??
                                          false;
                                    },
                                    keyboardType: TextInputType.text,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        _cargando ? null : _validarCodigo,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        _cargando
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              'Verificar Código',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ),
                              ] else if (_pasoActual == 3) ...[
                                TextFormField(
                                  controller: _nuevaContrasenaController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Nueva Contraseña',
                                    hintText: 'Ingrese su nueva contraseña',
                                    prefixIcon: const Icon(Icons.lock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'La nueva contraseña es requerida.';
                                    }
                                    if (value.length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _confirmarContrasenaController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar Contraseña',
                                    hintText: 'Confirme su nueva contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Debe confirmar la contraseña.';
                                    }
                                    if (value !=
                                        _nuevaContrasenaController.text) {
                                      return 'Las contraseñas no coinciden.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        _cargando
                                            ? null
                                            : _restablecerContrasena,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        _cargando
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              'Restablecer Contraseña',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (_, __, ___) => const LoginScreen(),
                                      transitionsBuilder: (
                                        _,
                                        animation,
                                        __,
                                        child,
                                      ) {
                                        var begin = const Offset(-1.0, 0.0);
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
                                child: const Text(
                                  'Volver a Iniciar Sesión',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
