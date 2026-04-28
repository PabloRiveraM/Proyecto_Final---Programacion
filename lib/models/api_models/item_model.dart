class ItemModel {
  final int id;
  final String nombre;
  final String categoria;
  final int watts;
  final double precio;

  ItemModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.watts,
    required this.precio,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: _parseInt(json['id']),
      nombre: json['nombre']?.toString() ?? 'Desconocido',
      categoria: json['categoria']?.toString() ?? 'General',
      watts: _parseInt(json['watts']),
      precio: _parseDouble(json['precio']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'watts': watts,
      'precio': precio,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() {
    return '$nombre ($categoria) - ${watts}W - Q$precio';
  }
}