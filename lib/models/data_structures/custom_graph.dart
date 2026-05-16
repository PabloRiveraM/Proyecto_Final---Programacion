// lib/models/data_structures/custom_graph.dart
// Autor: Jose (8jose-gt) — feature/jose-grafo-compatibilidad
//
// Grafo de compatibilidad de hardware:
//
// NODOS: tipos de conectores/estándares (AM4, LGA1700, DDR4, DDR5, PCIe4.0, PCIe3.0, SATA, NVMe)
// ARISTAS: si dos piezas comparten el mismo conector/estándar, son COMPATIBLES → se crea una arista
//
// Ejemplo:
//   Ryzen 5 5600X (Socket: AM4) ──── ASUS B550 (Socket: AM4)   ✅ Compatible
//   Ryzen 5 5600X (Socket: AM4) ──── MSI PRO B660M (Socket: LGA1700)  ❌ Incompatible
//
// MÉTODO:
//   sonCompatibles(pieza1, pieza2) → bool
//   verificarEnsamble(piezas) → List<ConflictoCompatibilidad>

import '../api_models/item_model.dart';

class ConflictoCompatibilidad {
  final ItemModel piezaA;
  final ItemModel piezaB;
  final String motivo;

  ConflictoCompatibilidad({
    required this.piezaA,
    required this.piezaB,
    required this.motivo,
  });

  @override
  String toString() =>
      '${piezaA.nombre} ↔ ${piezaB.nombre}: $motivo';
}

class CompatibilityGraph {
  // Mapa: nombre del conector → lista de piezas que lo tienen
  final Map<String, List<ItemModel>> _nodos = {};

  // Adyacencia: id_pieza → Set de ids de piezas compatibles
  final Map<int, Set<int>> _aristas = {};

  // Registra la pieza en el grafo según sus conectores
  void agregarPieza(ItemModel pieza) {
    final conectores = _conectoresDe(pieza);
    for (final conector in conectores) {
      _nodos.putIfAbsent(conector, () => []).add(pieza);
      _aristas.putIfAbsent(pieza.id, () => {});
    }
    // Crear aristas con piezas que comparten el mismo conector
    for (final conector in conectores) {
      for (final otra in _nodos[conector]!) {
        if (otra.id != pieza.id) {
          _aristas[pieza.id]!.add(otra.id);
          _aristas.putIfAbsent(otra.id, () => {}).add(pieza.id);
        }
      }
    }
  }

  // Inserta múltiples piezas
  void agregarTodas(List<ItemModel> piezas) {
    for (final p in piezas) {
      agregarPieza(p);
    }
  }

  // ¿Dos piezas son compatibles entre sí?
  bool sonCompatibles(ItemModel a, ItemModel b) {
    // Si son de la misma categoría, no hay conflicto directo
    if (a.categoria == b.categoria) return true;

    // Solo revisar compatibilidad entre categorías que requieren conector común
    final parConflictivo = _esParConflictivo(a.categoria, b.categoria);
    if (!parConflictivo) return true;

    // Verificar si comparten algún conector (arista en el grafo)
    return _aristas[a.id]?.contains(b.id) ?? false;
  }

  // Verifica todo el ensamble y devuelve lista de conflictos
  List<ConflictoCompatibilidad> verificarEnsamble(List<ItemModel> piezas) {
    final conflictos = <ConflictoCompatibilidad>[];

    // Buscar procesador y motherboard (el par más crítico)
    final procesadores = piezas.where((p) =>
        p.categoria.toLowerCase() == 'procesador').toList();
    final motherboards = piezas.where((p) =>
        p.categoria.toLowerCase() == 'motherboard').toList();
    final rams = piezas.where((p) =>
        p.categoria.toLowerCase() == 'ram').toList();

    // Conflictos procesador ↔ motherboard
    for (final proc in procesadores) {
      for (final mb in motherboards) {
        if (!sonCompatibles(proc, mb)) {
          conflictos.add(ConflictoCompatibilidad(
            piezaA: proc,
            piezaB: mb,
            motivo: 'Socket incompatible: '
                '${_socketDe(proc)} ≠ ${_socketDe(mb)}',
          ));
        }
      }
    }

    // Conflictos RAM (tipo DDR) ↔ motherboard
    for (final ram in rams) {
      for (final mb in motherboards) {
        final tipoRam = _tipoRamDe(ram);
        final mbSoporta = _ramSoportadaPor(mb);
        if (tipoRam.isNotEmpty &&
            mbSoporta.isNotEmpty &&
            !mbSoporta.contains(tipoRam)) {
          conflictos.add(ConflictoCompatibilidad(
            piezaA: ram,
            piezaB: mb,
            motivo: 'Tipo de RAM incompatible: '
                '$tipoRam ≠ ${mbSoporta.join("/")}',
          ));
        }
      }
    }

    return conflictos;
  }

  // ── Helpers: extrae conectores de una pieza del catálogo ─────────────────
  Set<String> _conectoresDe(ItemModel pieza) {
    final cat = pieza.categoria.toLowerCase();
    final nombre = pieza.nombre.toLowerCase();
    final conectores = <String>{};

    if (cat == 'procesador') {
      if (nombre.contains('ryzen') || nombre.contains('amd')) {
        conectores.add('AM4');
      } else if (nombre.contains('intel') || nombre.contains('core i')) {
        conectores.add('LGA1700');
      }
    }

    if (cat == 'motherboard') {
      if (nombre.contains('b550') || nombre.contains('x570') ||
          nombre.contains('am4')) {
        conectores.addAll(['AM4', 'DDR4']);
      } else if (nombre.contains('b660') || nombre.contains('lga1700') ||
          nombre.contains('z690')) {
        conectores.addAll(['LGA1700', 'DDR5']);
      }
    }

    if (cat == 'ram') {
      if (nombre.contains('ddr4')) conectores.add('DDR4');
      if (nombre.contains('ddr5')) conectores.add('DDR5');
    }

    if (cat == 'tarjeta grafica') {
      conectores.add('PCIe');
    }

    if (cat == 'almacenamiento') {
      if (nombre.contains('nvme') || nombre.contains('m.2')) {
        conectores.add('NVMe');
      } else {
        conectores.add('SATA');
      }
    }

    return conectores;
  }

  String _socketDe(ItemModel pieza) {
    final nombre = pieza.nombre.toLowerCase();
    if (nombre.contains('ryzen') || nombre.contains('b550')) return 'AM4';
    if (nombre.contains('intel') || nombre.contains('i5-12') ||
        nombre.contains('b660')) return 'LGA1700';
    return 'Desconocido';
  }

  String _tipoRamDe(ItemModel ram) {
    final nombre = ram.nombre.toLowerCase();
    if (nombre.contains('ddr5')) return 'DDR5';
    if (nombre.contains('ddr4')) return 'DDR4';
    return '';
  }

  Set<String> _ramSoportadaPor(ItemModel mb) {
    final nombre = mb.nombre.toLowerCase();
    if (nombre.contains('b550')) {
      return {'DDR4'};
    }
    if (nombre.contains('b660')) {
      return {'DDR5'};
    }
    return {};
  }

  bool _esParConflictivo(String catA, String catB) {
    final pares = [
      {'procesador', 'motherboard'},
      {'ram', 'motherboard'},
    ];
    final a = catA.toLowerCase();
    final b = catB.toLowerCase();
    return pares.any((par) => par.contains(a) && par.contains(b));
  }

  // Lista de todos los nodos (conectores) del grafo
  List<String> get nodos => _nodos.keys.toList();

  // Número total de aristas
  int get totalAristas =>
      _aristas.values.fold(0, (s, set) => s + set.length) ~/ 2;
}
