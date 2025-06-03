/// Modelo para representar un detalle de Reporte en el sistema
///
/// Esta clase mapea los datos del detalle del reporte desde la API
/// y proporciona métodos para convertir entre JSON y objetos.
class ReporteDetalle {
  final int rdet_Id;
  final int repo_Id;
  final String rdet_Observacion;
  final int usua_Creacion;
  final String rdet_FechaCreacion;
  final int? usua_Modificacion;
  final String? rdet_FechaModificacion;
  final String? rdet_Estado;

  ReporteDetalle({
    required this.rdet_Id,
    required this.repo_Id,
    required this.rdet_Observacion,
    required this.usua_Creacion,
    required this.rdet_FechaCreacion,
    this.usua_Modificacion,
    this.rdet_FechaModificacion,
    this.rdet_Estado,
  });

  /// Crea una instancia de ReporteDetalle a partir de un mapa JSON
  factory ReporteDetalle.fromJson(Map<String, dynamic> json) {
    return ReporteDetalle(
      rdet_Id: json['rdet_Id'] ?? 0,
      repo_Id: json['repo_Id'] ?? 0,
      rdet_Observacion: json['rdet_Observacion'] ?? '',
      usua_Creacion: json['usua_Creacion'] ?? 0,
      rdet_FechaCreacion: json['rdet_FechaCreacion'] ?? '',
      usua_Modificacion: json['usua_Modificacion'],
      rdet_FechaModificacion: json['rdet_FechaModificacion'],
      rdet_Estado: json['rdet_Estado'],
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'rdet_Id': rdet_Id,
      'repo_Id': repo_Id,
      'rdet_Observacion': rdet_Observacion,
      'usua_Creacion': usua_Creacion,
      'rdet_FechaCreacion': rdet_FechaCreacion,
      'usua_Modificacion': usua_Modificacion,
      'rdet_FechaModificacion': rdet_FechaModificacion,
      'rdet_Estado': rdet_Estado,
    };
  }
}
