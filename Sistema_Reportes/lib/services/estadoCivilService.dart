import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estadoCivilViewModel.dart';
import '../models/apiResponse.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

/// Servicio para manejar operaciones relacionadas con estados civiles
class EstadoCivilService {
  /// Servicio para verificar la conectividad a internet
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Obtiene la lista de todos los estados civiles
  /// 
  /// @return Lista de objetos EstadoCivil
  Future<List<EstadoCivil>> listar() async {
    // Verificar conectividad antes de realizar la solicitud - con doble verificación
    // para asegurar que detectamos correctamente cuando se recupera la conexión
    bool hasConnection = false;
    
    // Primer intento
    hasConnection = await _connectivityService.hasConnection();
    
    // Si no hay conexión, esperamos un momento y volvemos a verificar
    // (esto ayuda en casos donde la conexión se acaba de recuperar)
    if (!hasConnection) {
      await Future.delayed(const Duration(milliseconds: 500));
      hasConnection = await _connectivityService.hasConnection();
    }
    
    if (!hasConnection) {
      // Registrar el error para depuración interna
      print('No hay conexión a internet al intentar listar estados civiles');
      // Lanzar una excepción con mensaje amigable para el usuario
      throw Exception('No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.');
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/EstadosCiviles/Listar');
    
    try {
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        final apiResponse = ApiResponse<EstadoCivil>.fromJson(
          jsonMap,
          (json) => EstadoCivil.fromJson(json),
        );

        return apiResponse.data;
      } else {
        throw Exception('Error en el Servidor: ${response.statusCode}');
      }
    } catch (e) {
      // Registrar el error para depuración interna
      print('Error técnico al obtener estados civiles: ${e.toString()}');
      // Lanzar una excepción con mensaje amigable para el usuario
      throw Exception('No se pudieron cargar las opciones de estado civil.');
    }
  }

  /// Obtiene un estado civil por su ID
  /// 
  /// @param id ID del estado civil a buscar
  /// @return Objeto EstadoCivil si se encuentra, null en caso contrario
  Future<EstadoCivil?> obtenerPorId(int id) async {
    // Verificar conectividad antes de realizar la solicitud - con doble verificación
    // para asegurar que detectamos correctamente cuando se recupera la conexión
    bool hasConnection = false;
    
    // Primer intento
    hasConnection = await _connectivityService.hasConnection();
    
    // Si no hay conexión, esperamos un momento y volvemos a verificar
    // (esto ayuda en casos donde la conexión se acaba de recuperar)
    if (!hasConnection) {
      await Future.delayed(const Duration(milliseconds: 500));
      hasConnection = await _connectivityService.hasConnection();
    }
    
    if (!hasConnection) {
      // Registrar el error para depuración interna
      print('No hay conexión a internet al intentar obtener estado civil por ID');
      // Lanzar una excepción con mensaje amigable para el usuario
      throw Exception('No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.');
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/EstadosCiviles/Find?id=$id');
    
    try {
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        final apiResponse = ApiResponse<EstadoCivil>.fromJson(
          jsonMap,
          (json) => EstadoCivil.fromJson(json),
        );

        if (apiResponse.data.isEmpty) return null;

        return apiResponse.data.first;
      } else {
        // Registrar el error técnico internamente
        print('Error en el Servidor: ${response.statusCode}');
        throw Exception('No se pudo obtener la información solicitada.');
      }
    } catch (e) {
      // Registrar el error técnico internamente
      print('Error técnico al obtener estado civil: ${e.toString()}');
      throw Exception('No se pudo obtener la información del estado civil.');
    }
  }

  /// Convierte una lista de estados civiles a un formato adecuado para dropdowns
  /// 
  /// @param estadosCiviles Lista de objetos EstadoCivil
  /// @return Lista de mapas con valores y textos para usar en dropdowns
  List<Map<String, dynamic>> convertirAOpcionesDropdown(List<EstadoCivil> estadosCiviles) {
    final opciones = <Map<String, dynamic>>[];
    
    // Opción por defecto
    opciones.add({'valor': 0, 'texto': 'Seleccione una opción'});
    
    // Agregar cada estado civil como una opción
    for (var estadoCivil in estadosCiviles) {
      opciones.add({
        'valor': estadoCivil.esCi_Id,
        'texto': estadoCivil.esCi_Nombre,
      });
    }
    
    return opciones;
  }
}
