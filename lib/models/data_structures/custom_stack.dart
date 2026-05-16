class CustomStack<T> {
  // Usamos una lista privada de Dart como base para nuestra pila
  final List<T> _items = [];

  // PUSH: Agregar un elemento a la cima de la pila
  void push(T item) {
    _items.add(item);
  }

  // POP: Sacar y devolver el último elemento de la pila (Deshacer)
  T? pop() {
    if (_items.isEmpty) return null;
    return _items.removeLast();
  }

  // PEEK: Ver cuál es el último elemento sin sacarlo
  T? peek() {
    if (_items.isEmpty) return null;
    return _items.last;
  }

  // Saber si la pila está vacía (muy útil para bloquear el botón de Deshacer si no hay nada)
  bool get isEmpty => _items.isEmpty;

  // Convertir a lista para poder ver el historial en pantalla si fuera necesario
  List<T> toList() {
    // Lo retornamos al revés para que el último ingresado se vea de primero
    return List.from(_items.reversed); 
  }
}