import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login.dart';

class principalScreen extends StatefulWidget {
  const principalScreen({super.key});

  @override
  State<principalScreen> createState() => _principalScreenState();
}

class _principalScreenState extends State<principalScreen> {
  final storage = FlutterSecureStorage();
  String nombreUsuario = 'Usuario';
  String rolUsuario = 'Rol no disponible';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Cargar datos del usuario desde el almacenamiento seguro
  Future<void> _cargarDatosUsuario() async {
    try {
      final nombre = await storage.read(key: 'usuario_nombre');
      final rol = await storage.read(key: 'usuario_rol');
      final empleado = await storage.read(key: 'usuario_empleado');

      setState(() {
        nombreUsuario = empleado ?? nombre ?? 'Usuario';
        rolUsuario = rol ?? 'Rol no disponible';
      });
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
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

  // Método para mostrar el diálogo de edición de perfil
  void _mostrarDialogoEditarPerfil() {
    // Controladores para los campos de texto
    final nombreController = TextEditingController(text: nombreUsuario);
    final correoController = TextEditingController(text: rolUsuario);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar Perfil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),  
                  const SizedBox(height: 20),
                  // Avatar con opción para cambiar imagen
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
                            // Aquí iría la lógica para cambiar la imagen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cambiar imagen de perfil'),
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
                  // Campo de nombre
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Campo de correo
                  TextField(
                    controller: correoController,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Aquí iría la lógica para guardar los cambios
                          setState(() {
                            nombreUsuario = nombreController.text;
                            rolUsuario = correoController.text;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Perfil actualizado correctamente'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
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
