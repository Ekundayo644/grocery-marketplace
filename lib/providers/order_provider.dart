import 'package:flutter/foundation.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _svc = OrderService.instance;

  List<Address> _addresses = [];
  List<Order> _orders = [];
  bool _loadingAddresses = false;
  bool _loadingOrders = false;
  bool _placing = false;
  String? _error;

  /// Timestamp of the last placeOrder call. Used to dedupe rapid repeat
  /// calls (double-tap, rebuild-triggered re-entry, etc.).
  DateTime? _lastOrderTime;
  static const Duration _dedupeWindow = Duration(seconds: 5);

  List<Address> get addresses => _addresses;
  List<Order> get orders => _orders;
  bool get loadingAddresses => _loadingAddresses;
  bool get loadingOrders => _loadingOrders;
  bool get placing => _placing;
  String? get error => _error;

  Address? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses
        .firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
  }

  /// Clear any previously stored error (used when entering checkout).
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    _loadingAddresses = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _svc.getAddresses();
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> OrderProvider.loadAddresses error: $e');
    } finally {
      _loadingAddresses = false;
      notifyListeners();
    }
  }

  Future<Address?> addAddress({
    required String recipientName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    String? label,
    String? deliveryNotes,
    bool isDefault = false,
  }) async {
    try {
      final a = await _svc.createAddress(
        recipientName: recipientName,
        phone: phone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        label: label,
        deliveryNotes: deliveryNotes,
        isDefault: isDefault,
      );
      await loadAddresses();
      return a;
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> OrderProvider.addAddress error: $e');
      notifyListeners();
      return null;
    }
  }

  Future<PlaceOrderResult?> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? customerNote,
  }) async {
    // ── Dedupe window: reject any call within 5 seconds of the last one ──
    final now = DateTime.now();
    if (_lastOrderTime != null &&
        now.difference(_lastOrderTime!) < _dedupeWindow) {
      debugPrint(
          '>>> [OrderProvider.placeOrder] BLOCKED — dedupe window '
          '(${now.difference(_lastOrderTime!).inMilliseconds}ms since last)');
      return null;
    }

    // ── In-flight guard ──
    if (_placing) {
      debugPrint('>>> [OrderProvider.placeOrder] BLOCKED — already placing');
      return null;
    }

    _lastOrderTime = now;
    _placing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _svc.placeOrder(
        addressId: addressId,
        paymentMethod: paymentMethod,
        customerNote: customerNote,
      );
      debugPrint(
          '>>> [OrderProvider.placeOrder] SUCCESS ${result.orderNumber}');
      return result;
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> [OrderProvider.placeOrder] error: $e');
      return null;
    } finally {
      _placing = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    _loadingOrders = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _svc.getMyOrders();
    } catch (e) {
      _error = e.toString();
      debugPrint('>>> OrderProvider.loadOrders error: $e');
    } finally {
      _loadingOrders = false;
      notifyListeners();
    }
  }
}