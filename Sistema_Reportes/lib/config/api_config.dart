/// Configuración centralizada para la API
///
/// Este archivo contiene todas las constantes relacionadas con la API,
/// como la URL base, claves de autenticación, etc.
class ApiConfig {
  /// URL base para todas las llamadas a la API
  static const String baseUrl = 'http://siresp.somee.com';

  /// Clave API para autenticación con el servidor
  static const String apiKey = 'bdccf3f3-d486-4e1e-ab44-74081aefcdbc';

  /// Encabezados comunes para todas las solicitudes HTTP
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'X-API-KEY': apiKey,
  };

  /// Versión de la API (si es necesario para futuras actualizaciones)
  static const String apiVersion = 'v1';

  /// Tiempo de espera para solicitudes HTTP (en segundos)
  static const int timeoutDuration = 30;

  /// Formatea una fecha en formato ISO 8601 UTC compatible con SQL Server
  static String formatearFechaIso(DateTime fecha) {
    final fechaMinSql = DateTime(1753, 1, 1);
    if (fecha.isBefore(fechaMinSql)) {
      return fechaMinSql.toUtc().toIso8601String();
    }
    return fecha.toUtc().toIso8601String(); // Ej: 2025-05-25T22:16:42.710Z
  }
}
