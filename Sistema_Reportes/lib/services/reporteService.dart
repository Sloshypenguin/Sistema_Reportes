import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reporteViewModel.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

class ReporteService {
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Lista todos los reportes disponibles desde la API
  Future<List<Reporte>> listarReportes() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (!hasConnection) {
      throw Exception("Sin conexión a internet");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/Reporte/Listar');

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: ApiConfig.headers,);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];

      return data.map((json) => Reporte.fromJson(json)).toList();
    } else {
      throw Exception("Error al cargar reportes: ${response.statusCode}");
    }
  }
}
