import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sistema_reportes/models/pantallaViewModel.dart';
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
  String? imagenPerfil;
  List<Pantalla> _pantallas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarPantallas();
  }

  Future<void> _cargarPantallas() async {
    final storage = FlutterSecureStorage();
    final pantallasJson = await storage.read(key: 'usuario_pantallas');
    if (pantallasJson != null) {
      final List<dynamic> lista = jsonDecode(pantallasJson);
      setState(() {
        _pantallas = lista.map((item) => Pantalla.fromJson(item)).toList();
      });
    }
  }

  Future<void> _cargarDatosUsuario() async {
    final nombre = await AuthService.obtenerNombreUsuario() ?? 'Usuario';
    final rol = await AuthService.obtenerRol() ?? 'Rol';
    final imagen = await AuthService.obtenerImagenPerfil();
    
    setState(() {
      nombreUsuario = nombre;
      rolUsuario = rol;
      imagenPerfil = imagen;
      
      if (imagenPerfil != null) {
        debugPrint('Imagen de perfil cargada: $imagenPerfil');
      }
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
            child: GestureDetector(
              onTap: () {
                // Navegar a la pantalla "Mi Perfil"
                Navigator.pushNamed(context, '/mi_perfil');
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                // Mostrar imagen de perfil si está disponible, de lo contrario mostrar la inicial del nombre
                backgroundImage: imagenPerfil != null
                    ? NetworkImage('http://sistemareportesgob.somee.com${imagenPerfil}')
                    : null,
                child: imagenPerfil == null
                    ? Text(
                        nombreUsuario.isNotEmpty
                            ? nombreUsuario[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    // Mostrar imagen de perfil si está disponible, de lo contrario mostrar icono de persona
                    backgroundImage: imagenPerfil != null
                        ? NetworkImage('http://sistemareportesgob.somee.com${imagenPerfil}')
                        : null,
                    child: imagenPerfil == null
                        ? const Icon(Icons.person, size: 40, color: Colors.blue)
                        : null,
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
            ..._pantallas.map(
              (pantalla) => ListTile(
                leading: Icon(pantalla.icono),
                title: Text(pantalla.nombre),
                onTap: () {
                  Navigator.pushReplacementNamed(context, pantalla.ruta);
                },
              ),
            ),
            // Opción de Google Maps añadida manualmente
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/google_maps');
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
