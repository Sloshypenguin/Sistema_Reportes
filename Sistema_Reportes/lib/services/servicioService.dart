import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/servicioViewModel.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

class ServicioService {
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Lista todos los servicios disponibles desde la API
  Future<List<Servicio>> listarServicios() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Servicios/Listar');

    print('=== DEBUG LISTAR SERVICIOS ===');
    print('URL: $url');
    print('Headers: ${ApiConfig.headers}');

    final response = await http.get(url, headers: ApiConfig.headers);

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('============================');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // DEBUG: Mostrar toda la estructura de respuesta
        print('Estructura completa de respuesta: $jsonResponse');
        
        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Servicio.fromJson(json)).toList();
        }
        
        // Fallback: Si 'data' no existe, intentar usar directamente la respuesta
        else if (json.decode(response.body) is List) {
          final List<dynamic> data = json.decode(response.body) as List<dynamic>;
          return data.map((json) => Servicio.fromJson(json)).toList();
        }
        
        // Si no tiene la estructura esperada
        else {
          print('Estructura de respuesta inesperada para servicios: $jsonResponse');
          throw Exception('Estructura de respuesta no válida');
        }
        
      } catch (parseError) {
        print('Error al parsear JSON de servicios: $parseError');
        print('Response body: ${response.body}');
        throw Exception('Error al procesar respuesta del servidor: $parseError');
      }
    } else {
      print('Error HTTP al listar servicios: ${response.statusCode}');
      print('Error body: ${response.body}');
      throw Exception("Error al cargar servicios: ${response.statusCode} - ${response.body}");
    }
  }

  /// Obtiene un servicio específico por ID
  Future<Servicio?> obtenerServicioPorId(int servicioId) async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    try {
      final servicios = await listarServicios();
      return servicios.firstWhere(
        (servicio) => servicio.serv_Id == servicioId,
        orElse: () => throw Exception('Servicio no encontrado'),
      );
    } catch (e) {
      print('Error al obtener servicio por ID $servicioId: $e');
      return null;
    }
  }

  /// Obtiene solo los servicios activos (si serv_Estado es true)
  Future<List<Servicio>> listarServiciosActivos() async {
    final servicios = await listarServicios();
    return servicios.where((servicio) => servicio.serv_Estado == true).toList();
  }

  /// Método de conveniencia para verificar si hay servicios disponibles
  Future<bool> hayServiciosDisponibles() async {
    try {
      final servicios = await listarServicios();
      return servicios.isNotEmpty;
    } catch (e) {
      print('Error al verificar disponibilidad de servicios: $e');
      return false;
    }
  }
}