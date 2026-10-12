class OrderItem {
  final String id;
  final String productName;
  final String? unit;
  final double price;
  final int quantity;
  final double lineTotal;

  OrderItem({
    required this.id,
    required this.productName,
    this.unit,
    required this.price,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) {
    return OrderItem(
      id: m['id'] as String,
      productName: m['product_name'] as String,
      unit: m['unit'] as String?,
      price: (m['price'] as num).toDouble(),
      quantity: (m['quantity'] as num).toInt(),
      lineTotal: (m['line_total'] as num).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String? deliveryAddressSnapshot;

  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;

  final String paymentMethod;
  final String paymentStatus;
  final String status;

  final String? customerNote;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    this.deliveryAddressSnapshot,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.customerNote,
    required this.createdAt,
    this.deliveredAt,
    required this.items,
  });

  factory Order.fromMap(Map<String, dynamic> m) {
    final rawItems = m['order_items'] as List?;
    final items = (rawItems ?? [])
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();

    return Order(
      id: m['id'] as String,
      orderNumber: m['order_number'] as String,
      userId: m['user_id'] as String,
      deliveryAddressSnapshot:
          m['delivery_address_snapshot'] == null
              ? null
              : m['delivery_address_snapshot'].toString(),
      subtotal: (m['subtotal'] as num).toDouble(),
      deliveryFee: (m['delivery_fee'] as num).toDouble(),
      serviceFee: (m['service_fee'] as num).toDouble(),
      discount: (m['discount'] as num).toDouble(),
      total: (m['total'] as num).toDouble(),
      paymentMethod: m['payment_method'] as String,
      paymentStatus: m['payment_status'] as String,
      status: m['status'] as String,
      customerNote: m['customer_note'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      deliveredAt: m['delivered_at'] == null
          ? null
          : DateTime.parse(m['delivered_at'] as String),
      items: items,
    );
  }
}

/// Result returned by the place_order RPC.
class PlaceOrderResult {
  final bool success;
  final String orderId;
  final String orderNumber;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double total;

  PlaceOrderResult({
    required this.success,
    required this.orderId,
    required this.orderNumber,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.total,
  });

  factory PlaceOrderResult.fromMap(Map<String, dynamic> m) {
    return PlaceOrderResult(
      success: (m['success'] ?? false) as bool,
      orderId: m['order_id'] as String,
      orderNumber: m['order_number'] as String,
      subtotal: (m['subtotal'] as num).toDouble(),
      deliveryFee: (m['delivery_fee'] as num).toDouble(),
      serviceFee: (m['service_fee'] as num).toDouble(),
      total: (m['total'] as num).toDouble(),
    );
  }
}