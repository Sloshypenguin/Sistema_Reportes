import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:http/http.dart' as http;
import '../models/reporteDetalleViewModel.dart';
import '../models/apiResponse.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

/// Servicio para manejar operaciones relacionadas con los detalles del reporte
class ReporteDetalleService {
  /// Servicio para verificar la conectividad a internet
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Obtiene los detalles de un reporte específico por su ID
  Future<List<ReporteDetalle>> listarPorReporte(int repoId) async {
    bool hasConnection = await _connectivityService.hasConnection();

    if (!hasConnection) {
      await Future.delayed(const Duration(milliseconds: 500));
      hasConnection = await _connectivityService.hasConnection();
    }

    if (!hasConnection) {
      print(
        'No hay conexión a internet al intentar obtener detalles del reporte con ID: $repoId',
      );
      throw Exception(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/ReporteDetalle/ListarPorReporte/$repoId',
    );

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        final apiResponse = ApiResponse<ReporteDetalle>.fromJson(
          jsonMap,
          (json) => ReporteDetalle.fromJson(json),
        );

        return apiResponse.data;
      } else {
        print('Error en el Servidor: ${response.statusCode}');
        throw Exception('No se pudieron cargar los detalles del reporte.');
      }
    } catch (e) {
      print('Error técnico al obtener detalles del reporte: ${e.toString()}');
      throw Exception(
        'Ocurrió un error técnico al intentar obtener los detalles del reporte.',
      );
    }
  }

  /// Inserta una nueva observación al reporte
  Future<Map<String, dynamic>> insertarObservacion(
    int repoId,
    String observacion,
    int usuaCreacion,
  ) async {
    bool hasConnection = await _connectivityService.hasConnection();

    if (!hasConnection) {
      await Future.delayed(const Duration(milliseconds: 500));
      hasConnection = await _connectivityService.hasConnection();
    }

    if (!hasConnection) {
      print(
        'No hay conexión a internet al intentar insertar observación para el reporte ID: $repoId',
      );
      throw Exception(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/ReporteDetalle/Insertar');

    final body = jsonEncode({
      'repo_Id': repoId,
      'rdet_Observacion': observacion,
      'usua_Creacion': usuaCreacion,
    });

    // === DEBUG ===
    debugPrint('=== REQUEST DEBUG ===');
    debugPrint('URL: $url');
    debugPrint('Headers: ${ApiConfig.headers}');
    debugPrint('Body: $body');
    debugPrint('=====================');

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: body,
      );

      // === DEBUG ===
      debugPrint('=== RESPONSE DEBUG ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('=======================');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        return {
          'success': jsonMap['code_Status'] == 1,
          'message': jsonMap['message_Status'] ?? 'Operación completada',
        };
      } else {
        return {
          'success': false,
          'message': 'Error del servidor al insertar la observación.',
        };
      }
    } catch (e) {
      print('Error técnico al insertar observación: ${e.toString()}');
      throw Exception(
        'Ocurrió un error técnico al intentar insertar la observación.',
      );
    }
  }
}
