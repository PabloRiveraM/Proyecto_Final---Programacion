// lib/models/data_structures/custom_tree.dart
// Autor: Diego (Apioide) — feature/diego-catalogo-arbol
// Árbol Binario de Búsqueda para organizar el catálogo de piezas.
//
// ESTRUCTURA:
//   Raíz: "PC"
//   Subárbol izquierdo: categorías de procesamiento (Procesador, Motherboard, RAM)
//   Subárbol derecho: categorías de salida/almacenamiento (Tarjeta Grafica, Almacenamiento, Fuente de Poder)
//
// RECORRIDO inOrder() → lista ordenada alfabéticamente por categoría.

import '../api_models/item_model.dart';

class TreeNode {
  final String categoria;
  final List<ItemModel> piezas;
  TreeNode? izquierdo;
  TreeNode? derecho;

  TreeNode({required this.categoria})
      : piezas = [];

  void agregarPieza(ItemModel pieza) => piezas.add(pieza);

  @override
  String toString() => 'TreeNode($categoria, ${piezas.length} piezas)';
}

class PCComponentTree {
  TreeNode? raiz;

  // Inserta una pieza en el árbol según su categoría.
  // Si el nodo de la categoría no existe, se crea.
  void insertar(ItemModel pieza) {
    raiz = _insertarEnNodo(raiz, pieza);
  }

  TreeNode _insertarEnNodo(TreeNode? nodo, ItemModel pieza) {
    if (nodo == null) {
      final nuevo = TreeNode(categoria: pieza.categoria);
      nuevo.agregarPieza(pieza);
      return nuevo;
    }

    final cmp = pieza.categoria.compareTo(nodo.categoria);
    if (cmp < 0) {
      nodo.izquierdo = _insertarEnNodo(nodo.izquierdo, pieza);
    } else if (cmp > 0) {
      nodo.derecho = _insertarEnNodo(nodo.derecho, pieza);
    } else {
      // Misma categoría: agregar pieza al nodo existente
      nodo.agregarPieza(pieza);
    }
    return nodo;
  }

  // Recorrido in-order: devuelve nodos ordenados alfabéticamente por categoría
  List<TreeNode> inOrder() {
    final resultado = <TreeNode>[];
    _inOrder(raiz, resultado);
    return resultado;
  }

  void _inOrder(TreeNode? nodo, List<TreeNode> resultado) {
    if (nodo == null) return;
    _inOrder(nodo.izquierdo, resultado);
    resultado.add(nodo);
    _inOrder(nodo.derecho, resultado);
  }

  // Devuelve todas las piezas del árbol como lista plana
  List<ItemModel> todasLasPiezas() {
    return inOrder().expand((nodo) => nodo.piezas).toList();
  }

  // Busca todas las piezas de una categoría específica
  List<ItemModel> buscarPorCategoria(String categoria) {
    final nodo = _buscarNodo(raiz, categoria);
    return nodo?.piezas ?? [];
  }

  TreeNode? _buscarNodo(TreeNode? nodo, String categoria) {
    if (nodo == null) return null;
    final cmp = categoria.compareTo(nodo.categoria);
    if (cmp < 0) return _buscarNodo(nodo.izquierdo, categoria);
    if (cmp > 0) return _buscarNodo(nodo.derecho, categoria);
    return nodo;
  }

  // Lista de categorías disponibles (orden in-order)
  List<String> categorias() => inOrder().map((n) => n.categoria).toList();

  bool get isEmpty => raiz == null;
}
