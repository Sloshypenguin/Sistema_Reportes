/// Modelo para representar una Persona en el sistema
/// 
/// Esta clase mapea los datos de una persona desde la API
/// y proporciona métodos para convertir entre JSON y objetos.
class Persona {
  final int     pers_Id;
  final String  pers_DNI;
  final String  pers_Nombres;
  final String  pers_Apellidos;
  final String  pers_Sexo;
  final int     esCi_Id;
  final String? esCi_Nombre;
  final String  pers_Telefono;
  final String  pers_Correo;
  final String  pers_Direccion;
  final String  muni_Codigo;
  final String? muni_Nombre;
  final int     usua_Creacion;
  final int?    usua_Modificacion;
  final String  pers_FechaCreacion;
  final String? pers_FechaModificacion;

  Persona({
    required this.pers_Id,
    required this.pers_DNI,
    required this.pers_Nombres,
    required this.pers_Apellidos,
    required this.pers_Sexo,
    required this.esCi_Id,
    this.esCi_Nombre,
    required this.pers_Telefono,
    required this.pers_Correo,
    required this.pers_Direccion,
    required this.muni_Codigo,
    this.muni_Nombre,
    required this.usua_Creacion,
    this.usua_Modificacion,
    required this.pers_FechaCreacion,
    this.pers_FechaModificacion,
  });

  /// Crea una instancia de Persona a partir de un mapa JSON
  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      pers_Id: json['pers_Id'] ?? 0,
      pers_DNI: json['pers_DNI'] ?? '',
      pers_Nombres: json['pers_Nombres'] ?? '',
      pers_Apellidos: json['pers_Apellidos'] ?? '',
      pers_Sexo: json['pers_Sexo'] ?? '',
      esCi_Id: json['esCi_Id'] ?? 0,
      esCi_Nombre: json['esCi_Nombre'],
      pers_Telefono: json['pers_Telefono'] ?? '',
      pers_Correo: json['pers_Correo'] ?? '',
      pers_Direccion: json['pers_Direccion'] ?? '',
      muni_Codigo: json['muni_Codigo'] ?? '',
      muni_Nombre: json['muni_Nombre'],
      usua_Creacion: json['usua_Creacion'] ?? 0,
      usua_Modificacion: json['usua_Modificacion'],
      pers_FechaCreacion: json['pers_FechaCreacion'] ?? '',
      pers_FechaModificacion: json['pers_FechaModificacion'],
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'pers_Id': pers_Id,
      'pers_DNI': pers_DNI,
      'pers_Nombres': pers_Nombres,
      'pers_Apellidos': pers_Apellidos,
      'pers_Sexo': pers_Sexo,
      'esCi_Id': esCi_Id,
      'esCi_Nombre': esCi_Nombre,
      'pers_Telefono': pers_Telefono,
      'pers_Correo': pers_Correo,
      'pers_Direccion': pers_Direccion,
      'muni_Codigo': muni_Codigo,
      'muni_Nombre': muni_Nombre,
      'usua_Creacion': usua_Creacion,
      'usua_Modificacion': usua_Modificacion,
      'pers_FechaCreacion': pers_FechaCreacion,
      'pers_FechaModificacion': pers_FechaModificacion,
    };
  }
}
