import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio para verificar la conectividad a internet
class ConnectivityService {
  /// Instancia singleton de Connectivity
  final Connectivity _connectivity = Connectivity();
  
  /// Direcciones para probar la conectividad real
  final List<String> _testUrls = [
    'google.com',
    'apple.com',
    'microsoft.com',
  ];

  /// Verifica si el dispositivo tiene alguna conexión a internet
  /// Primero verifica el estado de la conectividad y luego intenta hacer ping a servidores conocidos
  Future<bool> hasConnection() async {
    try {
      // Primero verificamos si hay alguna interfaz de red activa
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      
      // Si no hay ninguna conexión según el sistema, retornamos false inmediatamente
      if (connectivityResult.contains(ConnectivityResult.none) || 
          connectivityResult.isEmpty) {
        print('No hay interfaces de red activas según el sistema');
        return false;
      }
      
      // Si hay alguna interfaz activa, verificamos si realmente hay conexión a internet
      // intentando hacer ping a servidores conocidos
      return await _checkRealConnectivity();
    } catch (e) {
      // En caso de error, intentamos verificar la conectividad real
      print('Error al verificar conectividad: $e');
      return await _checkRealConnectivity();
    }
  }
  
  /// Verifica la conectividad real intentando hacer ping a servidores conocidos
  Future<bool> _checkRealConnectivity() async {
    try {
      // Intentamos hacer ping a varios servidores conocidos
      for (final url in _testUrls) {
        try {
          final result = await InternetAddress.lookup(url);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            print('Conectividad verificada con $url');
            return true;
          }
        } catch (e) {
          print('No se pudo conectar a $url: $e');
          // Continuamos con el siguiente servidor
          continue;
        }
      }
      
      // Si no pudimos conectarnos a ningún servidor, no hay conexión real
      print('No se pudo conectar a ningún servidor de prueba');
      return false;
    } catch (e) {
      print('Error al verificar conectividad real: $e');
      return false;
    }
  }

  /// Obtiene el tipo de conexión actual
  Future<String> getConnectionType() async {
    try {
      // Primero verificamos si realmente hay conexión a internet
      final bool hasInternet = await hasConnection();
      if (!hasInternet) {
        return 'Sin conexión';
      }
      
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return 'Datos móviles';
      } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
        return 'VPN';
      } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
        return 'Bluetooth';
      } else if (connectivityResult.contains(ConnectivityResult.other)) {
        return 'Otra conexión';
      } else {
        return 'Sin conexión';
      }
    } catch (e) {
      print('Error al obtener tipo de conexión: $e');
      return 'Desconocido';
    }
  }
  
  /// Escucha los cambios en la conectividad
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged;
  }
}
