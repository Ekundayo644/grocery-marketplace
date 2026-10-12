import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _svc = CartService.instance;

  List<CartItem> _items = [];
  bool _loading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  int get itemCount => _items.fold(0, (sum, it) => sum + it.quantity);
  double get subtotal => _items.fold(0.0, (sum, it) => sum + it.lineTotal);
  bool get isEmpty => _items.isEmpty;

  Future<void> loadCart() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _svc.getCartItems();
      debugPrint('>>> [CartProvider.loadCart] loaded ${_items.length} items');
    } catch (e, st) {
      _error = e.toString();
      debugPrint('>>> [CartProvider.loadCart] ERROR: $e');
      debugPrint('>>> stack: $st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart({
    required String productId,
    required String vendorId,
    required double price,
    int quantity = 1,
  }) async {
    debugPrint('>>> [CartProvider.addToCart] ENTER');
    debugPrint('    productId=$productId');
    debugPrint('    vendorId=$vendorId');
    debugPrint('    price=$price');
    debugPrint('    quantity=$quantity');

    // Log who is signed in at the moment the user taps
    final currentUser = Supabase.instance.client.auth.currentUser;
    debugPrint('>>> [CartProvider.addToCart] currentUser='
        '${currentUser == null ? "NOT SIGNED IN" : currentUser.id}');

    try {
      await _svc.addToCart(
        productId: productId,
        vendorId: vendorId,
        price: price,
        quantity: quantity,
      );
      debugPrint('>>> [CartProvider.addToCart] service returned OK');

      await loadCart();
      debugPrint(
          '>>> [CartProvider.addToCart] after reload, items=${_items.length}');
      return true;
    } catch (e, st) {
      debugPrint('>>> [CartProvider.addToCart] ERROR: $e');
      debugPrint('>>> stack: $st');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    debugPrint('>>> [CartProvider.updateQuantity] id=$cartItemId qty=$quantity');
    try {
      await _svc.updateQuantity(cartItemId: cartItemId, quantity: quantity);
      await loadCart();
    } catch (e, st) {
      debugPrint('>>> [CartProvider.updateQuantity] ERROR: $e');
      debugPrint('>>> stack: $st');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeItem(String cartItemId) async {
    debugPrint('>>> [CartProvider.removeItem] id=$cartItemId');
    try {
      await _svc.removeItem(cartItemId);
      await loadCart();
    } catch (e, st) {
      debugPrint('>>> [CartProvider.removeItem] ERROR: $e');
      debugPrint('>>> stack: $st');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    debugPrint('>>> [CartProvider.clearCart] ENTER');
    try {
      await _svc.clearCart();
      _items = [];
      notifyListeners();
    } catch (e, st) {
      debugPrint('>>> [CartProvider.clearCart] ERROR: $e');
      debugPrint('>>> stack: $st');
      _error = e.toString();
      notifyListeners();
    }
  }
}