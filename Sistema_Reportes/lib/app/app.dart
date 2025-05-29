import 'package:flutter/material.dart';
import 'rutas.dart';
import 'tema.dart';
import '../services/auth_service.dart';
import '../screens/login.dart';
import '../screens/principal.dart';
import '../layout/plantilla_base.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _verificando = true;
  String _rutaInicial = '/';

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    try {
      final sesionActiva = await AuthService.verificarSesionActiva();
      setState(() {
        _rutaInicial = sesionActiva ? '/principal' : '/';
        _verificando = false;
      });
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
      setState(() {
        _rutaInicial = '/';
        _verificando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si todavía estamos verificando la sesión, mostrar un indicador de carga
    if (_verificando) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaGlobal,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Iniciando aplicación...'),
              ],
            ),
          ),
        ),
      );
    }

    // Una vez verificada la sesión, cargar la aplicación con la ruta inicial adecuada
    return MaterialApp(
      title: 'SIRESP - Sistema de Reportes',
      debugShowCheckedModeBanner: false,
      theme: temaGlobal, // definido en tema.dart
      // Siempre usar el login como pantalla inicial por defecto
      home: const LoginScreen(),
      // Usar onGenerateRoute para manejar todas las rutas, incluyendo la inicial
      onGenerateRoute: (settings) {
        // Si hay una sesión activa y estamos en la ruta inicial, redirigir a principal
        if (_rutaInicial == '/principal' && settings.name == '/') {
          return MaterialPageRoute(
            builder: (_) => const PlantillaBase(
              titulo: 'Página Principal',
              mostrarBotonRegresar: false,
              child: PrincipalScreen(),
            ),
          );
        }
        // Para todas las demás rutas, usar el generador de rutas normal
        return generarRuta(settings);
      },
    );
  }
}
