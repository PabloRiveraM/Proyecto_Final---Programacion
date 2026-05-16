// lib/core/app_state.dart
// Estado compartido entre todas las pantallas (Singleton)
// Evita pasar datos entre widgets manualmente.
//
// ESTRUCTURAS USADAS:
//   - ensamble     : CustomLinkedList<ItemModel>  → Marly
//   - historial    : CustomStack<ItemModel>        → Marly
//   - wishlist     : CustomQueue<ItemModel>        → Diego
//   - hashTable    : CustomHashTable<ItemModel>    → Jose (se inicializa en search_screen)

import '../models/api_models/item_model.dart';
import '../models/data_structures/custom_list.dart';
import '../models/data_structures/custom_stack.dart';
import '../models/data_structures/custom_queue.dart';

class AppState {
  // Singleton
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Marly — Ensamble actual
  final CustomLinkedList<ItemModel> ensamble = CustomLinkedList<ItemModel>();
  final CustomStack<ItemModel> historial = CustomStack<ItemModel>();

  // Diego — Wishlist
  final CustomQueue<ItemModel> wishlist = CustomQueue<ItemModel>();

  // Listeners para notificar a los widgets cuando el estado cambia
  final List<void Function()> _listeners = [];

  void addListener(void Function() fn) => _listeners.add(fn);
  void removeListener(void Function() fn) => _listeners.remove(fn);
  void notificar() {
    for (final fn in _listeners) {
      fn();
    }
  }

  // === Operaciones del Ensamble (Marly) ===

  void agregarAlEnsamble(ItemModel pieza) {
    ensamble.insert(pieza);
    historial.push(pieza);
    notificar();
  }

  void eliminarDelEnsamble(ItemModel pieza) {
    ensamble.delete(pieza);
    notificar();
  }

  ItemModel? deshacer() {
    final pieza = historial.pop();
    if (pieza != null) {
      ensamble.delete(pieza);
      notificar();
    }
    return pieza;
  }

  // === Operaciones de Wishlist (Diego) ===

  void agregarAWishlist(ItemModel pieza) {
    wishlist.enqueue(pieza);
    notificar();
  }

  ItemModel? comprarDesdWishlist() {
    final pieza = wishlist.dequeue();
    if (pieza != null) {
      agregarAlEnsamble(pieza);
    }
    return pieza;
  }

  // === Totales ===

  double get totalPrecioEnsamble =>
      ensamble.toList().fold(0.0, (s, p) => s + p.precio);

  int get totalWattsEnsamble =>
      ensamble.toList().fold(0, (s, p) => s + p.watts);

  Map<String, double> get gastoPorCategoria {
    final mapa = <String, double>{};
    for (final p in ensamble.toList()) {
      mapa[p.categoria] = (mapa[p.categoria] ?? 0.0) + p.precio;
    }
    return mapa;
  }
}
