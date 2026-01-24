class SubcategoryModel {
  String id;
  String categoryId;
  String name;
  String slug;

  SubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoria_id': categoryId,
      'nome': name,
      'slug': slug,
    };
  }

  factory SubcategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubcategoryModel(
      id: documentId,
      categoryId: map['categoria_id'] ?? '',
      name: map['nome'] ?? '',
      slug: map['slug'] ?? '',
    );
  }
}
