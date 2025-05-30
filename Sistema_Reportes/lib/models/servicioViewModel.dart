class Servicio {
  final int     serv_Id;
  final String  serv_Nombre;
  final int     usua_Creacion;
  final int?    usua_Modificacion;
  final String  serv_FechaCreacion;
  final String? serv_FechaModificacion;
  final bool?   serv_Estado;

  Servicio({
    required this.serv_Id,
    required this.serv_Nombre,
    required this.usua_Creacion,
    this.usua_Modificacion,
    required this.serv_FechaCreacion,
    this.serv_FechaModificacion,
    this.serv_Estado,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      serv_Id: json['serv_Id'] ?? 0,
      serv_Nombre: json['serv_Nombre'] ?? '',
      usua_Creacion: json['usua_Creacion'] ?? 0,
      usua_Modificacion: json['usua_Modificacion'],
      serv_FechaCreacion: json['serv_FechaCreacion'] ?? '',
      serv_FechaModificacion: json['serv_FechaModificacion'],
      serv_Estado: json['serv_Estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serv_Id': serv_Id,
      'serv_Nombre': serv_Nombre,
      'usua_Creacion': usua_Creacion,
      'usua_Modificacion': usua_Modificacion,
      'serv_FechaCreacion': serv_FechaCreacion,
      'serv_FechaModificacion': serv_FechaModificacion,
      'serv_Estado': serv_Estado,
    };
  }
}