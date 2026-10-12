import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_category.dart';
import '../models/product.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ProductCategory>> getTopCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .isFilter('parent_id', null)
        .order('display_order');

    return (data as List).map((e) => ProductCategory.fromMap(e)).toList();
  }

  Future<List<ProductCategory>> getAllCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return (data as List).map((e) => ProductCategory.fromMap(e)).toList();
  }

  /// Fetch products in the given category AND all its direct children.
  Future<List<Product>> getProductsByCategory(String categoryId,
      {int limit = 60}) async {
    print('>>> [DEBUG] getProductsByCategory for $categoryId');

    final subCats = await _client
        .from('categories')
        .select('id')
        .eq('parent_id', categoryId);

    final ids = <String>[categoryId];
    for (final row in (subCats as List)) {
      ids.add(row['id'] as String);
    }
    print('>>> [DEBUG] ids to query: $ids');

    final data = await _client
        .from('products')
        .select()
        .inFilter('category_id', ids)
        .eq('status', 'active')
        .limit(limit);

    print('>>> [DEBUG] products found: ${(data as List).length}');

    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> getLatestProducts({int limit = 20}) async {
    final data = await _client
        .from('products')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> getDiscountedProducts({int limit = 20}) async {
    final data = await _client
        .from('products')
        .select()
        .eq('status', 'active')
        .not('compare_price', 'is', null)
        .limit(limit);

    return (data as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final data = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    return data == null ? null : Product.fromMap(data);
  }

  Future<List<Product>> searchProducts(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];
    final data = await _client
        .from('products')
        .select()
        .eq('status', 'active')
        .or('name.ilike.%${query.trim()}%,description.ilike.%${query.trim()}%')
        .limit(limit);

    return (data as List).map((e) => Product.fromMap(e)).toList();
  }
}