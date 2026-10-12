class Product {
  final String id;
  final String vendorId;
  final String categoryId;
  final String name;
  final String slug;
  final String? description;
  final String unit;
  final double unitValue;
  final double price;
  final double? comparePrice;
  final int stockQuantity;
  final bool isPerishable;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final String status;

  Product({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    required this.unit,
    required this.unitValue,
    required this.price,
    this.comparePrice,
    required this.stockQuantity,
    required this.isPerishable,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.status,
  });

  /// First image URL, or a fallback placeholder.
  String get primaryImage =>
      images.isNotEmpty ? images.first : 'https://picsum.photos/seed/placeholder/400/400';

  /// True when a compare price exists and is higher than the current price.
  bool get hasDiscount =>
      comparePrice != null && comparePrice! > price;

  /// Percentage discount, e.g. 20 for 20% off.
  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((comparePrice! - price) / comparePrice!) * 100).round();
  }

  factory Product.fromMap(Map<String, dynamic> m) {
    final rawImages = m['images'];
    List<String> imgs = [];
    if (rawImages is List) {
      imgs = rawImages.map((e) => e.toString()).toList();
    }

    return Product(
      id: m['id'] as String,
      vendorId: m['vendor_id'] as String,
      categoryId: m['category_id'] as String,
      name: m['name'] as String,
      slug: m['slug'] as String,
      description: m['description'] as String?,
      unit: (m['unit'] ?? 'piece') as String,
      unitValue: (m['unit_value'] as num).toDouble(),
      price: (m['price'] as num).toDouble(),
      comparePrice: m['compare_price'] == null
          ? null
          : (m['compare_price'] as num).toDouble(),
      stockQuantity: (m['stock_quantity'] ?? 0) as int,
      isPerishable: (m['is_perishable'] ?? false) as bool,
      images: imgs,
      rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (m['review_count'] ?? 0) as int,
      soldCount: (m['sold_count'] ?? 0) as int,
      status: (m['status'] ?? 'draft') as String,
    );
  }
}