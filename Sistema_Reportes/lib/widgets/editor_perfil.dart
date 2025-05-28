import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/usuarioService.dart';
import '../services/connectivityService.dart';

/// Widget para editar el perfil del usuario
///
/// Este widget muestra un diálogo que permite al usuario editar su nombre de usuario
/// y correo electrónico. Realiza validaciones básicas y envía los datos al servidor.
class EditorPerfil extends StatefulWidget {
  /// Función a ejecutar después de una actualización exitosa
  final Function? onActualizacionExitosa;

  /// Constructor del widget
  const EditorPerfil({Key? key, this.onActualizacionExitosa}) : super(key: key);

  @override
  State<EditorPerfil> createState() => _EditorPerfilState();
}

class _EditorPerfilState extends State<EditorPerfil> {
  // Servicios
  final UsuarioService _usuarioService = UsuarioService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  // Variables para controlar el estado
  bool _isLoading = false;
  String? _errorNombre;
  String? _errorCorreo;

  // Datos del usuario
  String _nombreUsuario = '';
  String _correoUsuario = '';
  int _usuarioId = 0;
  int _persId = 0;
  int _roleId = 0;
  bool _esAdmin = false;
  bool _esEmpleado = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  /// Carga los datos del usuario desde el almacenamiento seguro
  Future<void> _cargarDatosUsuario() async {
    try {
      // Cargar datos básicos del usuario
      final nombre = await _storage.read(key: 'usuario_nombre');
      final correo = await _storage.read(key: 'usuario_correo');
      final idStr = await _storage.read(key: 'usuario_id');
      final persIdStr = await _storage.read(key: 'pers_id');
      final roleIdStr = await _storage.read(key: 'role_id');
      final esAdminStr = await _storage.read(key: 'usuario_es_admin');
      final esEmpleadoStr = await _storage.read(key: 'usuario_es_empleado');

      if (mounted) {
        setState(() {
          _nombreUsuario = nombre ?? 'Usuario';
          _correoUsuario = correo ?? '';

          // Actualizar controladores
          _nombreController.text = _nombreUsuario;
          _correoController.text = _correoUsuario;

          // Convertir valores numéricos y booleanos
          _usuarioId = idStr != null ? int.tryParse(idStr) ?? 0 : 0;
          _persId = persIdStr != null ? int.tryParse(persIdStr) ?? 0 : 0;
          _roleId = roleIdStr != null ? int.tryParse(roleIdStr) ?? 0 : 0;
          _esAdmin = esAdminStr == 'true';
          _esEmpleado = esEmpleadoStr == 'true';
        });
      }

      debugPrint('Datos del usuario cargados correctamente en el widget');
    } catch (e) {
      debugPrint('Error al cargar datos del usuario en el widget: $e');
    }
  }

  /// Valida el formato del correo electrónico
  bool _esCorreoValido(String correo) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(correo);
  }

  /// Actualiza el perfil del usuario
  Future<void> _actualizarPerfil() async {
    // Validar campos
    final nuevoNombre = _nombreController.text.trim();
    final nuevoCorreo = _correoController.text.trim();

    // Validar nombre de usuario
    if (nuevoNombre.isEmpty) {
      setState(() {
        _errorNombre = 'El nombre de usuario no puede estar vacío';
      });
      return;
    }

    // Validar correo electrónico
    if (nuevoCorreo.isEmpty) {
      setState(() {
        _errorCorreo = 'El correo electrónico no puede estar vacío';
      });
      return;
    }

    if (!_esCorreoValido(nuevoCorreo)) {
      setState(() {
        _errorCorreo = 'Por favor ingrese un correo electrónico válido';
      });
      return;
    }

    // Verificar conectividad
    final bool tieneConexion = await _connectivityService.hasConnection();
    if (!tieneConexion) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al servicio para actualizar el usuario
      final resultado = await _usuarioService.actualizarUsuario(
        usuarioId: _usuarioId,
        usuario: nuevoNombre,
        persId: _persId,
        roleId: _roleId,
        esAdmin: _esAdmin,
        usuarioModificacion:
            _usuarioId, // El mismo usuario realiza la modificación
        esEmpleado: _esEmpleado,
        correo: nuevoCorreo,
      );

      // Verificar resultado
      if (resultado['success'] == true) {
        // Actualizar datos en el almacenamiento seguro
        await _storage.write(key: 'usuario_nombre', value: nuevoNombre);
        await _storage.write(key: 'usuario_correo', value: nuevoCorreo);

        // Actualizar estado
        if (mounted) {
          setState(() {
            _nombreUsuario = nuevoNombre;
            _correoUsuario = nuevoCorreo;
            _isLoading = false;
          });
        }

        // Cerrar diálogo y mostrar mensaje de éxito
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'Perfil actualizado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Ejecutar callback si existe
        if (widget.onActualizacionExitosa != null) {
          widget.onActualizacionExitosa!();
        }
      } else {
        // Mostrar mensaje de error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'No se pudo actualizar el perfil',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Manejar errores
      debugPrint('Error al actualizar perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error al actualizar tu perfil. Por favor, intenta nuevamente más tarde.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar Perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Avatar con opción para cambiar imagen (funcionalidad futura)
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blue,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Esta función estará disponible próximamente',
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Campo de nombre de usuario
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: _errorNombre,
                ),
                onChanged: (value) {
                  // Limpiar error al escribir
                  if (_errorNombre != null) {
                    setState(() {
                      _errorNombre = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 15),
              // Campo de correo electrónico
              TextField(
                controller: _correoController,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: _errorCorreo,
                ),
                onChanged: (value) {
                  // Limpiar error al escribir
                  if (_errorCorreo != null) {
                    setState(() {
                      _errorCorreo = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _actualizarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Guardar',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Función para mostrar el diálogo de edición de perfil
///
/// Esta función facilita la utilización del widget EditorPerfil
/// desde cualquier parte de la aplicación.
Future<void> mostrarEditorPerfil(
  BuildContext context, {
  Function? onActualizacionExitosa,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) =>
            EditorPerfil(onActualizacionExitosa: onActualizacionExitosa),
  );
}
