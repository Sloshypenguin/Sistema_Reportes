import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  Future<void> _cerrarSesion() async {
    try {
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

      if (confirmar != true) return;

      await storage.deleteAll();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print('Error al cerrar sesión: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla Principal')),
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
