import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuarioViewModel.dart';
import '../models/apiResponse.dart';

/// Servicio para manejar operaciones relacionadas con usuarios
/// 
/// Este servicio proporciona métodos para:
/// - Iniciar sesión (login)
/// - Registrar nuevos usuarios (registro)
/// - Otras operaciones relacionadas con usuarios que puedan ser necesarias
class UsuarioService {
  /// URL base del servidor API
  final String _baseUrl = 'http://sistemareportesgob.somee.com';
  
  /// Clave API para autenticación con el servidor
  final String _apiKey = 'bdccf3f3-d486-4e1e-ab44-74081aefcdbc';

  /// Autentica a un usuario con sus credenciales
  /// 
  /// @param usuario Nombre de usuario
  /// @param contrasena Contraseña del usuario
  /// @return Usuario autenticado o null si la autenticación falla
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
  
  /// Registra un nuevo usuario en el sistema
  /// 
  /// @param nombre Nombre completo del usuario
  /// @param usuario Nombre de usuario para iniciar sesión
  /// @param correo Correo electrónico del usuario
  /// @param contrasena Contraseña del usuario
  /// @return Usuario registrado o null si el registro falla
  Future<Usuario?> registro(String nombre, String usuario, String correo, String contrasena) async {
    // La URL del endpoint de registro puede variar según la API
    final url = Uri.parse('$_baseUrl/Usuarios/Insertar');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
        body: jsonEncode({
          'pers_Nombres': nombre,
          'usua_Usuario': usuario,
          'pers_Correo': correo,
          'usua_Contrasena': contrasena,
          // Puedes agregar más campos según los requisitos de tu API
          'role_Id': 2, // Rol por defecto para nuevos usuarios (ajustar según necesidad)
          'usua_EsAdmin': false, // Por defecto, los nuevos usuarios no son administradores
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
        throw Exception('Error en el registro: ${response.statusCode}');
      }
    } catch (e) {
      print('Error durante el registro: $e');
      return null;
    }
  }
}
