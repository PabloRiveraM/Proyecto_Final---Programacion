// lib/models/data_structures/custom_queue.dart
// Autor: Diego (Apioide) — feature/diego-catalogo-arbol
// Cola (Queue) para la Wishlist de piezas.
// Implementación: nodos enlazados con referencias a frente y final.

class _QueueNode<T> {
  T data;
  _QueueNode<T>? next;
  _QueueNode({required this.data});
}

class CustomQueue<T> {
  _QueueNode<T>? _frente; // Primer elemento (el que sale primero)
  _QueueNode<T>? _final;  // Último elemento (el que entró último)
  int _size = 0;

  // Cantidad de elementos en la cola
  int get size => _size;

  // Verdadero si la cola está vacía
  bool get isEmpty => _frente == null;

  // ENQUEUE: Agregar un elemento al final de la cola
  void enqueue(T data) {
    final nuevoNodo = _QueueNode(data: data);
    if (_final == null) {
      _frente = nuevoNodo;
      _final = nuevoNodo;
    } else {
      _final!.next = nuevoNodo;
      _final = nuevoNodo;
    }
    _size++;
  }

  // DEQUEUE: Sacar y devolver el elemento del frente (el más antiguo)
  T? dequeue() {
    if (_frente == null) return null;
    final data = _frente!.data;
    _frente = _frente!.next;
    if (_frente == null) _final = null;
    _size--;
    return data;
  }

  // PEEK: Ver el frente sin sacarlo
  T? peek() => _frente?.data;

  // Convertir a lista de Dart (para mostrar en UI)
  List<T> toList() {
    final lista = <T>[];
    var temp = _frente;
    while (temp != null) {
      lista.add(temp.data);
      temp = temp.next;
    }
    return lista;
  }

  @override
  String toString() => toList().toString();
}
