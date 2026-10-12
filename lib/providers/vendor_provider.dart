import 'package:flutter/foundation.dart';

import '../models/vendor.dart';
import '../services/vendor_service.dart';

class VendorProvider extends ChangeNotifier {
  final VendorService _svc = VendorService.instance;

  Vendor? _vendor;
  bool _loading = false;
  bool _applying = false;
  String? _error;

  Vendor? get vendor => _vendor;
  bool get loading => _loading;
  bool get applying => _applying;
  String? get error => _error;

  bool get hasApplied => _vendor != null;
  bool get isVerified => _vendor?.isVerified ?? false;
  bool get isPending => _vendor?.isPending ?? false;
  bool get isRejected => _vendor?.isRejected ?? false;

  // ================================================================
  // VENDOR PROFILE
  // ================================================================

  Future<void> loadVendor() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _vendor = await _svc.getMyVendor();
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> VendorProvider.loadVendor error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> applyAsVendor({
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
    _applying = true;
    _error = null;
    notifyListeners();

    try {
      _vendor = await _svc.createVendor(
        storeName: storeName,
        storeDescription: storeDescription,
        businessType: businessType,
        cacNumber: cacNumber,
        address: address,
        city: city,
        state: state,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> VendorProvider.applyAsVendor error: $e');
      return false;
    } finally {
      _applying = false;
      notifyListeners();
    }
  }

  // ================================================================
  // PRODUCTS
  // ================================================================

  Future<List<Map<String, dynamic>>> loadMyProducts() async {
    try {
      debugPrint('>>> [DEBUG] VendorProvider.loadMyProducts START');
      final result = await _svc.getMyProducts();
      debugPrint(
          '>>> [DEBUG] VendorProvider.loadMyProducts got ${result.length} items');
      return result;
    } catch (e, stack) {
      debugPrint('>>> [DEBUG] VendorProvider.loadMyProducts ERROR: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<bool> createProduct({
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
    try {
      await _svc.createProduct(
        name: name,
        description: description,
        unit: unit,
        unitValue: unitValue,
        price: price,
        comparePrice: comparePrice,
        stockQuantity: stockQuantity,
        categoryId: categoryId,
        imageUrls: imageUrls,
      );
      return true;
    } catch (e) {
      debugPrint('>>> VendorProvider.createProduct error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
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
  try {
    await _svc.updateProduct(
      productId: productId,
      name: name,
      description: description,
      unit: unit,
      unitValue: unitValue,
      price: price,
      comparePrice: comparePrice,
      stockQuantity: stockQuantity,
      categoryId: categoryId,
      status: status,
      imageUrls: imageUrls,
    );
    return true;
  } catch (e) {
    debugPrint('>>> VendorProvider.updateProduct error: $e');
    _error = e.toString();
    notifyListeners();
    return false;
  }
}

  Future<bool> deleteProduct(String productId) async {
    try {
      await _svc.deleteProduct(productId);
      return true;
    } catch (e) {
      debugPrint('>>> VendorProvider.deleteProduct error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ================================================================
  // ORDERS
  // ================================================================

  Future<List<Map<String, dynamic>>> loadMyVendorOrders() async {
    try {
      return await _svc.getMyVendorOrders();
    } catch (e) {
      debugPrint('>>> VendorProvider.loadMyVendorOrders error: $e');
      return [];
    }
  }

  Future<bool> updateOrderVendorStatus({
    required String orderVendorId,
    required String status,
  }) async {
    try {
      await _svc.updateOrderVendorStatus(
        orderVendorId: orderVendorId,
        status: status,
      );
      return true;
    } catch (e) {
      debugPrint('>>> VendorProvider.updateOrderVendorStatus error: $e');
      return false;
    }
  }

  // ================================================================
  // PAYOUTS
  // ================================================================

  Future<List<Map<String, dynamic>>> loadMyPayouts() async {
    try {
      return await _svc.getMyPayouts();
    } catch (e) {
      debugPrint('>>> VendorProvider.loadMyPayouts error: $e');
      return [];
    }
  }
}