import 'package:flutter/material.dart';
import '../services/usuarioService.dart';
import '../screens/login.dart';

class RegistrarseScreen extends StatefulWidget {
  const RegistrarseScreen({super.key});

  @override
  State<RegistrarseScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistrarseScreen> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final UsuarioService _usuarioService = UsuarioService();

  // Controladores para campos de usuario
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController = TextEditingController();

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
  String _mensaje = '';
  String _sexoSeleccionado = 'M';
  int _estadoCivilSeleccionado = 1;

  // Opciones para dropdowns
  final List<Map<String, dynamic>> _opcionesSexo = [
    {'valor': 'M', 'texto': 'Masculino'},
    {'valor': 'F', 'texto': 'Femenino'},
  ];

  final List<Map<String, dynamic>> _opcionesEstadoCivil = [
    {'valor': 1, 'texto': 'Soltero/a'},
    {'valor': 2, 'texto': 'Casado/a'},
    {'valor': 3, 'texto': 'Divorciado/a'},
    {'valor': 4, 'texto': 'Viudo/a'},
  ];

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
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    if (!_formkey.currentState!.validate()) {
      return;
    }

    // Validar confirmación de contraseña
    if (_contrasenaController.text != _confirmarContrasenaController.text) {
      setState(() {
        _mensaje = 'Las contraseñas no coinciden.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      final resultado = await _usuarioService.registro(
        // Datos de usuario
        usuario: _usuarioController.text.trim(),
        contrasena: _contrasenaController.text,
        usuaCreacion: 1,
        
        // Datos de persona
        dni: _dniController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        sexo: _sexoSeleccionado,
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
        direccion: _direccionController.text.trim(),
        municipioCodigo: _municipioController.text.trim(),
        estadoCivilId: _estadoCivilSeleccionado,
      );

      setState(() {
        _mensaje = resultado['message_Status'] ?? 'Respuesta desconocida';
      });

      // Si el registro fue exitoso, navegar al login después de 2 segundos
      if (resultado['success'] == true) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _mensaje = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
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
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
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

                            // SECCIÓN: DATOS PERSONALES
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Datos Personales',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  
                                  // DNI
                                  TextFormField(
                                    controller: _dniController,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      labelText: 'DNI / Identidad',
                                      hintText: 'Ej: 0801199812345',
                                      prefixIcon: const Icon(Icons.credit_card),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El DNI es requerido.';
                                      }
                                      if (value.length < 13) {
                                        return 'El DNI debe tener al menos 13 caracteres.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // Nombre y Apellido en fila
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _nombreController,
                                          decoration: InputDecoration(
                                            labelText: 'Nombre',
                                            hintText: 'Tu nombre',
                                            prefixIcon: const Icon(Icons.person),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: primaryColor, width: 2),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Nombre requerido';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _apellidoController,
                                          decoration: InputDecoration(
                                            labelText: 'Apellido',
                                            hintText: 'Tu apellido',
                                            prefixIcon: const Icon(Icons.person_outline),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: primaryColor, width: 2),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Apellido requerido';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),

                                  // Sexo y Estado Civil en fila
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _sexoSeleccionado,
                                          decoration: InputDecoration(
                                            labelText: 'Sexo',
                                            prefixIcon: const Icon(Icons.wc),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: primaryColor, width: 2),
                                            ),
                                          ),
                                          items: _opcionesSexo.map((opcion) {
                                            return DropdownMenuItem<String>(
                                              value: opcion['valor'],
                                              child: Text(opcion['texto']),
                                            );
                                          }).toList(),
                                          onChanged: (valor) {
                                            setState(() {
                                              _sexoSeleccionado = valor!;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
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
                                          items: _opcionesEstadoCivil.map((opcion) {
                                            return DropdownMenuItem<int>(
                                              value: opcion['valor'],
                                              child: Text(opcion['texto']),
                                            );
                                          }).toList(),
                                          onChanged: (valor) {
                                            setState(() {
                                              _estadoCivilSeleccionado = valor!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),

                                  // Teléfono
                                  TextFormField(
                                    controller: _telefonoController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Teléfono',
                                      hintText: 'Ej: 98765432',
                                      prefixIcon: const Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El teléfono es requerido.';
                                      }
                                      if (value.length < 8) {
                                        return 'Teléfono debe tener al menos 8 dígitos.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // Correo
                                  TextFormField(
                                    controller: _correoController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Correo Electrónico',
                                      hintText: 'ejemplo@correo.com',
                                      prefixIcon: const Icon(Icons.email),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El correo es requerido.';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Ingrese un correo válido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // Dirección
                                  TextFormField(
                                    controller: _direccionController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      labelText: 'Dirección',
                                      hintText: 'Tu dirección completa',
                                      prefixIcon: const Icon(Icons.home),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La dirección es requerida.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // Municipio
                                  TextFormField(
                                    controller: _municipioController,
                                    decoration: InputDecoration(
                                      labelText: 'Código de Municipio',
                                      hintText: 'Ej: 0801',
                                      prefixIcon: const Icon(Icons.location_city),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El código de municipio es requerido.';
                                      }
                                      if (value.length != 4) {
                                        return 'El código debe tener 4 dígitos.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // SECCIÓN: DATOS DE USUARIO
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Datos de Usuario',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Usuario
                                  TextFormField(
                                    controller: _usuarioController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre de Usuario',
                                      hintText: 'Ej: usuario123',
                                      prefixIcon: const Icon(Icons.account_circle),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El usuario es requerido.';
                                      }
                                      if (value.length < 3) {
                                        return 'El usuario debe tener al menos 3 caracteres.';
                                      }
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
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La contraseña es requerida.';
                                      }
                                      if (value.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres.';
                                      }
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
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Debe confirmar la contraseña.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),

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