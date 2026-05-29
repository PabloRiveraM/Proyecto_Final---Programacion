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

  // === Autenticación (Mock Local) ===
  String? currentUser;
  final Map<String, String> _usuariosRegistrados = {
    'admin@admin.com': 'admin123' // Usuario por defecto
  };

  bool get isLogged => currentUser != null;

  bool login(String email, String password) {
    if (_usuariosRegistrados.containsKey(email) && _usuariosRegistrados[email] == password) {
      currentUser = email;
      notificar();
      return true;
    }
    return false;
  }

  bool register(String email, String password) {
    if (_usuariosRegistrados.containsKey(email)) {
      return false; // Ya existe
    }
    _usuariosRegistrados[email] = password;
    currentUser = email;
    notificar();
    return true;
  }

  void logout() {
    currentUser = null;
    // Limpiar estado al cerrar sesión
    while (ensamble.head != null) {
      ensamble.delete(ensamble.head!.data);
    }
    while (historial.pop() != null) {}
    while (wishlist.dequeue() != null) {}
    notificar();
  }

  // === Operaciones del Ensamble (Marly) ===

  String? agregarAlEnsamble(ItemModel pieza) {
    final cat = pieza.categoria.toLowerCase();
    if (cat == 'procesador' || cat == 'motherboard') {
      final yaExiste = ensamble.toList().any((p) => p.categoria.toLowerCase() == cat);
      if (yaExiste) {
        return 'Ya hay un $cat en el ensamble. Solo se permite uno.';
      }
    }
    ensamble.insert(pieza);
    historial.push(pieza);
    notificar();
    return null;
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

  String? comprarDesdWishlist() {
    final pieza = wishlist.peek();
    if (pieza != null) {
      final error = agregarAlEnsamble(pieza);
      if (error != null) {
        return error;
      }
      wishlist.dequeue();
      return null;
    }
    return 'Wishlist vacía';
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
