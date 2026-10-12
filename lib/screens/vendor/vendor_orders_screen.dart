import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/vendor_provider.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<VendorProvider>().loadMyVendorOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: const Text('Incoming Orders'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No orders yet.',
                    style: TextStyle(color: Colors.black54)),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _OrderTile(
                row: items[i],
                onChanged: () => setState(_reload),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onChanged;
  const _OrderTile({required this.row, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final order = row['orders'] as Map<String, dynamic>?;
    final items =
        (row['order_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final subtotal = (row['subtotal'] as num).toDouble();
    final status = row['status'] as String;
    final orderNumber = order?['order_number'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
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
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A3D7C),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${it['quantity']}× ${it['product_name']}',
                  style: const TextStyle(fontSize: 13),
                ),
              )),
          const Divider(height: 16),
          Row(
            children: [
              Text(
                '₦${_fmt(subtotal)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A3D7C)),
              ),
              const Spacer(),
              if (status == 'pending')
                ElevatedButton(
                  onPressed: () async {
                    await context
                        .read<VendorProvider>()
                        .updateOrderVendorStatus(
                          orderVendorId: row['id'] as String,
                          status: 'accepted',
                        );
                    onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3D7C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
              if (status == 'accepted')
                ElevatedButton(
                  onPressed: () async {
                    await context
                        .read<VendorProvider>()
                        .updateOrderVendorStatus(
                          orderVendorId: row['id'] as String,
                          status: 'ready',
                        );
                    onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark ready'),
                ),
              if (status == 'ready')
                ElevatedButton(
                  onPressed: () async {
                    await context
                        .read<VendorProvider>()
                        .updateOrderVendorStatus(
                          orderVendorId: row['id'] as String,
                          status: 'dispatched',
                        );
                    onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Dispatch'),
                ),
              if (status == 'dispatched')
                ElevatedButton(
                  onPressed: () async {
                    await context
                        .read<VendorProvider>()
                        .updateOrderVendorStatus(
                          orderVendorId: row['id'] as String,
                          status: 'delivered',
                        );
                    onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark delivered'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'dispatched':
        return Colors.purple;
      case 'delivered':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  String _fmt(double p) {
    final s = p.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}