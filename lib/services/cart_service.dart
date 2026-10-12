import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all cart items for the current user, joined with product info.
  Future<List<CartItem>> getCartItems() async {
    final userId = _client.auth.currentUser?.id;
    debugPrint('>>> [CartService.getCartItems] user=$userId');
    if (userId == null) return [];

    // Find the user's cart
    final cartRow = await _client
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    debugPrint('>>> [CartService.getCartItems] cartRow=$cartRow');
    if (cartRow == null) return [];
    final cartId = cartRow['id'] as String;

    final data = await _client
        .from('cart_items')
        .select(
            '*, products(name, description, images, unit, unit_value, stock_quantity, status)')
        .eq('cart_id', cartId)
        .order('added_at', ascending: false);

    debugPrint('>>> [CartService.getCartItems] fetched ${(data as List).length} rows');
    return (data).map((e) => CartItem.fromMap(e)).toList();
  }

  /// Add a product to the cart. If already present, increment quantity.
  Future<void> addToCart({
    required String productId,
    required String vendorId,
    required double price,
    int quantity = 1,
  }) async {
    debugPrint('>>> [CartService.addToCart] ENTER');
    debugPrint('    productId=$productId');
    debugPrint('    vendorId=$vendorId');
    debugPrint('    price=$price');
    debugPrint('    quantity=$quantity');

    final userId = _client.auth.currentUser?.id;
    debugPrint('>>> [CartService.addToCart] currentUserId=$userId');
    if (userId == null) throw Exception('Not signed in');

    // Get or create the user's cart
    final cartRow = await _client
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    debugPrint('>>> [CartService.addToCart] cartRow=$cartRow');

    String cartId;
    if (cartRow == null) {
      final created = await _client
          .from('carts')
          .insert({'user_id': userId})
          .select('id')
          .single();
      cartId = created['id'] as String;
      debugPrint('>>> [CartService.addToCart] created new cart $cartId');
    } else {
      cartId = cartRow['id'] as String;
    }

    // Is this product already in the cart?
    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('product_id', productId)
        .maybeSingle();

    debugPrint('>>> [CartService.addToCart] existing=$existing');

    if (existing != null) {
      final newQty = (existing['quantity'] as int) + quantity;
      await _client
          .from('cart_items')
          .update({'quantity': newQty})
          .eq('id', existing['id']);
      debugPrint('>>> [CartService.addToCart] updated quantity to $newQty');
    } else {
      try {
        final inserted = await _client
            .from('cart_items')
            .insert({
              'cart_id': cartId,
              'product_id': productId,
              'vendor_id': vendorId,
              'quantity': quantity,
              'price_snapshot': price,
            })
            .select()
            .single();
        debugPrint('>>> [CartService.addToCart] INSERTED: $inserted');
      } on PostgrestException catch (e) {
        debugPrint('>>> [CartService.addToCart] PostgrestException:');
        debugPrint('    message=${e.message}');
        debugPrint('    code=${e.code}');
        debugPrint('    details=${e.details}');
        debugPrint('    hint=${e.hint}');
        rethrow;
      }
    }
  }

  /// Update quantity of a cart item.
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    debugPrint('>>> [CartService.updateQuantity] id=$cartItemId qty=$quantity');
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    await _client
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  /// Remove a single item.
  Future<void> removeItem(String cartItemId) async {
    debugPrint('>>> [CartService.removeItem] id=$cartItemId');
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  /// Empty the current user's cart.
  Future<void> clearCart() async {
    debugPrint('>>> [CartService.clearCart] ENTER');
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final cartRow = await _client
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (cartRow == null) return;
    await _client.from('cart_items').delete().eq('cart_id', cartRow['id']);
    debugPrint('>>> [CartService.clearCart] cleared');
  }
}