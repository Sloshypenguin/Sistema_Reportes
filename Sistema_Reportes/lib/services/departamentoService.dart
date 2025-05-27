import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/departamentoViewModel.dart';
import '../models/apiResponse.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

/// Servicio para manejar operaciones relacionadas con departamentos
class DepartamentoService {
  /// Servicio para verificar la conectividad a internet
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Obtiene la lista de todos los departamentos
  ///
  /// @return Lista de objetos Departamento
  Future<List<Departamento>> listar() async {
    bool hasConnection = await _connectivityService.hasConnection();

    if (!hasConnection) {
      await Future.delayed(const Duration(milliseconds: 500));
      hasConnection = await _connectivityService.hasConnection();
    }

    if (!hasConnection) {
      print('No hay conexión a internet al intentar listar departamentos');
      throw Exception('No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Departamentos/Listar');

    try {
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        final apiResponse = ApiResponse<Departamento>.fromJson(
          jsonMap,
          (json) => Departamento.fromJson(json),
        );

        return apiResponse.data;
      } else {
        throw Exception('Error en el Servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error técnico al obtener departamentos: ${e.toString()}');
      throw Exception('No se pudieron cargar las opciones de departamentos.');
    }
  }

  /// Obtiene un departamento por su código
  ///
  /// @param codigo Código del departamento a buscar
  /// @return Objeto Departamento si se encuentra, null en caso contrario
  Future<Departamento?> obtenerPorCodigo(String codigo) async {
    bool hasConnection = await _connectivityService.hasConnection();

    if (!hasConnection) {
      await Future.delayed(const Duration(milliseconds: 500));
      hasConnection = await _connectivityService.hasConnection();
    }

    if (!hasConnection) {
      print('No hay conexión a internet al intentar obtener departamento por código');
      throw Exception('No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Departamentos/Find?codigo=$codigo');

    try {
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        final apiResponse = ApiResponse<Departamento>.fromJson(
          jsonMap,
          (json) => Departamento.fromJson(json),
        );

        if (apiResponse.data.isEmpty) return null;

        return apiResponse.data.first;
      } else {
        print('Error en el Servidor: ${response.statusCode}');
        throw Exception('No se pudo obtener la información solicitada.');
      }
    } catch (e) {
      print('Error técnico al obtener departamento: ${e.toString()}');
      throw Exception('No se pudo obtener la información del departamento.');
    }
  }

  /// Convierte una lista de departamentos a un formato adecuado para dropdowns
  ///
  /// @param departamentos Lista de objetos Departamento
  /// @return Lista de mapas con valores y textos para usar en dropdowns
  List<Map<String, dynamic>> convertirAOpcionesDropdown(List<Departamento> departamentos) {
    final opciones = <Map<String, dynamic>>[];

    opciones.add({'valor': '', 'texto': 'Seleccione un departamento'});

    for (var departamento in departamentos) {
      opciones.add({
        'valor': departamento.depa_Codigo,
        'texto': departamento.depa_Nombre,
      });
    }

    return opciones;
  }
}
