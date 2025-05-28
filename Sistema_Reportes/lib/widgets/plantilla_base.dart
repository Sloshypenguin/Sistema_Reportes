import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login.dart';
import 'editor_perfil.dart';

/// Widget que proporciona la estructura base de la aplicación
/// 
/// Este widget implementa el layout principal de la aplicación, similar
/// a una aplicación Angular, con una barra superior, menú lateral y
/// área de contenido donde se muestran las diferentes páginas.
class PlantillaBase extends StatefulWidget {
  /// Widget hijo que se mostrará en el área de contenido
  final Widget child;
  
  /// Título que se mostrará en la barra superior
  final String titulo;
  
  /// Indica si se debe mostrar el botón de regreso
  final bool mostrarBotonRegresar;
  
  /// Constructor del widget
  const PlantillaBase({
    Key? key,
    required this.child,
    this.titulo = 'Sistema de Reportes',
    this.mostrarBotonRegresar = false,
  }) : super(key: key);

  @override
  State<PlantillaBase> createState() => _PlantillaBaseState();
}

class _PlantillaBaseState extends State<PlantillaBase> {
  final storage = FlutterSecureStorage();
  
  // Datos del usuario
  String nombreUsuario = 'Usuario';
  String rolUsuario = 'Rol no disponible';
  List<dynamic> menuItems = [];
  
  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }
  
  /// Carga los datos del usuario desde el almacenamiento seguro
  Future<void> _cargarDatosUsuario() async {
    try {
      final nombre = await storage.read(key: 'usuario_nombre');
      final rol = await storage.read(key: 'usuario_rol');
      final pantallasJson = await storage.read(key: 'usuario_pantallas');
      
      setState(() {
        nombreUsuario = nombre ?? 'Usuario';
        rolUsuario = rol ?? 'Rol no disponible';
        
        // Parsear las pantallas disponibles si existen
        if (pantallasJson != null && pantallasJson.isNotEmpty) {
          try {
            menuItems = List<dynamic>.from(
              (pantallasJson.startsWith('[') 
                ? json.decode(pantallasJson) 
                : [])
            );
          } catch (e) {
            debugPrint('Error al parsear pantallas: $e');
            menuItems = [];
          }
        }
      });
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }
  
  /// Cierra la sesión del usuario
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (confirmar == true) {
      try {
        // Limpiar datos de sesión
        await storage.deleteAll();
        
        // Limpiar caché de datos
        await _limpiarCacheDatos();
        
        // Navegar a la pantalla de inicio de sesión
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        debugPrint('Error al cerrar sesión: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cerrar sesión. Intente nuevamente.')),
        );
      }
    }
  }
  
  /// Limpia todas las cachés de datos usadas en la aplicación
  Future<void> _limpiarCacheDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Eliminar cachés de estados civiles, departamentos y municipios
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
    }
  }
  
  /// Muestra el diálogo para editar el perfil del usuario
  void _mostrarDialogoEditarPerfil() {
    mostrarEditorPerfil(
      context,
      onActualizacionExitosa: () {
        // Recargar datos del usuario después de una actualización exitosa
        _cargarDatosUsuario();
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        leading: widget.mostrarBotonRegresar 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
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
              itemBuilder: (context) => [
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
                PopupMenuItem(
                  value: 'cerrar_sesion',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Cerrar Sesión'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: menuItems.isNotEmpty ? _construirMenuLateral() : null,
      body: widget.child,
    );
  }
  
  /// Construye el menú lateral con las opciones disponibles para el usuario
  Widget _construirMenuLateral() {
    return Drawer(
      child: Column(
        children: [
          // Encabezado del drawer con información del usuario
          UserAccountsDrawerHeader(
            accountName: Text(
              nombreUsuario,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              rolUsuario,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
          ),
          
          // Lista de opciones del menú
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return ListTile(
                  leading: Icon(
                    _obtenerIcono(item['Pant_Icono'] ?? 'default'),
                    color: Colors.blue.shade700,
                  ),
                  title: Text(item['Pant_Nombre'] ?? 'Opción'),
                  onTap: () {
                    // Cerrar el drawer
                    Navigator.pop(context);
                    
                    // Navegar a la ruta correspondiente
                    // Aquí se implementaría la navegación a la pantalla seleccionada
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navegando a: ${item['Pant_Nombre']}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Pie del drawer con información de la aplicación
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sistema de Reportes v1.0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Obtiene el icono correspondiente a la cadena proporcionada
  IconData _obtenerIcono(String iconoStr) {
    switch (iconoStr.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'person':
        return Icons.person;
      case 'settings':
        return Icons.settings;
      case 'report':
        return Icons.description;
      case 'chart':
        return Icons.bar_chart;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.circle;
    }
  }
}


