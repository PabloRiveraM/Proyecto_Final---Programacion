class Node<T> {
  T data;
  Node<T>? next;
  Node({required this.data, this.next});
}

class CustomLinkedList<T> {
  Node<T>? head;

  void insert(T data) {
    Node<T> newNode = Node(data: data);
    if (head == null) {
      head = newNode;
    } else {
      Node<T> temp = head!;
      while (temp.next != null) {
        temp = temp.next;
      }
      temp.next = newNode;
    }
  }

  void delete(T data) {
    if (head == null) return;
    if (head!.data == data) {
      head = head!.next;
      return;
    }
    Node<T> temp = head!;
    while (temp.next != null && temp.next!.data != data) {
      temp = temp.next!;
    }
    if (temp.next != null) {
      temp.next = temp.next!.next;
    }
  }

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