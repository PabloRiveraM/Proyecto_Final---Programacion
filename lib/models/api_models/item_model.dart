class ItemModel {
  final int id;
  final String name;
  final String status;
  final String imageUrl;

  ItemModel({
    required this.id,
    required this.name,
    required this.status,
    required this.imageUrl,
  });

  // Este método "fábrica" toma el JSON de internet y lo convierte en un objeto de Dart
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Desconocido',
      status: json['status'] ?? 'Desconocido',
      imageUrl: json['image'] ?? '',
    );
  }

  // Útil para imprimir en consola y ver si funciona
  @override
  String toString() {
    return 'ItemModel(id: $id, name: $name)';
  }
}