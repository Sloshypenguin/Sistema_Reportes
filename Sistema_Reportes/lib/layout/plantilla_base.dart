import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PlantillaBase extends StatefulWidget {
  const PlantillaBase({
    super.key,
    required this.child,
    required this.titulo,
    this.mostrarBotonRegresar = false,
  });

  final Widget child;
  final bool mostrarBotonRegresar;
  final String titulo;

  @override
  State<PlantillaBase> createState() => _PlantillaBaseState();
}

class _PlantillaBaseState extends State<PlantillaBase> {
  String nombreUsuario = 'Usuario';
  String rolUsuario = 'Rol';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final nombre = await AuthService.obtenerNombreUsuario() ?? 'Usuario';
    final rol = await AuthService.obtenerRol() ?? 'Rol';

    setState(() {
      nombreUsuario = nombre;
      rolUsuario = rol;
    });
  }

  void _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Deseas cerrar sesión?'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Aceptar'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    final cerradoExitoso = await AuthService.cerrarSesion();

    if (cerradoExitoso && mounted) {
      // Usar la ruta '/login' explícitamente y eliminar todas las rutas anteriores
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIRESP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (value) {
                if (value == 'cerrar') _cerrarSesion();
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'cerrar',
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
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombreUsuario,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    rolUsuario,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/principal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/mi_perfil');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/reportes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.widgets),
              title: const Text('Plantilla Widget'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/plantilla');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _cerrarSesion,
            ),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}
