// =============================================================================
// SISTEMA DE REPORTES - PANTALLA DE LOGIN
// =============================================================================
// Descripción: Este archivo contiene la implementación de la pantalla de login
// con funcionalidades de autenticación, almacenamiento seguro de credenciales
// y navegación a la pantalla de registro.
// =============================================================================
// Autor: Alejandro
// Fecha: Mayo 2025
// =============================================================================

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sistema_reportes/services/usuarioService.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/usuarioViewModel.dart';
import '../screens/principal.dart';
import '../screens/Registrarse.dart';

/// Widget principal de la pantalla de login.
///
/// Esta pantalla permite a los usuarios iniciar sesión en el sistema
/// y también proporciona navegación a la pantalla de registro.
/// Implementa un diseño moderno con gradiente de fondo, tarjeta de
/// formulario y tabs de navegación.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Estado del widget LoginScreen.
///
/// Maneja la lógica de autenticación, almacenamiento seguro de credenciales
/// y navegación entre pantallas.
class _LoginScreenState extends State<LoginScreen> {
  /// Controlador para el campo de texto del usuario
  final TextEditingController _usuarioController = TextEditingController();

  /// Controlador para el campo de texto de la contraseña
  final TextEditingController _contrasenaController = TextEditingController();

  /// Clave global para acceder y validar el formulario
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  /// Servicio para realizar operaciones de autenticación con la API
  final UsuarioService _usuarioService = UsuarioService();

  /// Indica si se está procesando la solicitud de inicio de sesión
  bool _cargando = false;

  /// Mensaje de éxito o error para mostrar al usuario
  String _mensaje = '';

  /// Controla si se debe mantener la sesión activa después de cerrar la app
  /// Por defecto es true para mejor experiencia de usuario
  bool _mantenerSesion = true;

  /// Instancia de FlutterSecureStorage para almacenar datos de forma segura
  final storage = FlutterSecureStorage();

  /// Se ejecuta cuando el widget se inserta en el árbol de widgets
  ///
  /// Verifica si hay una sesión activa guardada para realizar
  /// un inicio de sesión automático
  @override
  void initState() {
    super.initState();
    // Verificar si hay una sesión activa al iniciar
    _verificarSesion();
  }

  /// Libera recursos cuando el widget se elimina del árbol de widgets
  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  /// Verifica si existe una sesión activa guardada en el almacenamiento seguro
  ///
  /// Si encuentra una sesión activa (el usuario marcó "Mantener sesión activa"
  /// en su último inicio de sesión), navega automáticamente a la pantalla principal
  /// sin requerir que el usuario vuelva a ingresar sus credenciales.
  Future<void> _verificarSesion() async {
    try {
      final sesionActiva = await storage.read(key: 'sesion_activa');

      if (sesionActiva == 'true') {
        // Si hay una sesión activa, navegar a la pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const principalScreen()),
        );
      }
    } catch (e) {
      print('Error al verificar la sesión: $e');
      // Si hay un error, simplemente continuamos con la pantalla de login
    }
  }

  /// Almacena los datos del usuario en el almacenamiento seguro
  ///
  /// Este método guarda la información del usuario autenticado en el
  /// almacenamiento seguro (FlutterSecureStorage) para poder acceder a ella
  /// posteriormente sin necesidad de volver a iniciar sesión.
  ///
  /// Guarda los siguientes datos:
  /// - ID del usuario
  /// - Nombre de usuario
  /// - Token de autenticación
  /// - Rol del usuario
  /// - Estado de administrador
  /// - Pantallas disponibles (si existen)
  /// - Información del empleado (si existe)
  /// - Estado de la sesión activa (según la elección del usuario)
  ///
  /// @param usuario Objeto Usuario con los datos a guardar
  Future<void> _guardarDatosUsuario(Usuario usuario) async {
    try {
      // Guardar información básica del usuario
      await storage.write(key: 'usuario_id', value: usuario.usua_Id.toString());
      await storage.write(key: 'usuario_nombre', value: usuario.usua_Usuario);
      await storage.write(key: 'usuario_token', value: usuario.usua_Token);
      await storage.write(key: 'usuario_rol', value: usuario.role_Nombre);
      await storage.write(
        key: 'usuario_es_admin',
        value: usuario.usua_EsAdmin.toString(),
      );

      // Guardar pantallas si están disponibles
      if (usuario.pantallas != null) {
        await storage.write(key: 'usuario_pantallas', value: usuario.pantallas);
      }

      // Guardar información adicional que pueda ser útil
      if (usuario.empleado != null) {
        await storage.write(key: 'usuario_empleado', value: usuario.empleado);
      }

      // Guardar estado de sesión activa según la elección del usuario
      await storage.write(
        key: 'sesion_activa',
        value: _mantenerSesion ? 'true' : 'false',
      );

      print('Datos del usuario guardados correctamente');
      print('Mantener sesión activa: $_mantenerSesion');
    } catch (e) {
      print('Error al guardar datos del usuario: $e');
      // No lanzamos la excepción para no interrumpir el flujo
    }
  }

  /// Maneja el proceso de inicio de sesión
  ///
  /// Este método se ejecuta cuando el usuario presiona el botón de inicio de sesión.
  /// Realiza las siguientes acciones:
  /// 1. Valida que los campos del formulario no estén vacíos
  /// 2. Muestra un indicador de carga
  /// 3. Llama al servicio de autenticación con las credenciales ingresadas
  /// 4. Si la autenticación es exitosa:
  ///    - Guarda los datos del usuario en el almacenamiento seguro
  ///    - Muestra un mensaje de éxito
  ///    - Navega a la pantalla principal
  /// 5. Si la autenticación falla, muestra un mensaje de error
  /// 6. Oculta el indicador de carga al finalizar
  void _iniciarSesion() async {
    // Validar el formulario
    if (!_formkey.currentState!.validate()) return;

    // Mostrar indicador de carga y limpiar mensajes previos
    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      // Llamar al servicio de autenticación
      final Usuario? usuario = await _usuarioService.login(
        _usuarioController.text.trim(),
        _contrasenaController.text.trim(),
      );

      // Verificar si la autenticación fue exitosa
      if (usuario != null &&
          (usuario.code_Status == 1 || usuario.code_Status == null)) {
        // Guardar datos del usuario en el almacenamiento seguro
        await _guardarDatosUsuario(usuario);

        // Mostrar mensaje de éxito
        setState(() {
          _mensaje = 'Login exitoso';
        });

        // Navegar a la pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const principalScreen()),
        );
      } else {
        // Mostrar mensaje de error si las credenciales son incorrectas
        setState(() {
          _mensaje = 'Usuario o contraseña incorrecta';
        });
      }
    } catch (e) {
      // Capturar y mostrar cualquier error que ocurra durante la autenticación
      setState(() {
        _mensaje = 'Error al iniciar sesion: $e';
      });
    } finally {
      // Ocultar el indicador de carga al finalizar
      setState(() {
        _cargando = false;
      });
    }
  }

  /// Construye la interfaz de usuario de la pantalla de login
  ///
  /// La interfaz se compone de los siguientes elementos:
  /// 1. Un fondo con gradiente azul
  /// 2. Un logo y título en la parte superior
  /// 3. Una tarjeta blanca que contiene:
  ///    - Un tab de navegación (Iniciar Sesión / Registrarse)
  ///    - Un formulario con campos para usuario y contraseña
  ///    - Una opción para mantener la sesión activa
  ///    - Un botón de inicio de sesión
  ///    - Un área para mostrar mensajes de éxito o error
  /// 4. Un pie de página con información de copyright
  @override
  Widget build(BuildContext context) {
    // Obtener el color primario del tema para usarlo en los elementos de la interfaz
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
                      // ===============================================================
                      // TAB DE NAVEGACIÓN (INICIAR SESIÓN / REGISTRARSE)
                      // ===============================================================
                      // Este componente implementa un tab de navegación personalizado que
                      // permite al usuario alternar entre las pantallas de inicio de sesión
                      // y registro. Está diseñado como un contenedor con fondo gris claro
                      // que contiene dos botones (tabs).
                      //
                      // El tab seleccionado (en este caso "Iniciar Sesión") se muestra con
                      // fondo azul y texto blanco. El tab no seleccionado tiene fondo
                      // transparente y texto negro.
                      //
                      // IMPORTANTE: Tu compañero debe implementar un diseño similar en la
                      // pantalla de registro, pero con el tab "Registrarse" seleccionado
                      // y el tab "Iniciar Sesión" no seleccionado.
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Tab "Iniciar Sesión" (seleccionado en esta pantalla)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Ya estamos en la pantalla de login, no necesitamos navegación
                                  // En la pantalla de registro, este onTap debe navegar de vuelta a LoginScreen
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    // Este tab está seleccionado, por lo que tiene fondo azul
                                    color: Colors.blue.shade700,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        // Texto blanco para el tab seleccionado
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Tab "Registrarse" (no seleccionado en esta pantalla)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navegar a la pantalla de registro
                                  // IMPORTANTE: Tu compañero debe implementar la navegación inversa
                                  // en la pantalla de registro (volver a LoginScreen)
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          const RegistrarseScreen(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        var begin = const Offset(1.0, 0.0);
                                        var end = Offset.zero;
                                        var curve = Curves.easeInOutQuart;
                                        
                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                        var offsetAnimation = animation.drive(tween);
                                        
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 500),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    // Este tab no está seleccionado, por lo que tiene fondo transparente
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Registrarse',
                                      style: TextStyle(
                                        // Texto negro para el tab no seleccionado
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Form(
                        key: _formkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),

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

                            TextFormField(
                              controller: _contrasenaController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                hintText: 'Ingrese su contraseña',
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
                                  return 'El campo contraseña es requerido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Checkbox(
                                  value: _mantenerSesion,
                                  onChanged: (value) {
                                    setState(() {
                                      _mantenerSesion = value ?? true;
                                    });
                                  },
                                  activeColor: Colors.blue.shade700,
                                ),
                                const Text(
                                  'Mantener sesión activa',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Tooltip(
                                  message:
                                      'Si activas esta opción, no tendrás que iniciar sesión la próxima vez que abras la aplicación',
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _iniciarSesion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                ),
                                child:
                                    _cargando
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'INICIAR SESIÓN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),

                            if (_mensaje.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        _mensaje.contains('exitoso')
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          _mensaje.contains('exitoso')
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _mensaje.contains('exitoso')
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color:
                                            _mensaje.contains('exitoso')
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _mensaje,
                                          style: TextStyle(
                                            color:
                                                _mensaje.contains('exitoso')
                                                    ? Colors.green
                                                    : Colors.red,
                                            fontWeight: FontWeight.bold,
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
