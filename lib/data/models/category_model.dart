// lib/data/models/category_model.dart
class CategoryModel {
  final int? id;
  final String name;
  final int displayOrder;
  final String? colorHex; // NOUVEAU

  CategoryModel({
    this.id,
    required this.name,
    required this.displayOrder,
    this.colorHex, // NOUVEAU
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_order': displayOrder,
      'color_hex': colorHex, // NOUVEAU
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      displayOrder: map['display_order'],
      colorHex: map['color_hex'], // NOUVEAU
    );
  }
}
