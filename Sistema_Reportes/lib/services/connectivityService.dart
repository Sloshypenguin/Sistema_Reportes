import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Servicio para verificar la conectividad a internet
class ConnectivityService {
  /// Instancia singleton de Connectivity
  final Connectivity _connectivity = Connectivity();
  
  /// URLs para probar la conectividad real mediante HTTP
  final List<String> _testUrls = [
    'https://www.google.com',
    'https://www.cloudflare.com',
    'https://www.microsoft.com',
  ];

  /// Verifica si el dispositivo tiene alguna conexión a internet
  /// Utiliza diferentes estrategias según la plataforma
  Future<bool> hasConnection() async {
    try {
      if (kIsWeb) {
        // En web, solo probamos contra nuestra API
        print('Verificando conectividad en plataforma web');
        return await _checkRealConnectivity();
      } else {
        // En móvil, verificamos con connectivity_plus + http
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          print('No hay interfaces de red activas según el sistema');
          return false;
        }
        return await _checkRealConnectivity();
      }
    } catch (e) {
      // En caso de error, intentamos verificar la conectividad real directamente
      print('Error al verificar conectividad: $e');
      return await _checkRealConnectivity();
    }
  }
  
  /// Verifica la conectividad real intentando hacer peticiones HTTP a servidores conocidos
  /// Utiliza diferentes estrategias según la plataforma
  Future<bool> _checkRealConnectivity() async {
    try {
      if (kIsWeb) {
        // En web, intentamos conectarnos a nuestro backend primero
        try {
          final apiUrl = 'https://sistema-reportes-api.azurewebsites.net/EstadosCiviles/Listar';
          
          final response = await http.get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 5));
          
          // Si obtenemos cualquier respuesta (incluso un error 401 o 403), significa que hay conexión
          print('Conectividad web verificada con backend: ${response.statusCode}');
          return true;
        } catch (e) {
          print('No se pudo conectar al backend desde web: $e');
          return false; // En web, si no podemos conectar al backend, asumimos que no hay conexión
        }
      } else {
        // En plataformas móviles, intentamos con varios servidores
        for (final url in _testUrls) {
          try {
            final response = await http.get(Uri.parse(url))
                .timeout(const Duration(seconds: 5));
            
            if (response.statusCode == 200) {
              print('Conectividad móvil verificada con $url');
              return true;
            }
          } catch (e) {
            print('No se pudo conectar a $url: $e');
            // Continuamos con el siguiente servidor
            continue;
          }
        }
        
        // Si no pudimos conectarnos a ningún servidor, no hay conexión real
        print('No se pudo conectar a ningún servidor de prueba desde móvil');
        return false;
      }
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
      
      // Luego obtenemos el tipo de conexión
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Manejar el resultado de la conectividad
      if (connectivityResult == ConnectivityResult.mobile) {
        return 'Datos móviles';
      } else if (connectivityResult == ConnectivityResult.wifi) {
        return 'WiFi';
      } else if (connectivityResult == ConnectivityResult.ethernet) {
        return 'Ethernet';
      } else if (connectivityResult == ConnectivityResult.vpn) {
        return 'VPN';
      } else if (connectivityResult == ConnectivityResult.bluetooth) {
        return 'Bluetooth';
      } else if (connectivityResult == ConnectivityResult.other) {
        return 'Otra conexión';
      } else if (connectivityResult == ConnectivityResult.none) {
        return 'Sin conexión';
      } else {
        return 'Desconocido';
      }
    } catch (e) {
      print('Error al obtener tipo de conexión: $e');
      return 'Error';
    }
  }
  
  /// Escucha los cambios en la conectividad
  Stream<ConnectivityResult> get onConnectivityChanged {
    // Creamos un StreamController para transformar el stream
    final controller = StreamController<ConnectivityResult>();
    
    // Nos suscribimos al stream original
    final subscription = _connectivity.onConnectivityChanged.listen((dynamic result) {
      // En web, solo verificamos la conectividad real cuando hay un cambio
      if (kIsWeb) {
        hasConnection().then((hasInternet) {
          if (hasInternet) {
            controller.add(ConnectivityResult.wifi); // En web asumimos WiFi si hay conexión
          } else {
            controller.add(ConnectivityResult.none);
          }
        });
      } else {
        // En móvil, podemos confiar más en el resultado de connectivity_plus
        // pero aún así verificamos la conectividad real para mayor seguridad
        if (result is List<ConnectivityResult>) {
          // Si es una lista, verificamos si contiene alguna conexión activa
          bool hasActiveConnection = false;
          for (var r in result) {
            if (r != ConnectivityResult.none) {
              hasActiveConnection = true;
              break;
            }
          }
          
          if (!hasActiveConnection) {
            controller.add(ConnectivityResult.none);
          } else {
            // Verificamos si realmente hay conexión a internet
            hasConnection().then((hasInternet) {
              if (hasInternet) {
                // Tomamos el primer tipo de conexión que no sea 'none'
                for (var r in result) {
                  if (r != ConnectivityResult.none) {
                    controller.add(r);
                    break;
                  }
                }
              } else {
                controller.add(ConnectivityResult.none);
              }
            });
          }
        } else if (result is ConnectivityResult) {
          // Si es un solo resultado, lo procesamos directamente
          if (result == ConnectivityResult.none) {
            controller.add(ConnectivityResult.none);
          } else {
            // Verificamos si realmente hay conexión a internet
            hasConnection().then((hasInternet) {
              if (hasInternet) {
                controller.add(result); // Usamos el tipo de conexión detectado
              } else {
                controller.add(ConnectivityResult.none);
              }
            });
          }
        } else {
          // Si no podemos determinar el tipo, verificamos la conectividad real
          hasConnection().then((hasInternet) {
            if (hasInternet) {
              controller.add(ConnectivityResult.wifi); // Asumimos WiFi por defecto
            } else {
              controller.add(ConnectivityResult.none);
            }
          });
        }
      }
    });
    
    // Cerramos el controller y cancelamos la suscripción cuando se cierre el stream
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };
    
    return controller.stream;
  }
}
