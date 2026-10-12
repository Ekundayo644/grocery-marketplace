import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class WishlistService {
  WishlistService._();
  static final WishlistService instance = WishlistService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// All products the current user has wishlisted, joined with product data.
  Future<List<Product>> getWishlist() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('wishlists')
        .select('product_id, products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final result = <Product>[];
    for (final row in (data as List)) {
      final p = row['products'];
      if (p is Map<String, dynamic>) {
        result.add(Product.fromMap(p));
      }
    }
    return result;
  }

  /// Fetch just the product IDs the current user has wishlisted.
  /// Used to display the correct heart state on product cards.
  Future<Set<String>> getWishlistIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final data = await _client
        .from('wishlists')
        .select('product_id')
        .eq('user_id', userId);

    return (data as List).map((r) => r['product_id'] as String).toSet();
  }

  Future<void> addToWishlist(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    await _client.from('wishlists').upsert(
      {'user_id': userId, 'product_id': productId},
      onConflict: 'user_id,product_id',
    );
  }

  Future<void> removeFromWishlist(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    await _client
        .from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  /// Toggle: add if absent, remove if present. Returns true if now wishlisted.
  Future<bool> toggle(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final existing = await _client
        .from('wishlists')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing == null) {
      await addToWishlist(productId);
      return true;
    } else {
      await removeFromWishlist(productId);
      return false;
    }
  }
}