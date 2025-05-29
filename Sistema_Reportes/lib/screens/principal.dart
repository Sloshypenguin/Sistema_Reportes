import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/auth_service.dart';
import '../widgets/widgets.dart';

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  final _storage = FlutterSecureStorage();

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

  Future<void> _cargarDatosUsuario() async {
    try {
      final nombre = await _storage.read(key: 'usuario_nombre');
      final rol = await _storage.read(key: 'usuario_rol');
      final correo = await _storage.read(key: 'usuario_correo');
      final idStr = await _storage.read(key: 'usuario_id');
      final persIdStr = await _storage.read(key: 'pers_id');
      final roleIdStr = await _storage.read(key: 'role_id');
      final esAdminStr = await _storage.read(key: 'usuario_es_admin');
      final esEmpleadoStr = await _storage.read(key: 'usuario_es_empleado');

      setState(() {
        nombreUsuario = nombre ?? 'Usuario';
        correoUsuario = correo ?? '';
        rolUsuario = rol ?? 'Rol no disponible';
        usuarioId = int.tryParse(idStr ?? '') ?? 0;
        persId = int.tryParse(persIdStr ?? '') ?? 0;
        roleId = int.tryParse(roleIdStr ?? '') ?? 0;
        esAdmin = esAdminStr == 'true';
        esEmpleado = esEmpleadoStr == 'true';
      });
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }

  Future<void> _cerrarSesion() async {
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

    // Encontrar el ScaffoldMessenger más cercano usando el contexto de la PlantillaBase
    // En lugar de mostrar un SnackBar, podemos usar un mensaje de depuración
    debugPrint('Cerrando sesión...');
    
    // O podemos pasar un callback a la PlantillaBase para mostrar mensajes
    // Esto sería una mejora futura

    await AuthService.cerrarSesion();
    await _limpiarCacheDatos();

    if (!mounted) return;

    // Usar pushNamedAndRemoveUntil para eliminar todas las rutas anteriores
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _limpiarCacheDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const kEstadosCivilesKey = 'estados_civiles_cache';
      const kDepartamentosKey = 'departamentos_cache';
      const kCacheExpiryKey = 'cache_expiry_timestamp';
      const kMunicipiosPrefixKey = 'municipios_';

      await prefs.remove(kEstadosCivilesKey);
      await prefs.remove(kDepartamentosKey);
      await prefs.remove(kCacheExpiryKey);

      for (final key in prefs.getKeys()) {
        if (key.startsWith(kMunicipiosPrefixKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error al limpiar caché: $e');
    }
  }

  void _mostrarDialogoEditarPerfil() {
    if (usuarioId == 0 || persId == 0 || roleId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar los datos del usuario.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    mostrarEditorPerfil(context, onActualizacionExitosa: _cargarDatosUsuario);
  }

  @override
  Widget build(BuildContext context) {
    // SOLO el contenido interno, sin Scaffold ni AppBar ni Drawer
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¡Bienvenido, $nombreUsuario!',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Text('Rol: $rolUsuario', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.person),
            label: const Text('Editar Perfil'),
            onPressed: _mostrarDialogoEditarPerfil,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
    );
  }
}
