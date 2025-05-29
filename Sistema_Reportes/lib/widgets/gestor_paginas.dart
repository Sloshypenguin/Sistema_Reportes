import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../layout/plantilla_base.dart';
import '../screens/login.dart';
import '../screens/principal.dart';

/// Widget que gestiona la navegación entre páginas de la aplicación
/// 
/// Este widget funciona como un enrutador similar a Angular, permitiendo
/// cargar diferentes páginas dentro de la plantilla base según la ruta.
class GestorPaginas extends StatefulWidget {
  /// Ruta inicial a mostrar
  final String rutaInicial;
  
  /// Constructor del widget
  const GestorPaginas({
    Key? key,
    this.rutaInicial = '/',
  }) : super(key: key);

  @override
  State<GestorPaginas> createState() => _GestorPaginasState();
}

class _GestorPaginasState extends State<GestorPaginas> {
  String _rutaActual = '/';
  bool _sesionIniciada = false;
  
  // Almacena los parámetros de navegación para cada ruta
  final Map<String, Map<String, dynamic>> _parametrosPorRuta = {};
  
  @override
  void initState() {
    super.initState();
    _rutaActual = widget.rutaInicial;
    _verificarSesion();
  }
  
  /// Verifica si hay una sesión activa
  Future<void> _verificarSesion() async {
    try {
      final sesionActiva = await AuthService.verificarSesionActiva();
      setState(() {
        _sesionIniciada = sesionActiva;
        
        // Si no hay sesión, redirigir a login
        if (!_sesionIniciada && _rutaActual != '/login') {
          _navegar('/login');
        }
      });
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
      setState(() {
        _sesionIniciada = false;
      });
      _navegar('/login');
    }
  }
  
  /// Navega a una nueva ruta
  void _navegar(String ruta, {Map<String, dynamic>? parametros}) {
    setState(() {
      _rutaActual = ruta;
      _parametrosPorRuta[ruta] = parametros ?? {};
    });
  }
  
  /// Obtiene el widget correspondiente a la ruta actual
  Widget _obtenerPagina() {
    // Obtener los parámetros de la ruta actual
    final parametros = _parametrosPorRuta[_rutaActual] ?? {};
    
    // Si no hay sesión iniciada, mostrar login
    if (!_sesionIniciada && _rutaActual != '/login') {
      return const LoginScreen();
    }
    
    // Determinar la página según la ruta
    switch (_rutaActual) {
      case '/login':
        return const LoginScreen();
      case '/':
      case '/principal':
        return const PrincipalScreen();
      // Aquí se añadirían más rutas según se vayan creando las páginas
      default:
        // Si la ruta no existe, mostrar página de error 404
        return _construirPagina404();
    }
  }
  
  /// Construye una página de error 404
  Widget _construirPagina404() {
    return PlantillaBase(
      titulo: 'Página no encontrada',
      mostrarBotonRegresar: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Página no encontrada',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navegar('/principal'),
              child: const Text('Ir a la página principal'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final Widget pagina = _obtenerPagina();
    
    // Si es la pantalla de login, mostrarla directamente sin la plantilla base
    if (_rutaActual == '/login') {
      return pagina;
    }
    
    // Para otras rutas, envolver la página en la plantilla base
    return PlantillaBase(
      titulo: _obtenerTituloPagina(),
      mostrarBotonRegresar: _rutaActual != '/' && _rutaActual != '/principal',
      child: pagina,
    );
  }
  
  /// Obtiene el título de la página actual
  String _obtenerTituloPagina() {
    switch (_rutaActual) {
      case '/':
      case '/principal':
        return 'Página Principal';
      // Añadir más casos según se agreguen rutas
      default:
        return 'Sistema de Reportes';
    }
  }
}

/// Clase que proporciona funciones de navegación globales
class Navegador {
  /// Instancia del estado del gestor de páginas
  static _GestorPaginasState? _instancia;
  
  /// Establece la instancia del estado
  static void establecerInstancia(_GestorPaginasState instancia) {
    _instancia = instancia;
  }
  
  /// Navega a una nueva ruta
  static void navegar(String ruta, {Map<String, dynamic>? parametros}) {
    if (_instancia != null) {
      _instancia!._navegar(ruta, parametros: parametros);
    } else {
      debugPrint('Error: Navegador no inicializado');
    }
  }
}
