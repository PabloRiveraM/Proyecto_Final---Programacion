// lib/models/data_structures/custom_hash_table.dart
// Autor: Jose (8jose-gt) — feature/jose-busqueda-hash
//
// Tabla Hash para búsqueda instantánea de piezas por su ID.
//
// ESTRUCTURA:
//   - Tamaño fijo de 'tableSize' cubetas (buckets)
//   - Función hash: id % tableSize
//   - Manejo de colisiones: encadenamiento (cada cubeta es una lista)
//   - Búsqueda: O(1) promedio

import '../api_models/item_model.dart';

class _HashEntry {
  final int clave; // ID de la pieza
  final ItemModel valor;
  _HashEntry({required this.clave, required this.valor});
}

class CustomHashTable {
  static const int tableSize = 16; // Tamaño de la tabla hash

  // La tabla: lista de listas (encadenamiento para colisiones)
  final List<List<_HashEntry>> _tabla;

  CustomHashTable()
      : _tabla = List.generate(tableSize, (_) => []);

  // FUNCIÓN HASH: mapea el ID a un índice de la tabla
  int _hash(int id) => id % tableSize;

  // INSERT: insertar o actualizar una pieza
  void insertar(ItemModel pieza) {
    final indice = _hash(pieza.id);
    final cubeta = _tabla[indice];

    // Si ya existe, actualiza (evita duplicados)
    for (int i = 0; i < cubeta.length; i++) {
      if (cubeta[i].clave == pieza.id) {
        cubeta[i] = _HashEntry(clave: pieza.id, valor: pieza);
        return;
      }
    }
    cubeta.add(_HashEntry(clave: pieza.id, valor: pieza));
  }

  // SEARCH: buscar por ID — O(1) promedio
  ItemModel? buscarPorId(int id) {
    final indice = _hash(id);
    final cubeta = _tabla[indice];
    for (final entrada in cubeta) {
      if (entrada.clave == id) return entrada.valor;
    }
    return null; // No encontrado
  }

  // SEARCH por nombre (búsqueda lineal — O(n), alternativa a buscar por ID)
  List<ItemModel> buscarPorNombre(String query) {
    final resultados = <ItemModel>[];
    final queryLower = query.toLowerCase();
    for (final cubeta in _tabla) {
      for (final entrada in cubeta) {
        if (entrada.valor.nombre.toLowerCase().contains(queryLower) ||
            entrada.valor.categoria.toLowerCase().contains(queryLower)) {
          resultados.add(entrada.valor);
        }
      }
    }
    return resultados;
  }

  // Insertar múltiples piezas de una vez
  void insertarTodas(List<ItemModel> piezas) {
    for (final pieza in piezas) {
      insertar(pieza);
    }
  }

  // Todas las piezas en la tabla
  List<ItemModel> todasLasPiezas() {
    return _tabla.expand((c) => c.map((e) => e.valor)).toList();
  }

  bool get isEmpty => _tabla.every((c) => c.isEmpty);

  int get size => _tabla.fold(0, (s, c) => s + c.length);

  // Info de colisiones (para visualización educativa)
  Map<String, int> infoColisiones() {
    int maxColision = 0;
    int totalColisiones = 0;
    for (final cubeta in _tabla) {
      if (cubeta.length > 1) {
        totalColisiones += cubeta.length - 1;
        if (cubeta.length > maxColision) maxColision = cubeta.length;
      }
    }
    return {
      'totalColisiones': totalColisiones,
      'maxPorCubeta': maxColision,
      'cubetasUsadas': _tabla.where((c) => c.isNotEmpty).length,
    };
  }
}
