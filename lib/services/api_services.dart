import 'dart:convert';
import 'package:http/http.dart' as http;
// Asegúrate de que la ruta coincida con tu proyecto
import '../models/api_models/item_model.dart'; 

class ApiService {
  // URL base de la API (Puedes cambiarla a la de Pokemon o la que elijan)
  static const String baseUrl = '[https://rickandmortyapi.com/api/character](https://rickandmortyapi.com/api/character)';

  /// Método para obtener una lista de datos desde la API
  static Future<List<ItemModel>> fetchData() async {
    try {
      // Hacemos la petición GET a la API
      final response = await http.get(Uri.parse(baseUrl));

      // Si el servidor responde con 200 (OK)
      if (response.statusCode == 200) {
        // Decodificamos el texto JSON a un Mapa de Dart
        final Map<String, dynamic> decodedData = json.decode(response.body);
        
        // La API de Rick&Morty guarda la lista dentro de "results"
        final List<dynamic> results = decodedData['results'];

        // Convertimos cada elemento del JSON a nuestro ItemModel
        return results.map((item) => ItemModel.fromJson(item)).toList();
      } else {
        // Si hay un error de servidor, lanzamos una excepción
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al conectar con la API: $e');
      return []; // Retornamos lista vacía en caso de error para no quebrar la app
    }
  }
}