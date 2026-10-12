import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _adding = false;

  Product get product => widget.product;

  Future<void> _addToCart() async {
    setState(() => _adding = true);

    final ok = await context.read<CartProvider>().addToCart(
          productId: product.id,
          vendorId: product.vendorId,
          price: product.price,
          quantity: 1,
        );

    if (!mounted) return;
    setState(() => _adding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Added to cart' : 'Could not add to cart'),
        duration: const Duration(seconds: 2),
        action: ok
            ? SnackBarAction(
                label: 'View cart',
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: Text(product.name, overflow: TextOverflow.ellipsis),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wl, _) {
              final inWishlist = wl.isWishlisted(product.id);
              return IconButton(
                icon: Icon(
                  inWishlist ? Icons.favorite : Icons.favorite_border,
                  color: inWishlist ? Colors.redAccent : Colors.white,
                ),
                tooltip: inWishlist ? 'Remove from wishlist' : 'Add to wishlist',
                onPressed: () async {
                  final nowIn =
                      await context.read<WishlistProvider>().toggle(product.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 1),
                        content: Text(
                          nowIn ? 'Added to wishlist' : 'Removed from wishlist',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(
              imageUrl: product.primaryImage,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade100),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade100,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(product.rating.toStringAsFixed(1)),
                    const SizedBox(width: 8),
                    Text('(${product.reviewCount} reviews)',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text('• ${product.soldCount} sold',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₦${_formatPrice(product.price)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A3D7C),
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        '₦${_formatPrice(product.comparePrice!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'per ${product.unitValue.toStringAsFixed(0)} ${product.unit}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      product.stockQuantity > 0
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: product.stockQuantity > 0
                          ? Colors.green
                          : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.stockQuantity > 0
                          ? 'In stock (${product.stockQuantity} available)'
                          : 'Out of stock',
                      style: TextStyle(
                        color: product.stockQuantity > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: const TextStyle(
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: product.stockQuantity > 0 && !_adding
                  ? _addToCart
                  : null,
              icon: _adding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_shopping_cart),
              label: Text(
                _adding ? 'Adding...' : 'Add to Cart',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D7C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}