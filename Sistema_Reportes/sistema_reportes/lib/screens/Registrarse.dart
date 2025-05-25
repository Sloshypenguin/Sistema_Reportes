
import 'package:flutter/material.dart';
import '../services/usuarioService.dart';
import '../screens/login.dart';


class RegistrarseScreen extends StatefulWidget {
  const RegistrarseScreen({super.key});

  @override
  State<RegistrarseScreen> createState() => _RegistrarseScreenState();
}

class _RegistrarseScreenState extends State<RegistrarseScreen> {
  /// Controlador para el campo de texto del usuario
  final TextEditingController _usuarioController = TextEditingController();
  
  /// Controlador para el campo de texto de la contraseña
  final TextEditingController _contrasenaController = TextEditingController();
  
  /// Controlador para el campo de confirmar contraseña
  final TextEditingController _confirmarContrasenaController = TextEditingController();
  
  /// Controlador para el campo del ID de persona
  final TextEditingController _persIdController = TextEditingController();
  
  /// Clave global para acceder y validar el formulario
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  
  /// Servicio para realizar operaciones de registro con la API
  final UsuarioService _usuarioService = UsuarioService();

  /// Indica si se está procesando la solicitud de registro
  bool _cargando = false;
  
  /// Mensaje de éxito o error para mostrar al usuario
  String _mensaje = '';
  
  /// Controla si el usuario será administrador
  bool _esAdmin = false;
  
  /// Controla si el usuario será empleado
  bool _esEmpleado = false;

  /// Libera recursos cuando el widget se elimina del árbol de widgets
  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    _persIdController.dispose();
    super.dispose();
  }

  /// Maneja el proceso de registro de usuario
  /// 
  /// Este método se ejecuta cuando el usuario presiona el botón de registro.
  /// Realiza las siguientes acciones:
  /// 1. Valida que los campos del formulario sean correctos
  /// 2. Verifica que las contraseñas coincidan
  /// 3. Muestra un indicador de carga
  /// 4. Llama al servicio de registro con los datos ingresados
  /// 5. Si el registro es exitoso, navega a la pantalla de login
  /// 6. Si el registro falla, muestra un mensaje de error
  void _registrarUsuario() async {
    // Validar el formulario
    if (!_formkey.currentState!.validate()) return;
    
    // Verificar que las contraseñas coincidan
    if (_contrasenaController.text.trim() != _confirmarContrasenaController.text.trim()) {
      setState(() {
        _mensaje = 'Las contraseñas no coinciden';
      });
      return;
    }
    
    // Mostrar indicador de carga y limpiar mensajes previos
    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      // Llamar al servicio de registro
      final resultado = await _usuarioService.registro(
        usuario: _usuarioController.text.trim(),
        contrasena: _contrasenaController.text.trim(),
        persId: int.parse(_persIdController.text.trim()),
        esAdmin: _esAdmin,
        esEmpleado: _esEmpleado,
      );

      // Verificar si el registro fue exitoso
      if (resultado['success'] == true) {
        // Mostrar mensaje de éxito
        setState(() {
          _mensaje = resultado['message_Status'] ?? 'Usuario registrado correctamente';
        });

        // Esperar un momento para que el usuario lea el mensaje
        await Future.delayed(const Duration(seconds: 2));

        // Navegar de vuelta a la pantalla de login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Mostrar mensaje de error
        setState(() {
          _mensaje = resultado['message_Status'] ?? 'Error al registrar usuario';
        });
      }
    } catch (e) {
      // Capturar y mostrar cualquier error que ocurra durante el registro
      setState(() {
        _mensaje = 'Error al registrar usuario: $e';
      });
    } finally {
      // Ocultar el indicador de carga al finalizar
      setState(() {
        _cargando = false;
      });
    }
  }

  /// Construye la interfaz de usuario de la pantalla de registro
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
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
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
                const SizedBox(height: 50),

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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Tab "Iniciar Sesión" (no seleccionado en esta pantalla)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navegar de vuelta a la pantalla de login
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    // Este tab no está seleccionado, por lo que tiene fondo transparente
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Iniciar Sesión',
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
                            // Tab "Registrarse" (seleccionado en esta pantalla)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Ya estamos en la pantalla de registro, no necesitamos navegación
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    // Este tab está seleccionado, por lo que tiene fondo azul
                                    color: Colors.blue.shade700,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Registrarse',
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
                              'Crear Cuenta',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Campo Usuario
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
                                if (value.length < 3) {
                                  return 'El usuario debe tener al menos 3 caracteres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Campo ID de Persona
                            TextFormField(
                              controller: _persIdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'ID de Persona',
                                hintText: 'Ingrese el ID de la persona',
                                prefixIcon: const Icon(Icons.badge),
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
                                  return 'El ID de persona es requerido.';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Debe ingresar un número válido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Campo Contraseña
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
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Campo Confirmar Contraseña
                            TextFormField(
                              controller: _confirmarContrasenaController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Confirmar Contraseña',
                                hintText: 'Confirme su contraseña',
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
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Checkboxes para roles
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _esAdmin,
                                        onChanged: (value) {
                                          setState(() {
                                            _esAdmin = value ?? false;
                                          });
                                        },
                                        activeColor: Colors.blue.shade700,
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Es Administrador',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _esEmpleado,
                                        onChanged: (value) {
                                          setState(() {
                                            _esEmpleado = value ?? false;
                                          });
                                        },
                                        activeColor: Colors.blue.shade700,
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Es Empleado',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Botón de registro
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _registrarUsuario,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                ),
                                child: _cargando
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'REGISTRARSE',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            // Área de mensajes
                            if (_mensaje.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _mensaje.contains('correctamente') || _mensaje.contains('registrado')
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _mensaje.contains('correctamente') || _mensaje.contains('registrado')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _mensaje.contains('correctamente') || _mensaje.contains('registrado')
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: _mensaje.contains('correctamente') || _mensaje.contains('registrado')
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _mensaje,
                                          style: TextStyle(
                                            color: _mensaje.contains('correctamente') || _mensaje.contains('registrado')
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