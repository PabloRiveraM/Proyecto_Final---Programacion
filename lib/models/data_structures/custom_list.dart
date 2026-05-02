// lib/models/data_structures/custom_list.dart

class Node<T> {
  T data;
  Node<T>? next;
  Node({required this.data, this.next});
}

class CustomLinkedList<T> {
  Node<T>? head;
  int _size = 0;

  // Cantidad de nodos en la lista
  int get size => _size;

  // Verdadero si la lista está vacía
  bool get isEmpty => head == null;

  // Insertar al final de la lista
  void insert(T data) {
    Node<T> newNode = Node(data: data);
    if (head == null) {
      head = newNode;
    } else {
      Node<T> temp = head!;
      while (temp.next != null) {
        temp = temp.next!;
      }
      temp.next = newNode;
    }
    _size++;
  }

  // Eliminar un nodo por igualdad de dato
  void delete(T data) {
    if (head == null) return;
    if (head!.data == data) {
      head = head!.next;
      _size--;
      return;
    }
    Node<T> temp = head!;
    while (temp.next != null && temp.next!.data != data) {
      temp = temp.next!;
    }
    if (temp.next != null) {
      temp.next = temp.next!.next;
      _size--;
    }
  }

  // Eliminar el último nodo (para la operación Deshacer)
  T? removeLast() {
    if (head == null) return null;
    if (head!.next == null) {
      T data = head!.data;
      head = null;
      _size--;
      return data;
    }
    Node<T> temp = head!;
    while (temp.next!.next != null) {
      temp = temp.next!;
    }
    T data = temp.next!.data;
    temp.next = null;
    _size--;
    return data;
  }

  // Convertir la lista a un List de Dart para mostrar en pantalla
  List<T> toList() {
    List<T> items = [];
    Node<T>? temp = head;
    while (temp != null) {
      items.add(temp.data);
      temp = temp.next;
    }
    return items;
  }
}