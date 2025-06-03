import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboardViewModel.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

class DashboardService {
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Obtiene el resumen del dashboard desde la API
  Future<ResumenReportes?> obtenerResumenDashboard() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Dashboard/Resumen');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List &&
            (jsonResponse['data'] as List).isNotEmpty) {
          // Obtener el primer elemento de la lista de datos
          final Map<String, dynamic> data = jsonResponse['data'][0];
          return ResumenReportes.fromJson(data);
        } else {
          print(
            'Estructura de respuesta inesperada para dashboard: $jsonResponse',
          );
          return null;
        }
      } else {
        print(
          'Error HTTP al obtener resumen de dashboard: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar resumen de dashboard: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener resumen de dashboard: $e');
      rethrow;
    }
  }

  /// Obtiene los reportes por mes desde la API
  Future<List<ReportePorMes>> obtenerReportesPorMes() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Dashboard/ReportesPorMes');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => ReportePorMes.fromJson(item)).toList();
        } else {
          print(
            'Estructura de respuesta inesperada para reportes por mes: $jsonResponse',
          );
          return [];
        }
      } else {
        print('Error HTTP al obtener reportes por mes: ${response.statusCode}');
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar reportes por mes: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener reportes por mes: $e');
      rethrow;
    }
  }

  /// Obtiene los reportes por servicio desde la API
  Future<List<ReportePorServicio>> obtenerReportesPorServicio() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Dashboard/ReportesPorServicio');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => ReportePorServicio.fromJson(item)).toList();
        } else {
          print(
            'Estructura de respuesta inesperada para reportes por servicio: $jsonResponse',
          );
          return [];
        }
      } else {
        print(
          'Error HTTP al obtener reportes por servicio: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar reportes por servicio: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener reportes por servicio: $e');
      rethrow;
    }
  }

  /// Obtiene los reportes por municipio desde la API
  Future<List<ReportePorMunicipio>> obtenerReportesPorMunicipio() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/Dashboard/ReportesPorMunicipio',
    );

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data
              .map((item) => ReportePorMunicipio.fromJson(item))
              .toList();
        } else {
          print(
            'Estructura de respuesta inesperada para reportes por municipio: $jsonResponse',
          );
          return [];
        }
      } else {
        print(
          'Error HTTP al obtener reportes por municipio: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar reportes por municipio: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener reportes por municipio: $e');
      rethrow;
    }
  }

  /// Obtiene los reportes por estado desde la API
  Future<List<ReportePorEstado>> obtenerReportesPorEstado() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Dashboard/ReportesPorEstado');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => ReportePorEstado.fromJson(item)).toList();
        } else {
          print(
            'Estructura de respuesta inesperada para reportes por estado: $jsonResponse',
          );
          return [];
        }
      } else {
        print(
          'Error HTTP al obtener reportes por estado: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar reportes por estado: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener reportes por estado: $e');
      rethrow;
    }
  }

  /// Obtiene el top de usuarios con más reportes desde la API
  Future<List<TopUsuario>> obtenerTopUsuarios() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Dashboard/TopUsuarios');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => TopUsuario.fromJson(item)).toList();
        } else {
          print(
            'Estructura de respuesta inesperada para top usuarios: $jsonResponse',
          );
          return [];
        }
      } else {
        print('Error HTTP al obtener top usuarios: ${response.statusCode}');
        print('Error body: ${response.body}');
        throw Exception("Error al cargar top usuarios: ${response.statusCode}");
      }
    } catch (e) {
      print('Excepción al obtener top usuarios: $e');
      rethrow;
    }
  }

  /// Obtiene el resumen de usuarios desde la API
  Future<ResumenUsuarios?> obtenerResumenUsuarios() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Dashboard/UsuariosResumen');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List &&
            (jsonResponse['data'] as List).isNotEmpty) {
          // Obtener el primer elemento de la lista de datos
          final Map<String, dynamic> data = jsonResponse['data'][0];
          return ResumenUsuarios.fromJson(data);
        } else {
          print(
            'Estructura de respuesta inesperada para resumen de usuarios: $jsonResponse',
          );
          return null;
        }
      } else {
        print(
          'Error HTTP al obtener resumen de usuarios: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar resumen de usuarios: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener resumen de usuarios: $e');
      rethrow;
    }
  }

  /// Obtiene los servicios más reportados desde la API
  Future<List<ServicioMasReportado>> obtenerServiciosMasReportados() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/Dashboard/ServiciosMasReportados',
    );

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data
              .map((item) => ServicioMasReportado.fromJson(item))
              .toList();
        } else {
          print(
            'Estructura de respuesta inesperada para servicios más reportados: $jsonResponse',
          );
          return [];
        }
      } else {
        print(
          'Error HTTP al obtener servicios más reportados: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar servicios más reportados: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener servicios más reportados: $e');
      rethrow;
    }
  }

  /// Obtiene el resumen de estado por servicio desde la API
  Future<List<ResumenEstadoPorServicio>>
  obtenerResumenEstadoPorServicio() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/Dashboard/ResumenEstadoPorServicio',
    );

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data
              .map((item) => ResumenEstadoPorServicio.fromJson(item))
              .toList();
        } else {
          print(
            'Estructura de respuesta inesperada para resumen de estado por servicio: $jsonResponse',
          );
          return [];
        }
      } else {
        print(
          'Error HTTP al obtener resumen de estado por servicio: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar resumen de estado por servicio: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener resumen de estado por servicio: $e');
      rethrow;
    }
  }

  /// Obtiene los reportes por municipio filtrados por fecha desde la API
  Future<List<ReportePorMunicipio>> obtenerReportesPorMunicipioPorFecha(
    DateTime fechaInicio,
    DateTime fechaFin, {
    String? depaCodigo,
  }) async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    // Formatear fechas en formato ISO (YYYY-MM-DD)
    final fechaInicioStr =
        "${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}";
    final fechaFinStr =
        "${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}";

    // Construir la URL con los parámetros
    var urlStr =
        '${ApiConfig.baseUrl}/Dashboard/ReportesPorMunicipioPorFecha?fechaInicio=$fechaInicioStr&fechaFin=$fechaFinStr';

    // Añadir filtro por departamento si está especificado
    if (depaCodigo != null && depaCodigo.isNotEmpty && depaCodigo != 'Todos') {
      urlStr += '&Depa_Codigo=$depaCodigo';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data
              .map((item) => ReportePorMunicipio.fromJson(item))
              .toList();
        } else {
          print(
            'Estructura de respuesta inesperada para reportes por municipio por fecha: $jsonResponse',
          );
          return [];
        }
      } else {
        print(
          'Error HTTP al obtener reportes por municipio por fecha: ${response.statusCode}',
        );
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar reportes por municipio por fecha: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener reportes por municipio por fecha: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de departamentos para filtrado
  Future<List<Map<String, String>>> obtenerDepartamentos() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Dashboard/Departamentos');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Verificar si la respuesta tiene la estructura esperada
        if (jsonResponse.containsKey('data') &&
            jsonResponse['success'] == true &&
            jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          return data
              .map(
                (item) => {
                  'codigo': item['depaCodigo'] as String,
                  'nombre': item['depaNombre'] as String,
                },
              )
              .toList();
        } else {
          print(
            'Estructura de respuesta inesperada para departamentos: $jsonResponse',
          );
          return [];
        }
      } else {
        print('Error HTTP al obtener departamentos: ${response.statusCode}');
        print('Error body: ${response.body}');
        throw Exception(
          "Error al cargar departamentos: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Excepción al obtener departamentos: $e');
      rethrow;
    }
  }
}
