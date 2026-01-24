class CategoryModel {
  String id;
  String name;
  String slug;
  String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': name,
      'slug': slug,
      'icone': icon,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      name: map['nome'] ?? '',
      slug: map['slug'] ?? '',
      icon: map['icone'] ?? '',
    );
  }
}
