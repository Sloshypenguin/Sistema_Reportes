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

  /// Formatea una fecha en formato ISO 8601 UTC
  String _formatearFechaIso(DateTime fecha) {
    final fechaMinSql = DateTime(1753, 1, 1);
    if (fecha.isBefore(fechaMinSql)) {
      return fechaMinSql.toUtc().toIso8601String();
    }
    return fecha.toUtc().toIso8601String(); // Ej: 2025-05-25T22:16:42.710Z
  }

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
    final url = Uri.parse('$_baseUrl/Usuarios/Registrar');

    try {
      final now = DateTime.now();
      final fechaCreacion = _formatearFechaIso(now);

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
        'Pers_FechaCreacion': fechaCreacion,
      };

      final bodyData = {
        'Persona': jsonEncode(personaJson),
        'Usua_Usuario': usuario,
        'Usua_Contrasena': contrasena,
        'Usua_Creacion': usuaCreacion,
        'FechaCreacion': fechaCreacion,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
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

        return {
          'success': false,
          'code_Status': 0,
          'message_Status': 'Respuesta inesperada del servidor: ${response.body}',
        };
      } else {
        return {
          'success': false,
          'code_Status': 0,
          'message_Status': 'Error HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
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
    int usuaCreacion = 1,
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
    final resultado = await registro(
      usuario: usuario,
      contrasena: contrasena,
      usuaCreacion: usuaCreacion,
      dni: dni,
      nombre: nombre,
      apellido: apellido,
      sexo: sexo,
      telefono: telefono,
      correo: correo,
      direccion: direccion,
      municipioCodigo: municipioCodigo,
      estadoCivilId: estadoCivilId,
    );

    final now = DateTime.now();
    final fechaCreacion = _formatearFechaIso(now);

    return Usuario(
      usua_Id: 0,
      usua_Usuario: usuario,
      usua_Contrasena: null,
      pers_Id: 0,
      role_Id: 3,
      usua_EsAdmin: false,
      usua_Creacion: usuaCreacion,
      usua_FechaCreacion: fechaCreacion,
      usua_Modificacion: null,
      usua_FechaModificacion: null,
      usua_Token: null,
      usua_Estado: resultado['success'] == true,
      usua_EsEmpleado: false,
      empleado: null,
      persona: null,
      role_Nombre: null,
      pantallas: null,
      pers_Correo: correo,
      code_Status: resultado['code_Status'],
      message_Status: resultado['message_Status'],
    );
  }
}
