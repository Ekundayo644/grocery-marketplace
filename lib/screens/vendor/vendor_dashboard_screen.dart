import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/vendor_provider.dart';
import 'vendor_orders_screen.dart';
import 'vendor_payouts_screen.dart';
import 'vendor_products_screen.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>().vendor;

    if (vendor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3D7C),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.storeName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${vendor.city ?? ''}${vendor.city != null && vendor.state != null ? ', ' : ''}${vendor.state ?? ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Verified Vendor',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard('Orders', '${vendor.totalOrders}',
                  Icons.receipt_long_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Revenue', '₦${_fmt(vendor.totalRevenue)}',
                  Icons.trending_up),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard('Rating', vendor.rating.toStringAsFixed(1),
                  Icons.star_outline),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                  'Commission',
                  '${vendor.commissionRate.toStringAsFixed(0)}%',
                  Icons.percent),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Manage your store',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A3D7C),
          ),
        ),
        const SizedBox(height: 10),
        _tile(
          'My Products',
          Icons.inventory_2_outlined,
          'Add or edit products you sell',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VendorProductsScreen()),
          ),
        ),
        _tile(
          'Incoming Orders',
          Icons.shopping_bag_outlined,
          'See orders and mark them ready',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VendorOrdersScreen()),
          ),
        ),
        _tile(
          'Payouts',
          Icons.account_balance_wallet_outlined,
          'Track your earnings and withdrawals',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VendorPayoutsScreen()),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
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
          Icon(icon, color: const Color(0xFF0A3D7C), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A3D7C),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _tile(String title, IconData icon, String subtitle,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0A3D7C)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
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