// Archivo: lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/api_models/item_model.dart';
import '../api_key.dart';

class ApiService {
  // URL de la API de Groq
  static const String baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // API Key de Groq (proyecto en equipo)
  static const String apiKey = groqApiKey;

  // Timeout para no quedarnos colgados si Groq no responde
  static const Duration timeout = Duration(seconds: 30);

  // =========================================================================
  // MÉTODO 1: Obtener piezas del catálogo
  // =========================================================================
  static Future<List<ItemModel>> fetchData() async {
    try {
      // 1. Cargar el JSON desde los assets locales
      final String response = await rootBundle.loadString(
        'assets/inventory.json',
      );

      // 2. Decodificar el JSON
      final data = await json.decode(response);
      final List<dynamic> results = data['results'];

      // 3. Mapear a modelos
      return results.map((item) => ItemModel.fromJson(item)).toList();
    } catch (e) {
      print('Error al cargar el inventario local: $e');
      return [];
    }
  }

  // =========================================================================
  // MÉTODO 2: Verificar compatibilidad de piezas seleccionadas
  // =========================================================================
  /// Recibe una lista de piezas que el usuario eligió y devuelve
  /// un análisis de compatibilidad generado por la IA.
  static Future<Map<String, dynamic>> checkCompatibility(
    List<ItemModel> piezasSeleccionadas,
  ) async {
    try {
      // 1. Cargar el inventario local para enviarlo como contexto a la IA
      final String inventarioString = await rootBundle.loadString(
        'assets/inventory.json',
      );

      // 2. Convertir las piezas seleccionadas a texto legible
      final String listaPiezas = piezasSeleccionadas.isEmpty
          ? "(Ninguna pieza seleccionada actualmente)"
          : piezasSeleccionadas
                .map(
                  (p) =>
                      '- ID: ${p.id} | ${p.nombre} (${p.categoria}, ${p.watts}W, Q${p.precio})',
                )
                .join('\n');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              "model": "llama-3.3-70b-versatile",
              "temperature": 0.2,
              "response_format": {"type": "json_object"},
              "messages": [
                {
                  "role": "system",
                  "content":
                      """
              Eres un experto en hardware de computadoras. Tu trabajo es analizar 
              la compatibilidad de un conjunto de piezas seleccionadas por el usuario, 
              y SI ES NECESARIO, sugerir piezas de nuestro inventario para completar o mejorar el ensamble.
              
              INVENTARIO DISPONIBLE (JSON):
              $inventarioString

              REGLAS DE COMPATIBILIDAD Y ENSAMBLE:
              1. SOCKET: El procesador y la motherboard deben coincidir (AM4 con AM4, LGA1700 con LGA1700).
                 - Los Ryzen Serie 5000 usan AM4.
                 - Los Intel Core Serie 12000 y 13000 usan LGA1700.
              2. RAM: La motherboard debe soportar el tipo de RAM (DDR4 o DDR5).
                 - Placas B550/X570 suelen usar DDR4.
                 - Placas Z690/B660 pueden usar DDR4 o DDR5 (asume la compatibilidad lógica de acuerdo al inventario).
              3. WATTS: La fuente de poder debe ser al menos 20% mayor al total de watts de los componentes.
              4. PIEZAS FALTANTES: Una PC completa DEBE tener: Procesador, Motherboard, RAM, Tarjeta Grafica (si aplica), Almacenamiento y Fuente de Poder.

              INSTRUCCIÓN DE RECOMENDACIÓN:
              Si a la lista de piezas del usuario le faltan categorías para ser una PC completa,
              o hay una incompatibilidad clara que requiera cambiar una pieza, RECOMIENDA las piezas necesarias
              **sacadas estrictamente del INVENTARIO DISPONIBLE proporcionado**. Muestra la sugerencia en formato de texto claro.

              Responde SOLO con un JSON con este formato exacto:
              {
                "compatible": true/false,
                "wattsTotal": numero,
                "wattsFuente": numero,
                "precioTotal": numero,
                "problemas": ["lista de problemas encontrados o piezas incompatibles"],
                "sugerencias": ["lista de recomendaciones detalladas de piezas faltantes o cambios sugeridos (incluyendo el ID de la pieza del inventario)"],
                "resumen": "Un resumen breve del análisis"
              }
              
              Si no hay problemas, "problemas" debe ser un arreglo vacío [].
              Asegúrate de que las sugerencias de piezas correspondan EXACTAMENTE a los nombres y especificaciones del inventario.
              NO respondas con texto conversacional. Solo JSON.
              """,
                },
                {
                  "role": "user",
                  "content":
                      "Analiza la compatibilidad de estas piezas que tengo seleccionadas:\n$listaPiezas",
                },
              ],
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final String iaContent =
            decodedData['choices'][0]['message']['content'];
        final Map<String, dynamic> resultado = json.decode(iaContent);
        return resultado;
      } else {
        print(
          'Groq respondió con código ${response.statusCode}: ${response.body}',
        );
        return _errorCompatibilidad(
          'Error del servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en verificación de compatibilidad: $e');
      return _errorCompatibilidad('No se pudo conectar con la IA: $e');
    }
  }

  // Helper para retornar un resultado de error con el mismo formato
  static Map<String, dynamic> _errorCompatibilidad(String mensaje) {
    return {
      'compatible': false,
      'wattsTotal': 0,
      'wattsFuente': 0,
      'precioTotal': 0,
      'problemas': [mensaje],
      'sugerencias': [],
      'resumen': 'Error al analizar compatibilidad.',
    };
  }
}
