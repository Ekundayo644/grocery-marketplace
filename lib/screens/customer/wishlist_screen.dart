import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wl = context.watch<WishlistProvider>();

    if (wl.loading && wl.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wl.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Your wishlist is empty',
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            SizedBox(height: 4),
            Text('Tap the heart on any product to save it here',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<WishlistProvider>().loadProducts(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        itemCount: wl.products.length,
        itemBuilder: (context, i) {
          final p = wl.products[i];
          return ProductCard(
            product: p,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            ),
          );
        },
      ),
    );
  }
}