import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();

    if (op.loadingOrders && op.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (op.orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No orders yet',
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            SizedBox(height: 4),
            Text('Place your first order to see it here',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OrderProvider>().loadOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: op.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _OrderCard(order: op.orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A3D7C),
                    fontSize: 13,
                  ),
                ),
              ),
              _statusChip(order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(order.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const Divider(height: 18),
          ...order.items.take(3).map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${it.quantity}× ${it.productName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '₦${_fmt(it.lineTotal)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          if (order.items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${order.items.length - 3} more item(s)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          const Divider(height: 18),
          Row(
            children: [
              _paymentLabel(order.paymentMethod),
              const Spacer(),
              const Text('Total: ',
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              Text(
                '₦${_fmt(order.total)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A3D7C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.black87;
    switch (status) {
      case 'pending':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case 'confirmed':
      case 'preparing':
      case 'ready_for_pickup':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'in_transit':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        break;
      case 'delivered':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _paymentLabel(String method) {
    IconData icon = Icons.payment;
    String label = method;
    switch (method) {
      case 'cod':
        icon = Icons.payments_outlined;
        label = 'Cash on Delivery';
        break;
      case 'bank_transfer':
        icon = Icons.account_balance_outlined;
        label = 'Bank Transfer';
        break;
      case 'card':
        icon = Icons.credit_card;
        label = 'Card';
        break;
    }
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = d.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$min $ampm';
  }

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}