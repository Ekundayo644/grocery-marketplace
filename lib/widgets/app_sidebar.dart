import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;
  const SidebarItem({required this.icon, required this.label, required this.route});
}

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onSelect;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onSelect,
  });

  static const List<SidebarItem> items = [
    SidebarItem(icon: Icons.home_outlined, label: 'Home', route: 'home'),
    SidebarItem(icon: Icons.category_outlined, label: 'Categories', route: 'categories'),
    SidebarItem(icon: Icons.shopping_cart_outlined, label: 'Cart', route: 'cart'),
    SidebarItem(icon: Icons.receipt_long_outlined, label: 'Orders', route: 'orders'),
    SidebarItem(icon: Icons.favorite_border, label: 'Wishlist', route: 'wishlist'),
    SidebarItem(icon: Icons.person_outline, label: 'Profile', route: 'profile'),
    SidebarItem(icon: Icons.storefront_outlined, label: 'Become a Vendor', route: 'vendor'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.profile?['username'] ?? 'User';
    final email = auth.user?.email ?? '';

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(color: Color(0xFF0A3D7C)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox.shrink(),
              itemBuilder: (context, i) {
                final item = items[i];
                final isActive = item.route == currentRoute;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isActive ? const Color(0xFF0A3D7C) : Colors.black54,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? const Color(0xFF0A3D7C) : Colors.black87,
                    ),
                  ),
                  selected: isActive,
                  selectedTileColor: const Color(0xFF0A3D7C).withValues(alpha: 0.08),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(item.route);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              Navigator.of(context).pop();
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}