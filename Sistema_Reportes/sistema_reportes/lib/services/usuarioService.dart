import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuarioViewModel.dart';
import '../models/apiResponse.dart';

/// Servicio para manejar operaciones relacionadas con usuarios
class UsuarioService {
  /// URL base del servidor API
  final String _baseUrl = 'http://sistemareportesgob.somee.com';
  
  /// Clave API para autenticación con el servidor
  final String _apiKey = 'bdccf3f3-d486-4e1e-ab44-74081aefcdbc';

  /// Autentica a un usuario con sus credenciales
  Future<Usuario?> login(String usuario, String contrasena) async {
    final url = Uri.parse('$_baseUrl/Usuarios/Login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
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
      throw Exception('Error en el Servidor: ${response.statusCode}');
    }
  }
  
  /// Registra un nuevo usuario en el sistema - VERSIÓN CON DEBUG MEJORADO
  Future<Map<String, dynamic>> registro({
    required String usuario,
    required String contrasena,
    required int persId,
    int roleId = 1,
    int usuaCreacion = 1,
    bool esAdmin = false,
    bool esEmpleado = false,
  }) async {
    final url = Uri.parse('$_baseUrl/Usuarios/Insertar');

    try {
      // Debug: Imprimir los datos que se envían
      final bodyData = {
        'usua_Usuario': usuario,
        'usua_Contrasena': contrasena,
        'pers_Id': persId,
        'role_Id': roleId,
        'usua_Creacion': usuaCreacion,
        'usua_FechaCreacion': DateTime.now().toIso8601String(),
        'usua_EsAdmin': esAdmin,
        'usua_EsEmpleado': esEmpleado,
      };
      
      print('=== DEBUG REGISTRO ===');
      print('URL: $url');
      print('Body enviado: ${jsonEncode(bodyData)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
        body: jsonEncode(bodyData),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        print('JSON decodificado: $jsonMap');

        // Estructura del swagger: { "code": 200, "success": true, "message": "...", "data": { "code_Status": 1, "message_Status": "..." } }
        if (jsonMap.containsKey('data')) {
          final data = jsonMap['data'] ?? {};
          
          // Priorizar code_Status y message_Status (del SP)
          final codeStatus = data['code_Status'] ?? data['codeStatus'] ?? 0;
          final messageStatus = data['message_Status'] ?? data['messageStatus'] ?? 'Sin mensaje';
          
          return {
            'success': codeStatus == 1,
            'code_Status': codeStatus,
            'message_Status': messageStatus,
          };
        }

        // Fallback: si la respuesta viene directamente (sin wrapper "data")
        if (jsonMap.containsKey('code_Status') && jsonMap.containsKey('message_Status')) {
          return {
            'success': jsonMap['code_Status'] == 1,
            'code_Status': jsonMap['code_Status'] ?? 0,
            'message_Status': jsonMap['message_Status'] ?? 'Sin mensaje',
          };
        }

        // Si no se puede parsear, devolver error
        return {
          'success': false,
          'code_Status': 0,
          'message_Status': 'Respuesta del servidor no reconocida: ${response.body}',
        };

      } else {
        return {
          'success': false,
          'code_Status': 0,
          'message_Status': 'Error HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('=== ERROR EN REGISTRO ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      
      return {
        'success': false,
        'code_Status': 0,
        'message_Status': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  /// Método alternativo que devuelve un objeto Usuario con la respuesta del registro
  Future<Usuario> registroUsuario({
    required String usuario,
    required String contrasena,
    required int persId,
    int roleId = 1,
    int usuaCreacion = 1,
    bool esAdmin = false,
    bool esEmpleado = false,
  }) async {
    final resultado = await registro(
      usuario: usuario,
      contrasena: contrasena,
      persId: persId,
      roleId: roleId,
      usuaCreacion: usuaCreacion,
      esAdmin: esAdmin,
      esEmpleado: esEmpleado,
    );

    // Crear un objeto Usuario con la respuesta del registro
    return Usuario(
      usua_Id: 0, // El SP no devuelve el ID generado
      usua_Usuario: usuario,
      usua_Contrasena: null, // No devolver la contraseña por seguridad
      pers_Id: persId,
      role_Id: roleId,
      usua_EsAdmin: esAdmin,
      usua_Creacion: usuaCreacion,
      usua_FechaCreacion: DateTime.now().toIso8601String(),
      usua_Modificacion: null,
      usua_FechaModificacion: null,
      usua_Token: null,
      usua_Estado: resultado['success'] == true,
      usua_EsEmpleado: esEmpleado,
      empleado: null,
      role_Nombre: null,
      pantallas: null,
      pers_Correo: null,
      code_Status: resultado['code_Status'],
      message_Status: resultado['message_Status'],
    );
  }
}