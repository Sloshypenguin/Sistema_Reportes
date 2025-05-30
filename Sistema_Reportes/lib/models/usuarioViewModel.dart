class Usuario {
  final int     usua_Id;
  final String  usua_Usuario;
  final String? usua_Contrasena;
  final int     pers_Id;
  final int     role_Id;
  final bool    usua_EsAdmin;
  final int?    usua_Creacion;
  final String? usua_FechaCreacion;
  final int?    usua_Modificacion;
  final String? usua_FechaModificacion;
  final String? usua_Token;
  final bool    usua_Estado;
  final bool    usua_EsEmpleado;
  final String? empleado;
  final String? persona;
  final String? role_Nombre;  
  final String? pantallas;
  final String? pers_Correo;
  final String? usua_Imagen; // Ruta de la imagen de perfil
  final int?    code_Status;
  final String? message_Status;

  Usuario({
    required this.usua_Id,
    required this.usua_Usuario,
    this.usua_Contrasena,
    required this.pers_Id,
    required this.role_Id,
    required this.usua_EsAdmin,
    this.usua_Creacion,
    this.usua_FechaCreacion,
    this.usua_Modificacion,
    this.usua_FechaModificacion,
    this.usua_Token,
    required this.usua_Estado,
    required this.usua_EsEmpleado,
    this.empleado,
    this.persona,
    this.role_Nombre, 
    this.pantallas,
    this.pers_Correo,
    this.usua_Imagen, // Añadido campo para la imagen
    this.code_Status,
    this.message_Status,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usua_Id: json['usua_Id'] ?? 0,
      usua_Usuario: json['usua_Usuario'] ?? '',
      usua_Contrasena: json['usua_Contrasena'],
      pers_Id: json['pers_Id'] ?? 0,
      role_Id: json['role_Id'] ?? 0,
      usua_EsAdmin: json['usua_EsAdmin'] ?? false,
      usua_Creacion: json['usua_Creacion'],
      usua_FechaCreacion: json['usua_FechaCreacion'],
      usua_Modificacion: json['usua_Modificacion'],
      usua_FechaModificacion: json['usua_FechaModificacion'],
      usua_Token: json['usua_Token'],
      usua_Estado: json['usua_Estado'] ?? false,
      usua_EsEmpleado: json['usua_EsEmpleado'] ?? false,
      empleado: json['empleado'],
      persona: json['persona'],
      role_Nombre: json['role_Nombre'],
      pantallas: json['pantallas'],
      pers_Correo: json['pers_Correo'],
      usua_Imagen: json['usua_Imagen'], // Añadido campo para la imagen
      code_Status: json['code_Status'],
      message_Status: json['message_Status'],
    );
  }
}
