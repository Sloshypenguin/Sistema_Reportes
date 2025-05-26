import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuarioViewModel.dart';
import '../models/apiResponse.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

/// Servicio para manejar operaciones relacionadas con usuarios
class UsuarioService {
  /// Servicio para verificar la conectividad a internet
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Autentica a un usuario con sus credenciales
  Future<Usuario?> login(String usuario, String contrasena) async {
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
      throw Exception('No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.');
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/Login');
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({
        'usua_Usuario': usuario,
        'usua_Contrasena': contrasena,
      }),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);

      final apiResponse = ApiResponse<Usuario>.fromJson(
        jsonMap,
        (json) => Usuario.fromJson(json),
      );

      if (apiResponse.data.isEmpty) return null;

      return apiResponse.data.first;
    } else {
      // Registrar el error técnico internamente
      print('Error técnico en el servidor: ${response.statusCode}');
      throw Exception('No se pudo iniciar sesión. Por favor, intenta nuevamente.');
    }
  }

  /// Registra un nuevo usuario en el sistema con datos de persona
  Future<Map<String, dynamic>> registro({
    required String usuario,
    required String contrasena,
    int usuaCreacion = 1,

    // Datos de Persona
    required String dni,
    required String nombre,
    required String apellido,
    required String sexo,
    required String telefono,
    required String correo,
    required String direccion,
    required String municipioCodigo,
    required int estadoCivilId,
  }) async {
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
      return {
        'success': false,
        'code_Status': 0,
        'message_Status': 'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      };
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/Registrar');

    try {

      final personaJson = {
        'Pers_DNI': dni,
        'Pers_Nombre': nombre,
        'Pers_Apellido': apellido,
        'Pers_Sexo': sexo,
        'Pers_Telefono': telefono,
        'Pers_Correo': correo,
        'Pers_Direccion': direccion,
        'Muni_Codigo': municipioCodigo,
        'EsCi_Id': estadoCivilId,
        'Pers_Creacion': usuaCreacion,
      };

      final bodyData = {
        'Persona': jsonEncode(personaJson),
        'Usua_Usuario': usuario,
        'Usua_Contrasena': contrasena,
        'Usua_Creacion': usuaCreacion,
      };

      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        if (jsonMap.containsKey('data') && jsonMap['data'] != null) {
          final data = jsonMap['data'];
          final codeStatus = data['code_Status'] ?? data['codeStatus'] ?? 0;
          final messageStatus = data['message_Status'] ?? data['messageStatus'] ?? 'Sin mensaje';

          return {
            'success': codeStatus == 1,
            'code_Status': codeStatus,
            'message_Status': messageStatus,
          };
        }

        if (jsonMap.containsKey('code_Status') && jsonMap.containsKey('message_Status')) {
          return {
            'success': jsonMap['code_Status'] == 1,
            'code_Status': jsonMap['code_Status'],
            'message_Status': jsonMap['message_Status'],
          };
        }

        // Registrar el error técnico internamente
        print('Respuesta inesperada del servidor: ${response.body}');
        return {
          'success': false,
          'code_Status': 0,
          'message_Status': 'No se pudo completar el registro. Por favor, intenta nuevamente más tarde.',
        };
      } else {
        // Registrar el error técnico internamente
        print('Error HTTP ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'code_Status': 0,
          'message_Status': 'No se pudo completar el registro. Por favor, verifica tus datos e intenta nuevamente.',
        };
      }
    } catch (e) {
      // Registrar el error técnico internamente
      print('Error de conexión: ${e.toString()}');
      return {
        'success': false,
        'code_Status': 0,
        'message_Status': 'No se pudo conectar al servidor. Por favor, verifica tu conexión a internet e intenta nuevamente.',
      };
    }
  }
}
