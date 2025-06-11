// lib/data/models/category_model.dart
class CategoryModel {
  CategoryModel({
    required this.name,
    required this.displayOrder,
    this.id,
    this.colorHex,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      name: map['name'] as String,
      displayOrder: map['display_order'] as int,
      id: map['id'] as int,
      colorHex: map['color_hex'] as String,
    );
  }

  final String name;
  final int displayOrder;
  final int? id;
  final String? colorHex;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_order': displayOrder,
      'color_hex': colorHex, // NOUVEAU
    };
  }
}
