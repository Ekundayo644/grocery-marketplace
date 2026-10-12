import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/address.dart';
import '../models/order.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------
  // ADDRESSES
  // ---------------------------------------------------------------------

  Future<List<Address>> getAddresses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Address.fromMap(e)).toList();
  }

  Future<Address> createAddress({
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
    final res = await _client.rpc('create_my_address', params: {
      'p_recipient_name': recipientName,
      'p_phone': phone,
      'p_address_line1': addressLine1,
      'p_address_line2': addressLine2,
      'p_city': city,
      'p_state': state,
      'p_label': label,
      'p_delivery_notes': deliveryNotes,
      'p_is_default': isDefault,
    });

    final newId = res as String;

    final data = await _client
        .from('addresses')
        .select()
        .eq('id', newId)
        .single();

    return Address.fromMap(data);
  }

  Future<void> setDefaultAddress(String addressId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    await _client
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', userId);

    await _client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', addressId);
  }

  // ---------------------------------------------------------------------
  // ORDERS
  // ---------------------------------------------------------------------

  Future<PlaceOrderResult> placeOrder({
    required String addressId,
    required String paymentMethod,
    double deliveryFee = 1500,
    double serviceFeeRate = 0.02,
    String? customerNote,
  }) async {
    // ═══════════════════════════════════════════════════════════════
    // TEMP DIAGNOSTIC — remove once duplicate-order issue is fixed
    // ═══════════════════════════════════════════════════════════════
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('>>> [OrderService.placeOrder] CALLED at ${DateTime.now()}');
    debugPrint('    addressId    = $addressId');
    debugPrint('    paymentMethod= $paymentMethod');
    debugPrint('    deliveryFee  = $deliveryFee');
    debugPrint('    customerNote = $customerNote');
    debugPrint('    STACK:');
    debugPrintStack(label: '    ');
    debugPrint('════════════════════════════════════════════════════════');

    final res = await _client.rpc('place_order', params: {
      'p_address_id': addressId,
      'p_payment_method': paymentMethod,
      'p_delivery_fee': deliveryFee,
      'p_service_fee_rate': serviceFeeRate,
      'p_customer_note': customerNote,
    });

    debugPrint('>>> [OrderService.placeOrder] RETURNED at ${DateTime.now()}: $res');

    return PlaceOrderResult.fromMap(Map<String, dynamic>.from(res));
  }

  Future<List<Order>> getMyOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Order.fromMap(e)).toList();
  }

  Future<Order?> getOrderById(String orderId) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();

    return data == null ? null : Order.fromMap(data);
  }
}