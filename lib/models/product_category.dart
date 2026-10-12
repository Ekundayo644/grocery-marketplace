class ProductCategory {
  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String? icon;
  final String? image;
  final int displayOrder;
  final bool isActive;

  ProductCategory({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    this.icon,
    this.image,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> m) {
    return ProductCategory(
      id: m['id'] as String,
      parentId: m['parent_id'] as String?,
      name: m['name'] as String,
      slug: m['slug'] as String,
      icon: m['icon'] as String?,
      image: m['image'] as String?,
      displayOrder: (m['display_order'] ?? 0) as int,
      isActive: (m['is_active'] ?? true) as bool,
    );
  }
}