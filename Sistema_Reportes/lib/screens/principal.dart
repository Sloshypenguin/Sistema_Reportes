import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login.dart';
import '../services/usuarioService.dart';
import '../services/connectivityService.dart';

class principalScreen extends StatefulWidget {
  const principalScreen({super.key});

  @override
  State<principalScreen> createState() => _principalScreenState();
}

class _principalScreenState extends State<principalScreen> {
  final storage = FlutterSecureStorage();
  final UsuarioService _usuarioService = UsuarioService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Datos del usuario
  String nombreUsuario = 'Usuario';
  String correoUsuario = '';
  String rolUsuario = 'Rol no disponible';
  int usuarioId = 0;
  int persId = 0;
  int roleId = 0;
  bool esAdmin = false;
  bool esEmpleado = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  /// Carga los datos del usuario desde el almacenamiento seguro
  /// 
  /// Obtiene toda la información necesaria para mostrar en la interfaz
  /// y para realizar operaciones como actualizar el perfil.
  Future<void> _cargarDatosUsuario() async {
    try {
      // Cargar datos básicos del usuario
      final nombre = await storage.read(key: 'usuario_nombre');
      final rol = await storage.read(key: 'usuario_rol');
      final correo = await storage.read(key: 'usuario_correo');
      final idStr = await storage.read(key: 'usuario_id');
      final persIdStr = await storage.read(key: 'pers_id');
      final roleIdStr = await storage.read(key: 'role_id');
      final esAdminStr = await storage.read(key: 'usuario_es_admin');
      final esEmpleadoStr = await storage.read(key: 'usuario_es_empleado');
      
      // Actualizar el estado con los datos obtenidos
      setState(() {
        nombreUsuario = nombre ?? 'Usuario';
        correoUsuario = correo ?? '';
        rolUsuario = rol ?? 'Rol no disponible';
        
        // Convertir valores numéricos y booleanos
        usuarioId = idStr != null ? int.tryParse(idStr) ?? 0 : 0;
        persId = persIdStr != null ? int.tryParse(persIdStr) ?? 0 : 0;
        roleId = roleIdStr != null ? int.tryParse(roleIdStr) ?? 0 : 0;
        esAdmin = esAdminStr == 'true';
        esEmpleado = esEmpleadoStr == 'true';
      });
      
      debugPrint('Datos del usuario cargados correctamente');
      debugPrint('Usuario ID: $usuarioId, Nombre: $nombreUsuario, Correo: $correoUsuario');
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }

  /// Cierra la sesión del usuario y limpia todas las cachés
  ///
  /// Este método:
  /// 1. Solicita confirmación al usuario
  /// 2. Elimina todos los datos de sesión del almacenamiento seguro
  /// 3. Limpia las cachés de estados civiles, departamentos y municipios
  /// 4. Navega de vuelta a la pantalla de inicio de sesión
  Future<void> _cerrarSesion() async {
    try {
      // Solicitar confirmación al usuario
      final confirmar = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cerrar sesión'),
              content: const Text('¿Está seguro que desea cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
      );

      // Si el usuario cancela, no hacer nada
      if (confirmar != true) return;

      // Mostrar indicador de progreso
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cerrando sesión...')));
      }

      // 1. Eliminar datos de sesión del almacenamiento seguro
      await storage.deleteAll();

      // 2. Limpiar cachés de datos
      // Limpiar caché de estados civiles, departamentos y municipios
      await _limpiarCacheDatos();

      // Verificar que el widget siga montado antes de navegar
      if (!mounted) return;

      // 3. Navegar a la pantalla de login
      // Usamos Future.microtask para asegurar que la navegación ocurra
      // fuera del ciclo actual de construcción y evitar errores
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      });
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión. Intente nuevamente.')),
      );
    }
  }

  /// Limpia todas las cachés de datos usadas en la aplicación
  Future<void> _limpiarCacheDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Eliminar cachés de estados civiles, departamentos y municipios
      // Usamos las mismas claves definidas en Registrarse.dart
      const String kEstadosCivilesKey = 'estados_civiles_cache';
      const String kDepartamentosKey = 'departamentos_cache';
      const String kCacheExpiryKey = 'cache_expiry_timestamp';
      const String kMunicipiosPrefixKey = 'municipios_';

      // Eliminar todas las claves relacionadas con nuestra caché
      await prefs.remove(kEstadosCivilesKey);
      await prefs.remove(kDepartamentosKey);
      await prefs.remove(kCacheExpiryKey);

      // Eliminar todas las claves de municipios (pueden ser múltiples)
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(kMunicipiosPrefixKey)) {
          await prefs.remove(key);
        }
      }

      debugPrint('Caché limpiada correctamente');
    } catch (e) {
      debugPrint('Error al limpiar caché: $e');
      // No propagamos el error para no interrumpir el cierre de sesión
    }
  }

  /// Muestra un diálogo para editar el perfil del usuario
  /// 
  /// Permite al usuario editar su nombre de usuario y correo electrónico.
  /// Realiza validaciones básicas y envía los datos al servidor mediante
  /// el servicio de usuario.
  void _mostrarDialogoEditarPerfil() {
    // Verificar si tenemos los datos necesarios
    if (usuarioId == 0 || persId == 0 || roleId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar los datos del usuario. Intente nuevamente más tarde.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Controladores para los campos de texto
    final nombreController = TextEditingController(text: nombreUsuario);
    final correoController = TextEditingController(text: correoUsuario);
    
    // Variables para controlar el estado de carga y errores
    bool isLoading = false;
    String? errorNombre;
    String? errorCorreo;
    
    // Función para validar el correo electrónico
    bool _esCorreoValido(String correo) {
      final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      return emailRegex.hasMatch(correo);
    }
    
    // Función para actualizar el perfil
    Future<void> _actualizarPerfil(BuildContext dialogContext) async {
      // Validar campos
      final nuevoNombre = nombreController.text.trim();
      final nuevoCorreo = correoController.text.trim();
      
      // Validar nombre de usuario
      if (nuevoNombre.isEmpty) {
        setState(() {
          errorNombre = 'El nombre de usuario no puede estar vacío';
        });
        return;
      }
      
      // Validar correo electrónico
      if (nuevoCorreo.isEmpty) {
        setState(() {
          errorCorreo = 'El correo electrónico no puede estar vacío';
        });
        return;
      }
      
      if (!_esCorreoValido(nuevoCorreo)) {
        setState(() {
          errorCorreo = 'Por favor ingrese un correo electrónico válido';
        });
        return;
      }
      
      // Verificar conectividad
      final bool tieneConexion = await _connectivityService.hasConnection();
      if (!tieneConexion) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Mostrar indicador de carga
      setState(() {
        isLoading = true;
      });
      
      try {
        // Llamar al servicio para actualizar el usuario
        final resultado = await _usuarioService.actualizarUsuario(
          usuarioId: usuarioId,
          usuario: nuevoNombre,
          persId: persId,
          roleId: roleId,
          esAdmin: esAdmin,
          usuarioModificacion: usuarioId, // El mismo usuario realiza la modificación
          esEmpleado: esEmpleado,
          correo: nuevoCorreo,
        );
        
        // Verificar resultado
        if (resultado['success'] == true) {
          // Actualizar datos en el almacenamiento seguro
          await storage.write(key: 'usuario_nombre', value: nuevoNombre);
          await storage.write(key: 'usuario_correo', value: nuevoCorreo);
          
          // Actualizar estado
          setState(() {
            nombreUsuario = nuevoNombre;
            correoUsuario = nuevoCorreo;
            isLoading = false;
          });
          
          // Cerrar diálogo y mostrar mensaje de éxito
          if (!mounted) return;
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['message'] ?? 'Perfil actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Mostrar mensaje de error
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['message'] ?? 'No se pudo actualizar el perfil'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        // Manejar errores
        debugPrint('Error al actualizar perfil: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un error al actualizar tu perfil. Por favor, intenta nuevamente más tarde.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
    
    // Mostrar el diálogo
    showDialog(
      context: context,
      barrierDismissible: false, // Evitar que se cierre al tocar fuera del diálogo
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    alignment: Alignment.bottomRight,
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta función estará disponible próximamente'),
                              ),
                            );
                          },
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Campo de nombre de usuario
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de usuario',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: errorNombre,
                    ),
                    onChanged: (value) {
                      // Limpiar error al escribir
                      if (errorNombre != null) {
                        setDialogState(() {
                          errorNombre = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  // Campo de correo electrónico
                  TextField(
                    controller: correoController,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: errorCorreo,
                    ),
                    onChanged: (value) {
                      // Limpiar error al escribir
                      if (errorCorreo != null) {
                        setDialogState(() {
                          errorCorreo = null;
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
                        onPressed: isLoading 
                          ? null 
                          : () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isLoading 
                          ? null 
                          : () => _actualizarPerfil(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: isLoading
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla Principal'),
        actions: [
          // Avatar de perfil con menú desplegable
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (value) {
                if (value == 'perfil') {
                  _mostrarDialogoEditarPerfil();
                } else if (value == 'cerrar_sesion') {
                  _cerrarSesion();
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'perfil',
                      child: Row(
                        children: const [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Editar Perfil'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'cerrar_sesion',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 10),
                          Text(
                            'Cerrar Sesión',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  nombreUsuario.isNotEmpty
                      ? nombreUsuario[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.blueAccent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    nombreUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    rolUsuario,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _cerrarSesion();
              },
            ),
          ],
        ),
      ),
      body: const Center(child: Text('¡Bienvenido!')),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'snackbar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This is a snackbar')),
              );
            },
            tooltip: 'Show Snackbar',
            child: const Icon(Icons.add_alert),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'nextpage',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Next page')),
                      body: const Center(
                        child: Text(
                          'This is the next page',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            tooltip: 'Go to the next page',
            child: const Icon(Icons.navigate_next),
          ),
        ],
      ),
    );
  }
}
