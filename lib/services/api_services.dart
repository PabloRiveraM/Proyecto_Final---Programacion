// Archivo: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models/item_model.dart'; 
import '../api_key.dart'; 

class ApiService {
  // URL de la API de Groq
    static const String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // API Key de Groq (proyecto en equipo)
  static const String apiKey = groqApiKey;

  // Timeout para no quedarnos colgados si Groq no responde
  static const Duration timeout = Duration(seconds: 30);

  // === CATÁLOGO OFICIAL (CONTEXTO RAG) ===
  // Este es el catálogo oficial que la IA debe respetar.
  static const String catalogoOficial = """
  1. AMD Ryzen 5 5600X | Categoria: Procesador | Socket: AM4 | Watts: 65 | Precio: 150
  2. Intel Core i5-12400F | Categoria: Procesador | Socket: LGA1700 | Watts: 65 | Precio: 140
  3. NVIDIA RTX 3060 | Categoria: Tarjeta Grafica | Watts: 170 | Precio: 300
  4. AMD Radeon RX 6600 | Categoria: Tarjeta Grafica | Watts: 132 | Precio: 200
  5. ASUS B550 | Categoria: Motherboard | Socket: AM4 | Watts: 40 | Precio: 120
  6. MSI PRO B660M | Categoria: Motherboard | Socket: LGA1700 | Watts: 45 | Precio: 110
  7. Corsair Vengeance 16GB DDR4 | Categoria: RAM | Tipo: DDR4 | Watts: 10 | Precio: 50
  8. Kingston Fury 16GB DDR5 | Categoria: RAM | Tipo: DDR5 | Watts: 12 | Precio: 75
  9. EVGA 600W 80+ Bronze | Categoria: Fuente de Poder | Capacidad: 600 | Watts: 0 | Precio: 60
  10. Corsair RM750 80+ Gold | Categoria: Fuente de Poder | Capacidad: 750 | Watts: 0 | Precio: 95
  11. Kingston NV2 1TB NVMe | Categoria: Almacenamiento | Watts: 5 | Precio: 45
  12. WD Blue 2TB HDD | Categoria: Almacenamiento | Watts: 8 | Precio: 55
  """;

  // =========================================================================
  // MÉTODO 1: Obtener piezas del catálogo
  // =========================================================================
  static Future<List<ItemModel>> fetchData() async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama3-8b-8192",
          "temperature": 0.0, // Determinista: no inventa datos
          "response_format": {"type": "json_object"},
          "messages": [
            {
              "role": "system",
              "content": """
              Eres el sistema interno de una aplicación de ensamble de PC.
              Aquí tienes el catálogo oficial de productos:
              $catalogoOficial
              
              TAREA: Devuelve un objeto JSON que contenga una propiedad llamada "results".
              Esa propiedad debe ser un arreglo con TODOS los productos del catálogo.
              
              FORMATO ESTRICTO DE CADA OBJETO:
              {
                "id": numero,
                "nombre": "texto",
                "categoria": "texto",
                "watts": numero,
                "precio": numero
              }
              NO inventes componentes. NO respondas con texto conversacional.
              Solo devuelve el JSON.
              """
            }
          ]
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        
        // Groq: choices[0].message.content contiene el JSON de la IA
        final String iaContent = decodedData['choices'][0]['message']['content'];
        final Map<String, dynamic> finalJson = json.decode(iaContent);
        final List<dynamic> results = finalJson['results'];

        return results.map((item) => ItemModel.fromJson(item)).toList();
      } else {
        // Incluimos el body del error para depuración
        print('Groq respondió con código ${response.statusCode}: ${response.body}');
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al conectar con la API de Groq: $e');
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
      // Convertimos las piezas a texto legible para la IA
      final String listaPiezas = piezasSeleccionadas
          .map((p) => '- ${p.nombre} (${p.categoria}, ${p.watts}W, Q${p.precio})')
          .join('\n');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama3-8b-8192",
          "temperature": 0.0,
          "response_format": {"type": "json_object"},
          "messages": [
            {
              "role": "system",
              "content": """
              Eres un experto en hardware de computadoras. Tu trabajo es analizar 
              la compatibilidad de un conjunto de piezas para ensamblar una PC.
              
              Catálogo de referencia con especificaciones:
              $catalogoOficial

              REGLAS DE COMPATIBILIDAD:
              1. SOCKET: El procesador y la motherboard deben tener el mismo socket
                 (ejemplo: AM4 con AM4, LGA1700 con LGA1700).
              2. RAM: El tipo de RAM debe ser compatible con la motherboard
                 (ejemplo: DDR4 con motherboards que soporten DDR4).
              3. WATTS: La fuente de poder debe cubrir al menos el total de watts 
                 de todos los componentes con un 20% de margen de seguridad.
              4. COMPONENTES DUPLICADOS: No debería haber dos procesadores, 
                 dos motherboards, ni dos fuentes de poder.
              5. PIEZAS FALTANTES: Una PC necesita mínimo: Procesador, Motherboard, 
                 RAM, Almacenamiento y Fuente de Poder.

              Responde SOLO con un JSON con este formato:
              {
                "compatible": true/false,
                "wattsTotal": numero,
                "wattsFuente": numero,
                "precioTotal": numero,
                "problemas": ["lista de problemas encontrados"],
                "sugerencias": ["lista de sugerencias para mejorar"],
                "resumen": "Un resumen breve del análisis"
              }
              
              Si no hay problemas, "problemas" debe ser un arreglo vacío [].
              NO respondas con texto conversacional. Solo JSON.
              """
            },
            {
              "role": "user",
              "content": "Analiza la compatibilidad de estas piezas:\n$listaPiezas"
            }
          ]
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final String iaContent = decodedData['choices'][0]['message']['content'];
        final Map<String, dynamic> resultado = json.decode(iaContent);
        return resultado;
      } else {
        print('Groq respondió con código ${response.statusCode}: ${response.body}');
        return _errorCompatibilidad('Error del servidor: ${response.statusCode}');
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