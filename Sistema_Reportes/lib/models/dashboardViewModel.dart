/// Modelo para representar los datos del Dashboard en el sistema
///
/// Esta clase mapea los datos del dashboard desde la API
/// y proporciona métodos para convertir entre JSON y objetos.

// Modelo para resumen de reportes
class ResumenReportes {
  final int datoTotalReportes;
  final int datoPendientes;
  final int datoResueltos;
  final int datoEnGestion;
  final int datoCancelados;
  final int datoHoy;

  ResumenReportes({
    required this.datoTotalReportes,
    required this.datoPendientes,
    required this.datoResueltos,
    required this.datoEnGestion,
    required this.datoCancelados,
    required this.datoHoy,
  });

  factory ResumenReportes.fromJson(Map<String, dynamic> json) {
    return ResumenReportes(
      datoTotalReportes: json['dato_total_reportes'] ?? 0,
      datoPendientes: json['dato_pendientes'] ?? 0,
      datoResueltos: json['dato_resueltos'] ?? 0,
      datoEnGestion: json['dato_en_gestion'] ?? 0,
      datoCancelados: json['dato_cancelados'] ?? 0,
      datoHoy: json['dato_hoy'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dato_total_reportes': datoTotalReportes,
      'dato_pendientes': datoPendientes,
      'dato_resueltos': datoResueltos,
      'dato_en_gestion': datoEnGestion,
      'dato_cancelados': datoCancelados,
      'dato_hoy': datoHoy,
    };
  }
}

// Modelo para resumen de usuarios
class ResumenUsuarios {
  final int datoTotalUsuarios;
  final int datoAdministradores;
  final int datoEmpleados;

  ResumenUsuarios({
    required this.datoTotalUsuarios,
    required this.datoAdministradores,
    required this.datoEmpleados,
  });

  factory ResumenUsuarios.fromJson(Map<String, dynamic> json) {
    return ResumenUsuarios(
      datoTotalUsuarios: json['dato_total_usuarios'] ?? 0,
      datoAdministradores: json['dato_administradores'] ?? 0,
      datoEmpleados: json['dato_empleados'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dato_total_usuarios': datoTotalUsuarios,
      'dato_administradores': datoAdministradores,
      'dato_empleados': datoEmpleados,
    };
  }
}

// Modelo para reportes por mes
class ReportePorMes {
  final String etiquetaMes;
  final int valorNumeroMes;
  final int valorCantidad;

  ReportePorMes({
    required this.etiquetaMes,
    required this.valorNumeroMes,
    required this.valorCantidad,
  });

  factory ReportePorMes.fromJson(Map<String, dynamic> json) {
    return ReportePorMes(
      etiquetaMes: json['etiqueta_mes'] ?? '',
      valorNumeroMes: json['valor_numero_mes'] ?? 0,
      valorCantidad: json['valor_cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etiqueta_mes': etiquetaMes,
      'valor_numero_mes': valorNumeroMes,
      'valor_cantidad': valorCantidad,
    };
  }
}

// Modelo para reportes por servicio
class ReportePorServicio {
  final String etiquetaServicio;
  final int valorCantidad;

  ReportePorServicio({
    required this.etiquetaServicio,
    required this.valorCantidad,
  });

  factory ReportePorServicio.fromJson(Map<String, dynamic> json) {
    return ReportePorServicio(
      etiquetaServicio: json['etiqueta_servicio'] ?? '',
      valorCantidad: json['valor_cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etiqueta_servicio': etiquetaServicio,
      'valor_cantidad': valorCantidad,
    };
  }
}

// Modelo para reportes por municipio
class ReportePorMunicipio {
  final String etiquetaMunicipio;
  final int valorCantidad;

  ReportePorMunicipio({
    required this.etiquetaMunicipio,
    required this.valorCantidad,
  });

  factory ReportePorMunicipio.fromJson(Map<String, dynamic> json) {
    return ReportePorMunicipio(
      etiquetaMunicipio: json['etiqueta_municipio'] ?? '',
      valorCantidad: json['valor_cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etiqueta_municipio': etiquetaMunicipio,
      'valor_cantidad': valorCantidad,
    };
  }
}

// Modelo para reportes por estado
class ReportePorEstado {
  final String estadoCodigo;
  final int cantidad;

  ReportePorEstado({
    required this.estadoCodigo,
    required this.cantidad,
  });

  factory ReportePorEstado.fromJson(Map<String, dynamic> json) {
    return ReportePorEstado(
      estadoCodigo: json['estado_codigo'] ?? '',
      cantidad: json['cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estado_codigo': estadoCodigo,
      'cantidad': cantidad,
    };
  }
}

// Modelo para últimos reportes
class UltimoReporte {
  final int reporteId;
  final String personaNombre;
  final String servicioNombre;
  final String descripcion;
  final DateTime fechaRegistro;

  UltimoReporte({
    required this.reporteId,
    required this.personaNombre,
    required this.servicioNombre,
    required this.descripcion,
    required this.fechaRegistro,
  });

  factory UltimoReporte.fromJson(Map<String, dynamic> json) {
    return UltimoReporte(
      reporteId: json['reporte_id'] ?? 0,
      personaNombre: json['persona_nombre'] ?? '',
      servicioNombre: json['servicio_nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporte_id': reporteId,
      'persona_nombre': personaNombre,
      'servicio_nombre': servicioNombre,
      'descripcion': descripcion,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }
}

// Modelo para top usuarios con más reportes
class TopUsuario {
  final String personaNombre;
  final int totalReportes;

  TopUsuario({
    required this.personaNombre,
    required this.totalReportes,
  });

  factory TopUsuario.fromJson(Map<String, dynamic> json) {
    return TopUsuario(
      personaNombre: json['persona_nombre'] ?? '',
      totalReportes: json['total_reportes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'persona_nombre': personaNombre,
      'total_reportes': totalReportes,
    };
  }
}

// Modelo para servicios más reportados
class ServicioMasReportado {
  final String etiquetaServicio;
  final int valorCantidad;

  ServicioMasReportado({
    required this.etiquetaServicio,
    required this.valorCantidad,
  });

  factory ServicioMasReportado.fromJson(Map<String, dynamic> json) {
    return ServicioMasReportado(
      etiquetaServicio: json['etiqueta_servicio'] ?? '',
      valorCantidad: json['valor_cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etiqueta_servicio': etiquetaServicio,
      'valor_cantidad': valorCantidad,
    };
  }
}

// Modelo para resumen de estado por servicio
class ResumenEstadoPorServicio {
  final int cantidad;
  final String estadoCodigo;
  final String servicioNombre;

  ResumenEstadoPorServicio({
    required this.cantidad,
    required this.estadoCodigo,
    required this.servicioNombre,
  });

  factory ResumenEstadoPorServicio.fromJson(Map<String, dynamic> json) {
    return ResumenEstadoPorServicio(
      cantidad: json['cantidad'] ?? 0,
      estadoCodigo: json['estado_codigo'] ?? '',
      servicioNombre: json['servicio_nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad': cantidad,
      'estado_codigo': estadoCodigo,
      'servicio_nombre': servicioNombre,
    };
  }
}

// Modelo principal del Dashboard que contiene todos los datos
class Dashboard {
  final ResumenReportes? resumenReportes;
  final ResumenUsuarios? resumenUsuarios;
  final List<ReportePorMes> reportesPorMes;
  final List<ReportePorServicio> reportesPorServicio;
  final List<ReportePorMunicipio> reportesPorMunicipio;
  final List<ReportePorEstado> reportesPorEstado;
  final List<UltimoReporte> ultimosReportes;
  final List<TopUsuario> topUsuarios;
  final List<ServicioMasReportado> serviciosMasReportados;
  final List<ResumenEstadoPorServicio> resumenEstadoPorServicio;

  Dashboard({
    this.resumenReportes,
    this.resumenUsuarios,
    this.reportesPorMes = const [],
    this.reportesPorServicio = const [],
    this.reportesPorMunicipio = const [],
    this.reportesPorEstado = const [],
    this.ultimosReportes = const [],
    this.topUsuarios = const [],
    this.serviciosMasReportados = const [],
    this.resumenEstadoPorServicio = const [],
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    // Procesar resumen de reportes
    ResumenReportes? resumenReportes;
    if (json.containsKey('resumenReportes')) {
      resumenReportes = ResumenReportes.fromJson(json['resumenReportes']);
    }

    // Procesar resumen de usuarios
    ResumenUsuarios? resumenUsuarios;
    if (json.containsKey('resumenUsuarios')) {
      resumenUsuarios = ResumenUsuarios.fromJson(json['resumenUsuarios']);
    }

    // Procesar reportes por mes
    List<ReportePorMes> reportesPorMes = [];
    if (json.containsKey('reportesPorMes') && json['reportesPorMes'] is List) {
      reportesPorMes = (json['reportesPorMes'] as List)
          .map((item) => ReportePorMes.fromJson(item))
          .toList();
    }

    // Procesar reportes por servicio
    List<ReportePorServicio> reportesPorServicio = [];
    if (json.containsKey('reportesPorServicio') && json['reportesPorServicio'] is List) {
      reportesPorServicio = (json['reportesPorServicio'] as List)
          .map((item) => ReportePorServicio.fromJson(item))
          .toList();
    }

    // Procesar reportes por municipio
    List<ReportePorMunicipio> reportesPorMunicipio = [];
    if (json.containsKey('reportesPorMunicipio') && json['reportesPorMunicipio'] is List) {
      reportesPorMunicipio = (json['reportesPorMunicipio'] as List)
          .map((item) => ReportePorMunicipio.fromJson(item))
          .toList();
    }

    // Procesar reportes por estado
    List<ReportePorEstado> reportesPorEstado = [];
    if (json.containsKey('reportesPorEstado') && json['reportesPorEstado'] is List) {
      reportesPorEstado = (json['reportesPorEstado'] as List)
          .map((item) => ReportePorEstado.fromJson(item))
          .toList();
    }

    // Procesar últimos reportes
    List<UltimoReporte> ultimosReportes = [];
    if (json.containsKey('ultimosReportes') && json['ultimosReportes'] is List) {
      ultimosReportes = (json['ultimosReportes'] as List)
          .map((item) => UltimoReporte.fromJson(item))
          .toList();
    }

    // Procesar top usuarios
    List<TopUsuario> topUsuarios = [];
    if (json.containsKey('topUsuarios') && json['topUsuarios'] is List) {
      topUsuarios = (json['topUsuarios'] as List)
          .map((item) => TopUsuario.fromJson(item))
          .toList();
    }

    // Procesar servicios más reportados
    List<ServicioMasReportado> serviciosMasReportados = [];
    if (json.containsKey('serviciosMasReportados') && json['serviciosMasReportados'] is List) {
      serviciosMasReportados = (json['serviciosMasReportados'] as List)
          .map((item) => ServicioMasReportado.fromJson(item))
          .toList();
    }

    // Procesar resumen de estado por servicio
    List<ResumenEstadoPorServicio> resumenEstadoPorServicio = [];
    if (json.containsKey('resumenEstadoPorServicio') && json['resumenEstadoPorServicio'] is List) {
      resumenEstadoPorServicio = (json['resumenEstadoPorServicio'] as List)
          .map((item) => ResumenEstadoPorServicio.fromJson(item))
          .toList();
    }

    return Dashboard(
      resumenReportes: resumenReportes,
      resumenUsuarios: resumenUsuarios,
      reportesPorMes: reportesPorMes,
      reportesPorServicio: reportesPorServicio,
      reportesPorMunicipio: reportesPorMunicipio,
      reportesPorEstado: reportesPorEstado,
      ultimosReportes: ultimosReportes,
      topUsuarios: topUsuarios,
      serviciosMasReportados: serviciosMasReportados,
      resumenEstadoPorServicio: resumenEstadoPorServicio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resumenReportes': resumenReportes?.toJson(),
      'resumenUsuarios': resumenUsuarios?.toJson(),
      'reportesPorMes': reportesPorMes.map((item) => item.toJson()).toList(),
      'reportesPorServicio': reportesPorServicio.map((item) => item.toJson()).toList(),
      'reportesPorMunicipio': reportesPorMunicipio.map((item) => item.toJson()).toList(),
      'reportesPorEstado': reportesPorEstado.map((item) => item.toJson()).toList(),
      'ultimosReportes': ultimosReportes.map((item) => item.toJson()).toList(),
      'topUsuarios': topUsuarios.map((item) => item.toJson()).toList(),
      'serviciosMasReportados': serviciosMasReportados.map((item) => item.toJson()).toList(),
      'resumenEstadoPorServicio': resumenEstadoPorServicio.map((item) => item.toJson()).toList(),
    };
  }
}
