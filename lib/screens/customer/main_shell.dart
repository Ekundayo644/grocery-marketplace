import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/cart_badge.dart';
import '../vendor/become_vendor_screen.dart';
import '../vendor/vendor_dashboard_screen.dart';
import '../vendor/vendor_pending_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_placeholder_screen.dart';
import 'wishlist_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _currentRoute = 'home';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
      context.read<WishlistProvider>().loadIds();
      context.read<VendorProvider>().loadVendor();
    });
  }

  void _onSelect(String route) {
    setState(() => _currentRoute = route);

    // Refresh data when the user navigates to a data-heavy screen
    if (route == 'cart') {
      context.read<CartProvider>().loadCart();
    } else if (route == 'orders') {
      context.read<OrderProvider>().loadOrders();
    } else if (route == 'wishlist') {
      context.read<WishlistProvider>().loadProducts();
    } else if (route == 'vendor') {
      context.read<VendorProvider>().loadVendor();
    }
  }

  String _titleFor(String route) {
    switch (route) {
      case 'home':
        return 'Grocery Marketplace';
      case 'categories':
        return 'Categories';
      case 'cart':
        return 'My Cart';
      case 'orders':
        return 'My Orders';
      case 'wishlist':
        return 'Wishlist';
      case 'profile':
        return 'My Profile';
      case 'vendor':
        return 'Vendor';
      default:
        return 'Grocery Marketplace';
    }
  }

  Widget _buildBody() {
    switch (_currentRoute) {
      case 'home':
        return const HomeScreen();
      case 'categories':
        return const CategoriesScreen();
      case 'cart':
        return const CartScreen();
      case 'orders':
        return const OrdersScreen();
      case 'wishlist':
        return const WishlistScreen();
      case 'profile':
        return const ProfilePlaceholderScreen();
      case 'vendor':
        return const _VendorRouter();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: Text(_titleFor(_currentRoute)),
        actions: [
          CartBadge(onTap: () => _onSelect('cart')),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AppSidebar(
        currentRoute: _currentRoute,
        onSelect: _onSelect,
      ),
      body: _buildBody(),
    );
  }
}

/// Decides what to show for the "Become a Vendor" / "Vendor" menu item
/// based on the user's vendor state.
class _VendorRouter extends StatelessWidget {
  const _VendorRouter();

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VendorProvider>();

    // Still loading the vendor record
    if (vp.loading && vp.vendor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // No vendor yet → show the application form
    if (vp.vendor == null) {
      return const BecomeVendorScreen();
    }

    // Pending approval
    if (vp.isPending) {
      return VendorPendingScreen(storeName: vp.vendor!.storeName);
    }

    // Rejected
    if (vp.isRejected) {
      return VendorPendingScreen(
        storeName: vp.vendor!.storeName,
        rejectionReason: vp.vendor!.verificationNotes ??
            'Please contact support for details.',
      );
    }

    // Verified → show the dashboard
    return const VendorDashboardScreen();
  }
}