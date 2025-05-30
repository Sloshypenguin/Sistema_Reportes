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
      throw Exception(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
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
      throw Exception(
        'No se pudo iniciar sesión. Por favor, intenta nuevamente.',
      );
    }
  }

  /// Verifica si un usuario existe en el sistema
  ///
  /// Retorna el ID del usuario y su correo electrónico si existe
  /// El código de estado puede ser:
  /// - Positivo (>0): ID del usuario (exitoso)
  /// - 0: Error
  /// - -1: Advertencia
  Future<Map<String, dynamic>> verificarUsuario(String usuario) async {
    // Verificar conectividad
    bool hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/Verificar');
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({'usua_Usuario': usuario}),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      final codeStatus = jsonMap['data']['code_Status'] ?? 0;
      final messageStatus = jsonMap['data']['message_Status'] ?? '';

      return {
        'success': jsonMap['success'] ?? false,
        'message': jsonMap['message'] ?? 'Error al verificar usuario',
        'codeStatus': codeStatus,
        'messageStatus': messageStatus,
        'usuarioId':
            codeStatus > 0 ? codeStatus : 0, // Si es positivo, es el ID
        'correo': messageStatus,
      };
    } else {
      throw Exception('Error al verificar usuario: ${response.statusCode}');
    }
  }

  /// Genera un código de restablecimiento para un usuario
  ///
  /// Retorna el token generado
  Future<String> generarCodigoRestablecimiento(int usuarioId) async {
    // Verificar conectividad
    bool hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/Usuarios/GenerarCodigoRestablecimiento',
    );
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({'usua_Id': usuarioId}),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      if (jsonMap['success'] == true) {
        return jsonMap['data']['token'] ?? '';
      } else {
        throw Exception(
          jsonMap['message'] ?? 'Error al generar código de restablecimiento',
        );
      }
    } else {
      throw Exception(
        'Error al generar código de restablecimiento: ${response.statusCode}',
      );
    }
  }

  /// Valida el código de restablecimiento ingresado por el usuario
  ///
  /// Retorna true si el código es válido
  Future<bool> validarCodigo(int usuarioId, String token) async {
    // Verificar conectividad
    bool hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/ValidarCodigo');
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({'usua_Id': usuarioId, 'usua_Token': token}),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      final codeStatus = jsonMap['data']['code_Status'] ?? 0;
      // 1 = éxito, -1 = advertencia, 0 = error
      return codeStatus == 1;
    } else {
      throw Exception('Error al validar código: ${response.statusCode}');
    }
  }

  /// Restablece la contraseña del usuario
  ///
  /// Retorna true si la contraseña se restableció correctamente
  Future<bool> restablecerContrasena(
    int usuarioId,
    String nuevaContrasena,
  ) async {
    // Verificar conectividad
    bool hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception(
        'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/ReestablecerClave');
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({
        'usua_Id': usuarioId,
        'usua_Contrasena': nuevaContrasena,
      }),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      final codeStatus = jsonMap['data']['code_Status'] ?? 0;
      // 1 = éxito, -1 = advertencia, 0 = error
      return codeStatus == 1;
    } else {
      throw Exception(
        'Error al restablecer contraseña: ${response.statusCode}',
      );
    }
  }

  /// Edita el registro completo de un usuario (perfil)
  Future<Map<String, dynamic>> editarRegistro({
    required int usuarioId,
    required Map<String, dynamic> personaData,
    required String usuario,
    String? usua_Imagen,
    required int usuarioModificacion,
  }) async {
    try {
      // Verificar conectividad
      final hasConnection = await _connectivityService.hasConnection();
      if (!hasConnection) {
        return {
          'exito': false,
          'mensaje':
              'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/EditarRegistro');
      final response = await http.put(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'usua_Id': usuarioId,
          'persona': jsonEncode(personaData),
          'usua_Usuario': usuario,
          'usua_Imagen': usua_Imagen,
          'usua_Modificacion': usuarioModificacion,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Verificar si la estructura de la respuesta es la esperada
        if (jsonResponse.containsKey('data')) {
          // Nueva estructura de respuesta
          final data = jsonResponse['data'];
          final codeStatus = data['code_Status'] ?? 0;
          final messageStatus = data['message_Status'] ?? 'Error desconocido';
          
          return {
            'exito': codeStatus == 1,
            'mensaje': messageStatus,
            'codeStatus': codeStatus,
          };
        } else {
          // Estructura antigua por si acaso
          final codeStatus = jsonResponse['code_Status'] ?? 0;
          final messageStatus = jsonResponse['message_Status'] ?? 'Error desconocido';
          
          return {
            'exito': codeStatus == 1,
            'mensaje': messageStatus,
            'codeStatus': codeStatus,
          };
        }
      } else {
        return {
          'exito': false,
          'mensaje': 'Error al actualizar el perfil. Código: ${response.statusCode}',
          'codeStatus': 0,
        };
      }
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error al actualizar el perfil: $e',
        'codeStatus': 0,
      };
    }
  }

  /// Obtiene los detalles de un usuario por su ID
  Future<Map<String, dynamic>> obtenerDetalleUsuario(int usuarioId) async {
    try {
      // Verificar conectividad
      final hasConnection = await _connectivityService.hasConnection();
      if (!hasConnection) {
        return {
          'exito': false,
          'mensaje':
              'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/Detalle');
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({'usua_Id': usuarioId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.isNotEmpty) {
          final usuarioData = jsonResponse[0];

          // Parsear los datos de persona y empleado que vienen como strings JSON
          Map<String, dynamic> personaData = {};
          Map<String, dynamic>? empleadoData;

          if (usuarioData['persona'] != null) {
            personaData = jsonDecode(usuarioData['persona']);
          }

          if (usuarioData['empleado'] != null &&
              usuarioData['empleado'] != 'null') {
            empleadoData = jsonDecode(usuarioData['empleado']);
          }

          return {
            'exito': true,
            'usuario': {
              'usua_Id': usuarioData['usua_Id'],
              'usua_Usuario': usuarioData['usua_Usuario'],
              'pers_Id': usuarioData['pers_Id'],
              'role_Id': usuarioData['role_Id'],
              'role_Nombre': usuarioData['role_Nombre'],
              'usua_EsAdmin': usuarioData['usua_EsAdmin'],
              'usua_EsEmpleado': usuarioData['usua_EsEmpleado'],
              'usua_Imagen': usuarioData['usua_Imagen'],
              'pers_Correo': usuarioData['pers_Correo'],
            },
            'persona': personaData,
            'empleado': empleadoData,
          };
        } else {
          return {'exito': false, 'mensaje': 'No se encontró el usuario'};
        }
      } else {
        return {
          'exito': false,
          'mensaje':
              'Error al obtener los detalles del usuario. Código: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error al obtener los detalles del usuario: $e',
      };
    }
  }

  /// Actualiza la información del usuario
  ///
  /// Permite actualizar el nombre de usuario, correo electrónico e imagen de perfil.
  /// Retorna un mapa con el resultado de la operación:
  /// - success: indica si la operación fue exitosa
  /// - message: mensaje descriptivo del resultado
  /// - codeStatus: código de estado (1 = éxito, -1 = advertencia, 0 = error)
  /// - messageStatus: mensaje detallado del estado
  Future<Map<String, dynamic>> actualizarUsuario({
    required int usuarioId,
    required String usuario,
    required int persId,
    required int roleId,
    required bool esAdmin,
    required int usuarioModificacion,
    required bool esEmpleado,
    required String correo,
    String? usua_Imagen, // Ruta de la imagen de perfil
  }) async {
    // Verificar conectividad con doble verificación para mayor robustez
    bool hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      // Segundo intento después de una breve pausa
      await Future.delayed(const Duration(milliseconds: 500));
      hasConnection = await _connectivityService.hasConnection();

      if (!hasConnection) {
        throw Exception(
          'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
        );
      }
    }

    // Obtener fecha actual en formato ISO
    final fechaActual = DateTime.now().toUtc().toIso8601String();

    final url = Uri.parse('${ApiConfig.baseUrl}/Usuarios/Actualizar');
    final response = await http.put(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({
        'usua_Id': usuarioId,
        'usua_Usuario': usuario,
        'pers_Id': persId,
        'role_Id': roleId,
        'usua_EsAdmin': esAdmin,
        'usua_Modificacion': usuarioModificacion,
        'usua_FechaModificacion': fechaActual,
        'usua_EsEmpleado': esEmpleado,
        'pers_Correo': correo,
        'usua_Imagen':
            usua_Imagen, // Añadir la ruta de la imagen si está disponible
      }),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      final codeStatus = jsonMap['data']?['code_Status'] ?? 0;
      final messageStatus = jsonMap['data']?['message_Status'] ?? '';

      return {
        'success': jsonMap['success'] ?? false,
        'message': jsonMap['message'] ?? 'Error al actualizar usuario',
        'codeStatus': codeStatus,
        'messageStatus': messageStatus,
      };
    } else {
      throw Exception(
        'No se pudo actualizar la información. Por favor, intenta nuevamente.',
      );
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
    String? usua_Imagen, // Ruta de la imagen de perfil
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
        'message_Status':
            'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.',
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
        'Usua_Imagen': usua_Imagen, // Añadir la ruta de la imagen
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
          final messageStatus =
              data['message_Status'] ?? data['messageStatus'] ?? 'Sin mensaje';

          return {
            'success': codeStatus == 1,
            'code_Status': codeStatus,
            'message_Status': messageStatus,
          };
        }

        if (jsonMap.containsKey('code_Status') &&
            jsonMap.containsKey('message_Status')) {
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
          'message_Status':
              'No se pudo completar el registro. Por favor, intenta nuevamente más tarde.',
        };
      } else {
        // Registrar el error técnico internamente
        print('Error HTTP ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'code_Status': 0,
          'message_Status':
              'No se pudo completar el registro. Por favor, verifica tus datos e intenta nuevamente.',
        };
      }
    } catch (e) {
      // Registrar el error técnico internamente
      print('Error de conexión: ${e.toString()}');
      return {
        'success': false,
        'code_Status': 0,
        'message_Status':
            'No se pudo conectar al servidor. Por favor, verifica tu conexión a internet e intenta nuevamente.',
      };
    }
  }
}
