class CartItem {
  final String id;
  final String cartId;
  final String productId;
  final String vendorId;
  final int quantity;
  final double priceSnapshot;
  final DateTime addedAt;

  // Joined from products table
  final String productName;
  final String? productDescription;
  final List<String> productImages;
  final String productUnit;
  final double productUnitValue;
  final int stockQuantity;
  final bool productActive;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.vendorId,
    required this.quantity,
    required this.priceSnapshot,
    required this.addedAt,
    required this.productName,
    this.productDescription,
    required this.productImages,
    required this.productUnit,
    required this.productUnitValue,
    required this.stockQuantity,
    required this.productActive,
  });

  double get lineTotal => priceSnapshot * quantity;

  String get primaryImage => productImages.isNotEmpty
      ? productImages.first
      : 'https://picsum.photos/seed/placeholder/400/400';

  factory CartItem.fromMap(Map<String, dynamic> m) {
    final product = m['products'] as Map<String, dynamic>?;
    final rawImages = product?['images'];
    List<String> imgs = [];
    if (rawImages is List) {
      imgs = rawImages.map((e) => e.toString()).toList();
    }

    return CartItem(
      id: m['id'] as String,
      cartId: m['cart_id'] as String,
      productId: m['product_id'] as String,
      vendorId: m['vendor_id'] as String,
      quantity: (m['quantity'] as num).toInt(),
      priceSnapshot: (m['price_snapshot'] as num).toDouble(),
      addedAt: DateTime.parse(m['added_at'] as String),
      productName: (product?['name'] ?? 'Unknown product') as String,
      productDescription: product?['description'] as String?,
      productImages: imgs,
      productUnit: (product?['unit'] ?? 'piece') as String,
      productUnitValue: ((product?['unit_value'] ?? 1) as num).toDouble(),
      stockQuantity: ((product?['stock_quantity'] ?? 0) as num).toInt(),
      productActive: (product?['status'] ?? 'active') == 'active',
    );
  }
}