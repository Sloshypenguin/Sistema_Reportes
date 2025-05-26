/// Modelo para representar un Estado Civil en el sistema
/// 
/// Esta clase mapea los datos de un estado civil desde la API
/// y proporciona métodos para convertir entre JSON y objetos.
class EstadoCivil {
  final int     esCi_Id;
  final String  esCi_Nombre;
  final int     usua_Creacion;
  final int?    usua_Modificacion;
  final String  esCi_FechaCreacion;
  final String? esCi_FechaModificacion;

  EstadoCivil({
    required this.esCi_Id,
    required this.esCi_Nombre,
    required this.usua_Creacion,
    this.usua_Modificacion,
    required this.esCi_FechaCreacion,
    this.esCi_FechaModificacion,
  });

  /// Crea una instancia de EstadoCivil a partir de un mapa JSON
  factory EstadoCivil.fromJson(Map<String, dynamic> json) {
    return EstadoCivil(
      esCi_Id: json['esCi_Id'] ?? 0,
      esCi_Nombre: json['esCi_Nombre'] ?? '',
      usua_Creacion: json['usua_Creacion'] ?? 0,
      usua_Modificacion: json['usua_Modificacion'],
      esCi_FechaCreacion: json['esCi_FechaCreacion'] ?? '',
      esCi_FechaModificacion: json['esCi_FechaModificacion'],
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'esCi_Id': esCi_Id,
      'esCi_Nombre': esCi_Nombre,
      'usua_Creacion': usua_Creacion,
      'usua_Modificacion': usua_Modificacion,
      'esCi_FechaCreacion': esCi_FechaCreacion,
      'esCi_FechaModificacion': esCi_FechaModificacion,
    };
  }
}
