class Departamento {
  final String depa_Codigo;
  final String depa_Nombre;
  final int usua_Creacion;
  final int? usua_Modificacion;
  final String depa_FechaCreacion;
  final String? depa_FechaModificacion;

  Departamento({
    required this.depa_Codigo,
    required this.depa_Nombre,
    required this.usua_Creacion,
    this.usua_Modificacion,
    required this.depa_FechaCreacion,
    this.depa_FechaModificacion,
  });

  factory Departamento.fromJson(Map<String, dynamic> json) {
    return Departamento(
      depa_Codigo: json['depa_Codigo'] ?? '',
      depa_Nombre: json['depa_Nombre'] ?? '',
      usua_Creacion: json['usua_Creacion'] ?? 0,
      usua_Modificacion: json['usua_Modificacion'],
      depa_FechaCreacion: json['depa_FechaCreacion'] ?? '',
      depa_FechaModificacion: json['depa_FechaModificacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'depa_Codigo': depa_Codigo,
      'depa_Nombre': depa_Nombre,
      'usua_Creacion': usua_Creacion,
      'usua_Modificacion': usua_Modificacion,
      'depa_FechaCreacion': depa_FechaCreacion,
      'depa_FechaModificacion': depa_FechaModificacion,
    };
  }

  @override
  String toString() => depa_Nombre;
}
