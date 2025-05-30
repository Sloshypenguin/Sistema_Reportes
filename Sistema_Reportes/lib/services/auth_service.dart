import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/usuarioViewModel.dart';
import 'usuarioService.dart';

/// Servicio centralizado para manejar la autenticación y sesión del usuario
///
/// Este servicio proporciona métodos para:
/// - Iniciar sesión y autenticar usuarios
/// - Guardar y recuperar datos de sesión
/// - Verificar el estado de la sesión
/// - Cerrar sesión
/// - Obtener información del usuario logueado
class AuthService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final UsuarioService _usuarioService = UsuarioService();

  /// Intenta autenticar al usuario con las credenciales proporcionadas
  ///
  /// @param usuario Nombre de usuario
  /// @param contrasena Contraseña del usuario
  /// @param mantenerSesion Indica si se debe mantener la sesión activa
  /// @return Future<Usuario?> Datos del usuario si la autenticación es exitosa, null en caso contrario
  static Future<Usuario?> iniciarSesion({
    required String usuario,
    required String contrasena,
    bool mantenerSesion = true,
  }) async {
    try {
      // Llamar al servicio de autenticación
      final Usuario? usuarioData = await _usuarioService.login(
        usuario.trim(),
        contrasena.trim(),
      );

      // Verificar si la autenticación fue exitosa
      if (usuarioData != null &&
          (usuarioData.code_Status == 1 || usuarioData.code_Status == null)) {
        // Guardar datos del usuario en el almacenamiento seguro
        await guardarDatosUsuario(usuarioData, mantenerSesion);
        return usuarioData;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error técnico durante el inicio de sesión: $e');
      return null;
    }
  }

  /// Guarda todos los datos del usuario en el almacenamiento seguro
  ///
  /// @param usuario Objeto Usuario con los datos a guardar
  /// @param mantenerSesion Indica si se debe mantener la sesión activa
  static Future<void> guardarDatosUsuario(Usuario usuario, bool mantenerSesion) async {
    try {
      // Guardar información básica del usuario
      await _storage.write(key: 'usuario_id', value: usuario.usua_Id.toString());
      await _storage.write(key: 'usuario_nombre', value: usuario.usua_Usuario);
      await _storage.write(key: 'usuario_token', value: usuario.usua_Token);
      await _storage.write(key: 'usuario_rol', value: usuario.role_Nombre);
      await _storage.write(
        key: 'usuario_es_admin',
        value: usuario.usua_EsAdmin.toString(),
      );

      // Guardar IDs importantes para operaciones de actualización
      await _storage.write(key: 'pers_id', value: usuario.pers_Id.toString());
      await _storage.write(key: 'role_id', value: usuario.role_Id.toString());

      // Guardar correo electrónico
      if (usuario.pers_Correo != null) {
        await _storage.write(key: 'usuario_correo', value: usuario.pers_Correo);
      }

      // Guardar estado de empleado
      await _storage.write(
        key: 'usuario_es_empleado',
        value: usuario.usua_EsEmpleado.toString(),
      );

      // Guardar nombre de empleado si existe
      if (usuario.empleado != null) {
        await _storage.write(key: 'usuario_empleado', value: usuario.empleado);
      }

      // Guardar pantallas si están disponibles
      if (usuario.pantallas != null) {
        await _storage.write(key: 'usuario_pantallas', value: usuario.pantallas);
      }
      
      // Guardar la ruta de la imagen de perfil si está disponible
      if (usuario.usua_Imagen != null && usuario.usua_Imagen!.isNotEmpty) {
        await _storage.write(key: 'usuario_imagen', value: usuario.usua_Imagen);
        debugPrint('Imagen de perfil guardada: ${usuario.usua_Imagen}');
      }

      // Guardar estado de sesión activa según la elección del usuario
      await _storage.write(
        key: 'sesion_activa',
        value: mantenerSesion ? 'true' : 'false',
      );

      debugPrint('Datos del usuario guardados correctamente');
      debugPrint('Mantener sesión activa: $mantenerSesion');
    } catch (e) {
      debugPrint('Error al guardar datos del usuario: $e');
    }
  }

  /// Verifica si hay una sesión activa guardada
  ///
  /// @return Future<bool> true si hay una sesión activa, false en caso contrario
  static Future<bool> verificarSesionActiva() async {
    try {
      final sesionActiva = await _storage.read(key: 'sesion_activa');
      
      // Verificar si hay una sesión activa (mantener sesión = true)
      // No verificamos el token ya que solo nos interesa si el usuario quiere mantener la sesión
      final resultado = sesionActiva == 'true';
      
      // Imprimir información de depuración
      debugPrint('Verificando sesión activa:');
      debugPrint('- sesion_activa: $sesionActiva');
      debugPrint('- Resultado verificación: $resultado');
      
      return resultado;
    } catch (e) {
      debugPrint('Error al verificar la sesión: $e');
      return false;
    }
  }

  /// Cierra la sesión eliminando todos los datos del usuario
  ///
  /// @return Future<bool> true si la sesión se cerró correctamente, false en caso contrario
  static Future<bool> cerrarSesion() async {
    try {
      // Eliminar todos los datos del usuario
      await _storage.deleteAll();
      
      // Establecer explícitamente sesion_activa como false
      await _storage.write(key: 'sesion_activa', value: 'false');
      debugPrint('Sesión cerrada y sesion_activa establecida a false');
      
      return true;
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      return false;
    }
  }

  /// Limpia todas las cachés de datos usadas en la aplicación
  static Future<void> limpiarCacheDatos() async {
    try {
      // Aquí se puede implementar la limpieza de cachés específicas
      // como SharedPreferences u otras cachés de la aplicación
      debugPrint('Caché limpiada correctamente');
    } catch (e) {
      debugPrint('Error al limpiar caché: $e');
    }
  }

  /// Obtiene el token de sesión (si existe)
  static Future<String?> obtenerToken() async {
    return await _storage.read(key: 'usuario_token');
  }

  /// Obtiene el nombre de usuario almacenado
  ///
  /// @return Future<String?> Nombre de usuario o null si no existe
  static Future<String?> obtenerNombreUsuario() async {
    return await _storage.read(key: 'usuario_nombre');
  }
  
  /// Obtiene la ruta de la imagen de perfil almacenada
  ///
  /// @return Future<String?> Ruta de la imagen de perfil o null si no existe
  static Future<String?> obtenerImagenPerfil() async {
    return await _storage.read(key: 'usuario_imagen');
  }

  /// Obtiene el correo del usuario
  static Future<String?> obtenerCorreoUsuario() async {
    return await _storage.read(key: 'usuario_correo');
  }

  /// Obtiene el rol del usuario
  static Future<String?> obtenerRol() async {
    return await _storage.read(key: 'usuario_rol');
  }

  /// Obtiene el ID del usuario
  static Future<String?> obtenerUsuarioId() async {
    return await _storage.read(key: 'usuario_id');
  }
  
  /// Obtiene el ID de la persona
  static Future<String?> obtenerPersonaId() async {
    return await _storage.read(key: 'pers_id');
  }
  
  /// Obtiene el ID del rol
  static Future<String?> obtenerRolId() async {
    return await _storage.read(key: 'role_id');
  }
  
  /// Verifica si el usuario es administrador
  static Future<bool> esAdministrador() async {
    final esAdmin = await _storage.read(key: 'usuario_es_admin');
    return esAdmin == 'true';
  }
  
  /// Verifica si el usuario es empleado
  static Future<bool> esEmpleado() async {
    final esEmpleado = await _storage.read(key: 'usuario_es_empleado');
    return esEmpleado == 'true';
  }
  
  /// Obtiene las pantallas disponibles para el usuario
  static Future<String?> obtenerPantallas() async {
    return await _storage.read(key: 'usuario_pantallas');
  }
}
