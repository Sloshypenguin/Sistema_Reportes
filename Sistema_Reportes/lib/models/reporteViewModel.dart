/// Modelo para representar un Reporte en el sistema
///
/// Esta clase mapea los datos de un reporte desde la API
/// y proporciona métodos para convertir entre JSON y objetos.
class Reporte {
  final int repo_Id;
  final int pers_Id;
  final String persona;
  final int serv_Id;
  final String serv_Nombre;
  final String repo_Descripcion;
  final String? repo_Ubicacion;
  final bool repo_Prioridad;
  final String prioridad;
  final String repo_Estado;
  final int usua_Creacion;
  final String repo_FechaCreacion;
  final int? usua_Modificacion;
  final String? repo_FechaModificacion;
  final String? repo_EstadoRegistro;

  Reporte({
    required this.repo_Id,
    required this.pers_Id,
    required this.persona,
    required this.serv_Id,
    required this.serv_Nombre,
    required this.repo_Descripcion,
    this.repo_Ubicacion,
    required this.repo_Prioridad,
    required this.prioridad,
    required this.repo_Estado,
    required this.usua_Creacion,
    required this.repo_FechaCreacion,
    this.usua_Modificacion,
    this.repo_FechaModificacion,
    this.repo_EstadoRegistro,
  });

  /// Crea una instancia de Reporte a partir de un mapa JSON
  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      repo_Id: json['repo_Id'] ?? 0,
      pers_Id: json['pers_Id'] ?? 0,
      persona: json['persona'] ?? '',
      serv_Id: json['serv_Id'] ?? 0,
      serv_Nombre: json['serv_Nombre'] ?? '',
      repo_Descripcion: json['repo_Descripcion'] ?? '',
      repo_Ubicacion: json['repo_Ubicacion'],
      repo_Prioridad: json['repo_Prioridad'] ?? false,
      prioridad: json['prioridad'] ?? '',
      repo_Estado: json['repo_Estado'] ?? '',
      usua_Creacion: json['usua_Creacion'] ?? 0,
      repo_FechaCreacion: json['repo_FechaCreacion'] ?? '',
      usua_Modificacion: json['usua_Modificacion'],
      repo_FechaModificacion: json['repo_FechaModificacion'],
      repo_EstadoRegistro: json['repo_EstadoRegistro'],
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'repo_Id': repo_Id,
      'pers_Id': pers_Id,
      'persona': persona,
      'serv_Id': serv_Id,
      'serv_Nombre': serv_Nombre,
      'repo_Descripcion': repo_Descripcion,
      'repo_Ubicacion': repo_Ubicacion,
      'repo_Prioridad': repo_Prioridad,
      'prioridad': prioridad,
      'repo_Estado': repo_Estado,
      'usua_Creacion': usua_Creacion,
      'repo_FechaCreacion': repo_FechaCreacion,
      'usua_Modificacion': usua_Modificacion,
      'repo_FechaModificacion': repo_FechaModificacion,
      'repo_EstadoRegistro': repo_EstadoRegistro,
    };
  }
}
