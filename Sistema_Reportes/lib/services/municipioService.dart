import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/municipioViewModel.dart';
import '../config/api_config.dart';
import '../services/connectivityService.dart';

class MunicipioService {
  final ConnectivityService _connectivityService = ConnectivityService();

 Future<List<Municipio>> listarPorDepartamento(String depaCodigo) async {
  final hasConnection = await _connectivityService.hasConnection();
  if (!hasConnection) {
    throw Exception("Sin conexión a internet");
  }

  final url = Uri.parse('${ApiConfig.baseUrl}/Municipios/Buscar');

  final body = json.encode({
    'depa_Codigo': depaCodigo,
  });

  final headers = {
    'Content-Type': 'application/json',
  };

  final response = await http.post(
    url,
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = json.decode(response.body);
    return jsonData.map((json) => Municipio.fromJson(json)).toList();
  } else {
    throw Exception("Error al cargar municipios");
  }
}

}
