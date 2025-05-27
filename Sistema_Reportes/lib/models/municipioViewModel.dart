/// Modelo para representar un Municipio en el sistema
///
/// Esta clase mapea los datos de un municipio desde la API
/// y proporciona métodos para convertir entre JSON y objetos.
class Municipio {
  final int muni_Id;
  final String muni_Codigo;
  final String muni_Nombre;
  final int depa_Id;
  final String? depa_Nombre;
  final int usua_Creacion;
  final int? usua_Modificacion;
  final String muni_FechaCreacion;
  final String? muni_FechaModificacion;

  Municipio({
    required this.muni_Id,
    required this.muni_Codigo,
    required this.muni_Nombre,
    required this.depa_Id,
    this.depa_Nombre,
    required this.usua_Creacion,
    this.usua_Modificacion,
    required this.muni_FechaCreacion,
    this.muni_FechaModificacion,
  });

  /// Crea una instancia de Municipio a partir de un mapa JSON
  factory Municipio.fromJson(Map<String, dynamic> json) {
    return Municipio(
      muni_Id: json['muni_Id'] ?? 0,
      muni_Codigo: json['muni_Codigo'] ?? '',
      muni_Nombre: json['muni_Nombre'] ?? '',
      depa_Id: json['depa_Id'] ?? 0,
      depa_Nombre: json['depa_Nombre'],
      usua_Creacion: json['usua_Creacion'] ?? 0,
      usua_Modificacion: json['usua_Modificacion'],
      muni_FechaCreacion: json['muni_FechaCreacion'] ?? '',
      muni_FechaModificacion: json['muni_FechaModificacion'],
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'muni_Id': muni_Id,
      'muni_Codigo': muni_Codigo,
      'muni_Nombre': muni_Nombre,
      'depa_Id': depa_Id,
      'depa_Nombre': depa_Nombre,
      'usua_Creacion': usua_Creacion,
      'usua_Modificacion': usua_Modificacion,
      'muni_FechaCreacion': muni_FechaCreacion,
      'muni_FechaModificacion': muni_FechaModificacion,
    };
  }
}
