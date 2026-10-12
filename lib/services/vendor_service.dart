import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vendor.dart';

class VendorService {
  VendorService._();
  static final VendorService instance = VendorService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ================================================================
  // VENDOR PROFILE
  // ================================================================

  Future<Vendor?> getMyVendor() async {
    final userId = _client.auth.currentUser?.id;
    print('>>> [DEBUG] getMyVendor: auth user id = $userId');
    if (userId == null) return null;

    final data = await _client
        .from('vendors')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    print('>>> [DEBUG] getMyVendor: result = $data');
    return data == null ? null : Vendor.fromMap(data);
  }

  Future<Vendor> createVendor({
    required String storeName,
    required String storeDescription,
    required String businessType,
    String? cacNumber,
    required String address,
    required String city,
    required String state,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final baseSlug = storeName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final slug = '$baseSlug-${userId.substring(0, 6)}';

    final res = await _client.rpc('create_my_vendor', params: {
      'p_store_name': storeName,
      'p_store_slug': slug,
      'p_store_description': storeDescription,
      'p_business_type': businessType,
      'p_cac_number': cacNumber,
      'p_address': address,
      'p_city': city,
      'p_state': state,
      'p_bank_name': bankName,
      'p_bank_account_number': bankAccountNumber,
      'p_bank_account_name': bankAccountName,
    });

    final newId = res as String;

    final data = await _client
        .from('vendors')
        .select()
        .eq('id', newId)
        .single();

    return Vendor.fromMap(data);
  }

  // ================================================================
  // PRODUCTS
  // ================================================================

  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final vendor = await getMyVendor();
    print('>>> [DEBUG] getMyProducts: vendor = ${vendor?.id}');
    if (vendor == null) {
      print('>>> [DEBUG] getMyProducts: NO VENDOR FOUND');
      return [];
    }

    print('>>> [DEBUG] getMyProducts: querying for vendor_id = ${vendor.id}');
    final data = await _client
        .from('products')
        .select()
        .eq('vendor_id', vendor.id)
        .order('created_at', ascending: false);

    final list = data as List;
    print('>>> [DEBUG] getMyProducts: got ${list.length} rows');
    if (list.isNotEmpty) {
      print('>>> [DEBUG] first row name: ${list.first['name']}');
      print('>>> [DEBUG] first row images: ${list.first['images']}');
    }

    return list.cast<Map<String, dynamic>>();
  }

  Future<String> createProduct({
    required String name,
    required String description,
    required String unit,
    required double unitValue,
    required double price,
    double? comparePrice,
    required int stockQuantity,
    required String categoryId,
    List<String> imageUrls = const [],
  }) async {
    final baseSlug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final slug =
        '$baseSlug-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final res = await _client.rpc('create_my_product', params: {
      'p_name': name,
      'p_slug': slug,
      'p_description': description,
      'p_unit': unit,
      'p_unit_value': unitValue,
      'p_price': price,
      'p_compare_price': comparePrice,
      'p_stock_quantity': stockQuantity,
      'p_category_id': categoryId,
      'p_images': imageUrls,
    });

    return res as String;
  }

  /// Update a product via the SECURITY DEFINER function `update_my_product`.
  /// The function verifies the caller owns the vendor and only updates
  /// rows belonging to that vendor.
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required String unit,
    required double unitValue,
    required double price,
    double? comparePrice,
    required int stockQuantity,
    required String categoryId,
    required String status,
    List<String> imageUrls = const [],
  }) async {
    print('>>> [DEBUG] updateProduct (RPC) called: id=$productId');
    print('>>> [DEBUG] updateProduct images=$imageUrls');

    try {
      final res = await _client.rpc('update_my_product', params: {
        'p_product_id': productId,
        'p_name': name,
        'p_description': description,
        'p_unit': unit,
        'p_unit_value': unitValue,
        'p_price': price,
        'p_compare_price': comparePrice,
        'p_stock_quantity': stockQuantity,
        'p_category_id': categoryId,
        'p_status': status,
        'p_images': imageUrls,
      });

      print('>>> [DEBUG] updateProduct: RPC returned $res');
    } catch (e, stack) {
      print('>>> [DEBUG] updateProduct ERROR: $e');
      print(stack.toString());
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
  }

  Future<void> toggleProductStatus(String productId, String newStatus) async {
    await _client
        .from('products')
        .update({'status': newStatus})
        .eq('id', productId);
  }

  // ================================================================
  // IMAGE UPLOAD
  // ================================================================

  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    print('>>> [DEBUG] uploadProductImage: user=$userId file=$fileName');

    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '.jpg';

    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}$ext';
    print('>>> [DEBUG] uploadProductImage: path=$path');

    await _client.storage.from('product-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    final publicUrl =
        _client.storage.from('product-images').getPublicUrl(path);
    print('>>> [DEBUG] uploadProductImage: publicUrl=$publicUrl');

    return publicUrl;
  }

  // ================================================================
  // ORDERS
  // ================================================================

  Future<List<Map<String, dynamic>>> getMyVendorOrders() async {
    final vendor = await getMyVendor();
    print('>>> [DEBUG] getMyVendorOrders: vendor = ${vendor?.id}');
    if (vendor == null) {
      print('>>> [DEBUG] getMyVendorOrders: NO VENDOR');
      return [];
    }

    print('>>> [DEBUG] getMyVendorOrders: querying for vendor_id = ${vendor.id}');

    try {
      final data = await _client
          .from('order_vendors')
          .select('''
            id,
            subtotal,
            commission_amount,
            vendor_earnings,
            status,
            accepted_at,
            ready_at,
            delivered_at,
            orders (
              id,
              order_number,
              status,
              payment_method,
              payment_status,
              created_at,
              customer_note,
              delivery_address_snapshot
            ),
            order_items (
              id,
              product_name,
              quantity,
              price,
              line_total
            )
          ''')
          .eq('vendor_id', vendor.id);

      final list = data as List;
      print('>>> [DEBUG] getMyVendorOrders: got ${list.length} rows');
      if (list.isNotEmpty) {
        print(
            '>>> [DEBUG] first order number: ${list.first['orders']?['order_number']}');
      }
      return list.cast<Map<String, dynamic>>();
    } catch (e, stack) {
      print('>>> [DEBUG] getMyVendorOrders ERROR: $e');
      print(stack.toString());
      rethrow;
    }
  }

  Future<void> updateOrderVendorStatus({
    required String orderVendorId,
    required String status,
  }) async {
    final updates = <String, dynamic>{'status': status};

    if (status == 'accepted') {
      updates['accepted_at'] = DateTime.now().toUtc().toIso8601String();
    } else if (status == 'ready') {
      updates['ready_at'] = DateTime.now().toUtc().toIso8601String();
    } else if (status == 'delivered') {
      updates['delivered_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await _client.from('order_vendors').update(updates).eq('id', orderVendorId);
  }

  // ================================================================
  // PAYOUTS
  // ================================================================

  Future<List<Map<String, dynamic>>> getMyPayouts() async {
    final vendor = await getMyVendor();
    if (vendor == null) return [];

    final data = await _client
        .from('vendor_payouts')
        .select()
        .eq('vendor_id', vendor.id)
        .order('created_at', ascending: false);

    return (data as List).cast<Map<String, dynamic>>();
  }
}