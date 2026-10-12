import 'package:flutter/foundation.dart';

import '../models/product_category.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _svc = ProductService.instance;

  List<ProductCategory> _categories = [];
  List<Product> _latest = [];
  List<Product> _discounted = [];
  bool _loading = false;
  String? _error;

  List<ProductCategory> get categories => _categories;
  List<Product> get latest => _latest;
  List<Product> get discounted => _discounted;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadHome() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('>>> [DEBUG] loadHome START');

      final cats = await _svc.getTopCategories();
      print('>>> [DEBUG] categories: ${cats.length}');

      final latestList = await _svc.getLatestProducts(limit: 12);
      print('>>> [DEBUG] latest products: ${latestList.length}');

      final discList = await _svc.getDiscountedProducts(limit: 12);
      print('>>> [DEBUG] discounted products: ${discList.length}');

      _categories = cats;
      _latest = latestList;
      _discounted = discList;
    } catch (e, stack) {
      print('>>> [DEBUG] loadHome ERROR: $e');
      print(stack);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Product>> productsForCategory(String categoryId) {
    return _svc.getProductsByCategory(categoryId);
  }

  Future<List<ProductCategory>> allCategories() {
    return _svc.getAllCategories();
  }

  Future<Product?> productById(String id) {
    return _svc.getProductById(id);
  }
}