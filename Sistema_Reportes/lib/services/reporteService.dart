import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reporteViewModel.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

class ReporteService {
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Obtiene las imágenes asociadas a un reporte específico
  Future<List<Map<String, dynamic>>> obtenerImagenesPorReporte(int repoId) async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/ImagenPorReporte/Listar/$repoId');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') && jsonResponse['success'] == true) {
          final List<dynamic> imagenesData = jsonResponse['data'];
          return List<Map<String, dynamic>>.from(imagenesData);
        } else {
          // Si no hay imágenes o la estructura es diferente
          return [];
        }
      } else {
        print('Error al obtener imágenes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Excepción al obtener imágenes: $e');
      return [];
    }
  }

  /// Lista los reportes asociados a una persona específica
  Future<List<Reporte>> listarReportesPorPersona(int persId) async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Reporte/ListarPorPersona/$persId');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Verificar si la respuesta tiene la estructura anidada esperada
        if (jsonResponse.containsKey('data') && jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          
          // Verificar si data tiene la estructura esperada
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            final List<dynamic> reportesData = data['data'];
            return reportesData.map((json) => Reporte.fromJson(json)).toList();
          }
        }
        
        // Si no hay reportes o la estructura es diferente
        return [];
      } else {
        print('Error al cargar reportes por persona: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Excepción al cargar reportes por persona: $e');
      return [];
    }
  }

  /// Lista todos los reportes disponibles desde la API con paginación
  Future<List<Reporte>> listarReportes({int page = 1, int pageSize = 10}) async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Reporte/Listar');

    final response = await http.get(url, headers: ApiConfig.headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      final List<Reporte> allReportes = data.map((json) => Reporte.fromJson(json)).toList();
      
      // Implementar paginación en el lado del cliente
      // ya que el API no soporta paginación directamente
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize > allReportes.length 
          ? allReportes.length 
          : startIndex + pageSize;
      
      if (startIndex >= allReportes.length) {
        return [];
      }
      
      return allReportes.sublist(startIndex, endIndex);
    } else {
      throw Exception("Error al cargar reportes: ${response.statusCode}");
    }
  }
  
  /// Obtiene el número total de reportes disponibles
  Future<int> obtenerTotalReportes() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Reporte/Listar');

    final response = await http.get(url, headers: ApiConfig.headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.length;
    } else {
      throw Exception("Error al obtener total de reportes: ${response.statusCode}");
    }
  }

  /// Crea un nuevo reporte en la API
  Future<Map<String, dynamic>> crearReporte({
    required int personaId,
    required int servicioId,
    required String descripcion,
    required String ubicacion,
    required bool esPrioritario,
    required int usuarioCreacion,
  }) async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Reporte/Insertar');



    final body = {
      'pers_Id': personaId,
      'serv_Id': servicioId,
      'repo_Descripcion': descripcion,
      'repo_Ubicacion': ubicacion,
      'repo_Prioridad': esPrioritario,
      'usua_Creacion': usuarioCreacion,

    };

    print('=== DEBUG CREAR REPORTE ===');
    print('URL: $url');
    print('Body enviado: ${json.encode(body)}');
    print('Headers: ${ApiConfig.headers}');

    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: json.encode(body),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('========================');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // DEBUG: Mostrar toda la estructura de respuesta
        print('Estructura completa de respuesta: $jsonResponse');
        
        // Manejar la estructura específica de tu API
        // {
        //   "code": 200,
        //   "success": true,
        //   "message": "Operación completada exitosamente.",
        //   "data": {
        //     "code_Status": 15,
        //     "message_Status": "Reporte registrado correctamente."
        //   }
        // }
        
        if (jsonResponse.containsKey('data') && jsonResponse['data'] != null) {
          final data = jsonResponse['data'] as Map<String, dynamic>;
          final apiSuccess = jsonResponse['success'] ?? false;
          final apiMessage = jsonResponse['message'] ?? 'Operación completada';
          
          // Obtener los valores del SP desde data
          final codeStatus = data['code_Status'] ?? 0;
          final messageStatus = data['message_Status'] ?? 'Reporte procesado';
          
          // El éxito se determina por:
          // 1. La API dice success: true
          // 2. Y el code_Status del SP es mayor a 0 (SCOPE_IDENTITY)
          final operacionExitosa = apiSuccess && codeStatus > 0;
          
          return {
            'success': operacionExitosa,
            'code': codeStatus,
            'message': operacionExitosa ? messageStatus : 'Error en el procesamiento',
            'reporteId': operacionExitosa ? codeStatus : null,
            'apiMessage': apiMessage, // Mensaje de la API
            'spMessage': messageStatus, // Mensaje del SP
          };
        }
        
        // Fallback: Si no tiene la estructura esperada pero success es true
        else if (jsonResponse.containsKey('success') && jsonResponse['success'] == true) {
          return {
            'success': true,
            'code': 1,
            'message': jsonResponse['message'] ?? 'Reporte creado exitosamente',
            'reporteId': null,
          };
        }
        
        // Si llegamos aquí, algo no está bien
        else {
          print('Estructura de respuesta inesperada: $jsonResponse');
          return {
            'success': false,
            'code': 0,
            'message': 'Estructura de respuesta no válida',
            'reporteId': null,
            'rawResponse': jsonResponse,
          };
        }
        
      } catch (parseError) {
        print('Error al parsear JSON: $parseError');
        print('Response body: ${response.body}');
        throw Exception('Error al procesar respuesta del servidor: $parseError');
      }
    } else {
      print('Error HTTP: ${response.statusCode}');
      print('Error body: ${response.body}');
      throw Exception("Error al crear reporte: ${response.statusCode} - ${response.body}");
    }
  }

  /// Versión alternativa del método crearReporte que acepta un objeto Reporte
  Future<Map<String, dynamic>> crearReporteFromObject(Reporte reporte, int usuarioCreacion) async {
    return await crearReporte(
      personaId: reporte.pers_Id,
      servicioId: reporte.serv_Id,
      descripcion: reporte.repo_Descripcion,
      ubicacion: reporte.repo_Ubicacion ?? '',
      esPrioritario: reporte.repo_Prioridad,
      usuarioCreacion: usuarioCreacion,
    );
  }

  /// Método de conveniencia que retorna solo si fue exitoso o no
  Future<bool> crearReporteSimple({
    required int personaId,
    required int servicioId,
    required String descripcion,
    required String ubicacion,
    required bool esPrioritario,
    required int usuarioCreacion,
  }) async {
    final resultado = await crearReporte(
      personaId: personaId,
      servicioId: servicioId,
      descripcion: descripcion,
      ubicacion: ubicacion,
      esPrioritario: esPrioritario,
      usuarioCreacion: usuarioCreacion,
    );
    return resultado['success'] ?? false;
  }

/// Actualiza un reporte existente en la API
Future<Map<String, dynamic>> actualizarReporte({
  required int reporteId,
  required int servicioId,
  required String descripcion,
  required String ubicacion,
  required bool esPrioritario,
  required String estado,
  required int usuarioModificacion,
  required int personaId,
}) async {
  final hasConnection = await _connectivityService.hasConnection();
  if (!hasConnection) {
    throw Exception("Sin conexión a internet");
  }

  final url = Uri.parse('${ApiConfig.baseUrl}/Reporte/Actualizar');

  // Obtener la fecha actual en formato ISO string
  final fechaModificacion = DateTime.now().toIso8601String();

  final body = {
    'repo_Id': reporteId,
    'serv_Id': servicioId,
    'pers_Id': personaId,
    'repo_Descripcion': descripcion,
    'repo_Ubicacion': ubicacion,
    'repo_Prioridad': esPrioritario,
    'repo_Estado': estado,
    'usua_Modificacion': usuarioModificacion,
    'repo_FechaModificacion': fechaModificacion,
  };



  final response = await http.put(
    url,
    headers: ApiConfig.headers,
    body: json.encode(body),
  );



  if (response.statusCode == 200 || response.statusCode == 201) {
    try {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (jsonResponse.containsKey('data') && jsonResponse['data'] != null) {
        final data = jsonResponse['data'] as Map<String, dynamic>;
        final apiSuccess = jsonResponse['success'] ?? false;
        final apiMessage = jsonResponse['message'] ?? 'Operación completada';
        
        // Obtener los valores del SP desde data
        final codeStatus = data['code_Status'] ?? 0;
        final messageStatus = data['message_Status'] ?? 'Reporte procesado';
        
        // El éxito se determina por:
        // 1. La API dice success: true
        // 2. Y el code_Status del SP es 1 (actualización exitosa)
        final operacionExitosa = apiSuccess && codeStatus == 1;
        
        return {
          'success': operacionExitosa,
          'code': codeStatus,
          'message': operacionExitosa ? messageStatus : 'Error en la actualización',
          'apiMessage': apiMessage, // Mensaje de la API
          'spMessage': messageStatus, // Mensaje del SP
        };
      }
      
      // Fallback: Si no tiene la estructura esperada pero success es true
      else if (jsonResponse.containsKey('success') && jsonResponse['success'] == true) {
        return {
          'success': true,
          'code': 1,
          'message': jsonResponse['message'] ?? 'Reporte actualizado exitosamente',
        };
      }
      
      // Si llegamos aquí, algo no está bien
      else {
        print('Estructura de respuesta inesperada: $jsonResponse');
        return {
          'success': false,
          'code': 0,
          'message': 'Estructura de respuesta no válida',
          'rawResponse': jsonResponse,
        };
      }
      
    } catch (parseError) {
      print('Error al parsear JSON: $parseError');
      print('Response body: ${response.body}');
      throw Exception('Error al procesar respuesta del servidor: $parseError');
    }
  } else {
    print('Error HTTP: ${response.statusCode}');
    print('Error body: ${response.body}');
    throw Exception("Error al actualizar reporte: ${response.statusCode} - ${response.body}");
  }
}

/// Versión alternativa del método actualizarReporte que acepta un objeto Reporte
Future<Map<String, dynamic>> actualizarReporteFromObject(Reporte reporte, int usuarioModificacion) async {
  return await actualizarReporte(
    reporteId: reporte.repo_Id,
    servicioId: reporte.serv_Id,
    descripcion: reporte.repo_Descripcion,
    ubicacion: reporte.repo_Ubicacion ?? '',
    esPrioritario: reporte.repo_Prioridad,
    estado: reporte.repo_Estado,
    usuarioModificacion: usuarioModificacion,
    personaId: reporte.pers_Id,
  );
}

/// Método de conveniencia que retorna solo si fue exitoso o no
Future<bool> actualizarReporteSimple({
  required int reporteId,
  required int servicioId,
  required String descripcion,
  required String ubicacion,
  required bool esPrioritario,
  required String estado,
  required int usuarioModificacion,
}) async {
  final resultado = await actualizarReporte(
    reporteId: reporteId,
    servicioId: servicioId,
    descripcion: descripcion,
    ubicacion: ubicacion,
    esPrioritario: esPrioritario,
    estado: estado,
    usuarioModificacion: usuarioModificacion,
    personaId: 1, // Asignar un valor por defecto o pasar el ID de la persona si es necesario
  );
  return resultado['success'] ?? false;
}



}