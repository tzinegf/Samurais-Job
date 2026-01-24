class CatalogServiceModel {
  String id;
  String subcategoryId;
  String name;
  String slug;
  String shortDescription;
  bool active;

  CatalogServiceModel({
    required this.id,
    required this.subcategoryId,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.active,
  });

  Map<String, dynamic> toMap() {
    return {
      'subcategoria_id': subcategoryId,
      'nome': name,
      'slug': slug,
      'descricao_curta': shortDescription,
      'ativo': active,
    };
  }

  factory CatalogServiceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CatalogServiceModel(
      id: documentId,
      subcategoryId: map['subcategoria_id'] ?? '',
      name: map['nome'] ?? '',
      slug: map['slug'] ?? '',
      shortDescription: map['descricao_curta'] ?? '',
      active: map['ativo'] ?? true,
    );
  }
}
