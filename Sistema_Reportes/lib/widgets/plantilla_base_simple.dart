import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      
      setState(() {
        nombreUsuario = nombre ?? 'Usuario';
        rolUsuario = rol ?? 'Rol no disponible';
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
                child: Text(
                  nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
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
            
            // Opciones del menú
            ListTile(
              leading: Icon(Icons.home, color: Colors.blue.shade700),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: Icon(Icons.description, color: Colors.blue.shade700),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reportes');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blue.shade700),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/configuracion');
              },
            ),
            
            const Spacer(),
            
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
      ),
      body: widget.child,
    );
  }
}
