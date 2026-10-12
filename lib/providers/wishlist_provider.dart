import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _svc = WishlistService.instance;

  Set<String> _ids = {};
  List<Product> _products = [];
  bool _loading = false;
  String? _error;

  Set<String> get ids => _ids;
  List<Product> get products => _products;
  bool get loading => _loading;
  String? get error => _error;
  int get count => _ids.length;

  bool isWishlisted(String productId) => _ids.contains(productId);

  /// Lightweight load — only fetches the IDs, used to power heart icons.
  Future<void> loadIds() async {
    _loading = true;
    notifyListeners();
    try {
      _ids = await _svc.getWishlistIds();
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> WishlistProvider.loadIds error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Full load — fetches the actual products, used on the wishlist screen.
  Future<void> loadProducts() async {
    _loading = true;
    notifyListeners();
    try {
      _products = await _svc.getWishlist();
      _ids = _products.map((p) => p.id).toSet();
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> WishlistProvider.loadProducts error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> toggle(String productId) async {
    // Optimistic update — instant UI feedback
    final wasIn = _ids.contains(productId);
    if (wasIn) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    notifyListeners();

    try {
      await _svc.toggle(productId);
      // Refresh the products list if we're on the wishlist screen
      if (_products.isNotEmpty) {
        await loadProducts();
      }
      return _ids.contains(productId);
    } catch (e) {
      // Roll back on failure
      if (wasIn) {
        _ids.add(productId);
      } else {
        _ids.remove(productId);
      }
      _error = e.toString();
      debugPrint('>>> WishlistProvider.toggle error: $e');
      notifyListeners();
      return wasIn;
    }
  }
}