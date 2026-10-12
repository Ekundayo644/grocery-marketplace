import 'package:flutter/material.dart';
import 'package:paystack_payment/paystack_payment.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/address.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'add_address_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const double _deliveryFee = 1500;
  static const double _serviceFeeRate = 0.02;

  Address? _selectedAddress;
  String _paymentMethod = 'cod';
  bool _placing = false;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<OrderProvider>().clearError();
      final op = context.read<OrderProvider>();
      await op.loadAddresses();
      if (!mounted) return;
      setState(() => _selectedAddress = op.defaultAddress);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double _serviceFee(double subtotal) =>
      double.parse((subtotal * _serviceFeeRate).toStringAsFixed(2));

  Future<void> _addNewAddress() async {
    final result = await Navigator.of(context).push<Address>(
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    if (result != null && mounted) {
      setState(() => _selectedAddress = result);
    }
  }

  Future<void> _placeOrder() async {
    if (_placing) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _placing = true);

    PlaceOrderResult? result;
    try {
      result = await context.read<OrderProvider>().placeOrder(
            addressId: _selectedAddress!.id,
            paymentMethod: _paymentMethod,
            customerNote: _noteCtrl.text.trim().isEmpty
                ? null
                : _noteCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place order: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    if (result == null) {
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<OrderProvider>().error ?? 'Could not place order',
          ),
        ),
      );
      return;
    }

    // ── Non-card payment: success path ──
    if (_paymentMethod != 'card') {
      await context.read<CartProvider>().loadCart();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderNumber: result!.orderNumber,
            total: result.total,
            paymentMethod: _paymentMethod,
          ),
        ),
      );
      return;
    }

    // ── Card payment path (WebView via paystack_payment) ──
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'quick-handler',
        body: {'order_id': result.orderId},
      );

      if (response.status != 200) {
        throw Exception('Payment initialization failed (${response.status})');
      }

      final data = response.data;
      if (data == null || data['status'] != true) {
        throw Exception(data?['message'] ?? 'Paystack rejected the request');
      }

      final accessCode = data['data']['access_code'] as String?;
      if (accessCode == null || accessCode.isEmpty) {
        throw Exception('No access_code returned from Paystack');
      }

      if (!mounted) return;

      // Launch the WebView-based Paystack checkout
      final paystack = PaystackPayment();
      await paystack.checkout(
        context: context, // 👈 FIXED: named parameter for paystack_payment 1.0.0
        accessCode: accessCode,
        onSuccess: (response) async {
          // Payment succeeded — refresh cart and show success screen
          await context.read<CartProvider>().loadCart();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(
                orderNumber: result!.orderNumber,
                total: result.total,
                paymentMethod: 'card',
              ),
            ),
          );
        },
        onCancel: (response) {
          if (!mounted) return;
          setState(() => _placing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled')),
          );
        },
        onError: (response) {
          if (!mounted) return;
          setState(() => _placing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment failed: ${response.message ?? "Unknown error"}',
              ),
            ),
          );
        },
        options: const PaystackCheckoutOptions(
          title: 'Complete your payment',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final op = context.watch<OrderProvider>();

    final subtotal = cart.subtotal;
    final serviceFee = _serviceFee(subtotal);
    final total = subtotal + _deliveryFee + serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Delivery Address'),
          if (op.loadingAddresses)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (op.addresses.isEmpty)
            _noAddressCard()
          else
            ...op.addresses.map(_addressTile),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addNewAddress,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add new address'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A3D7C),
              side: const BorderSide(color: Color(0xFF0A3D7C)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Payment Method'),
          _paymentTile('card', 'Card Payment', Icons.credit_card_outlined,
              'Pay securely with your debit or credit card'),
          _paymentTile('cod', 'Cash on Delivery', Icons.payments_outlined,
              'Pay the rider when your order arrives'),
          _paymentTile('bank_transfer', 'Bank Transfer',
              Icons.account_balance_outlined,
              'Transfer to our account and upload proof'),
          const SizedBox(height: 24),
          _sectionTitle('Order Note (optional)'),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Any special instructions for the vendor?',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Order Summary'),
          _summaryRow('Items (${cart.itemCount})', '₦${_fmt(subtotal)}'),
          _summaryRow('Delivery Fee', '₦${_fmt(_deliveryFee)}'),
          _summaryRow('Service Fee (2%)', '₦${_fmt(serviceFee)}'),
          const Divider(height: 24),
          _summaryRow('Total', '₦${_fmt(total)}', bold: true),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_placing || cart.isEmpty) ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D7C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: _placing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Place Order • ₦${_fmt(total)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0A3D7C),
        ),
      ),
    );
  }

  Widget _noAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No saved address. Add one to continue.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressTile(Address a) {
    final selected = _selectedAddress?.id == a.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0xFF0A3D7C) : Colors.grey.shade200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: RadioListTile<String>(
          value: a.id,
          groupValue: _selectedAddress?.id,
          onChanged: (_) => setState(() => _selectedAddress = a),
          title: Text(
            '${a.label ?? 'Address'} — ${a.recipientName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${a.phone}\n${a.shortLine}'),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _paymentTile(String value, String title, IconData icon, String sub) {
    final selected = _paymentMethod == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0xFF0A3D7C) : Colors.grey.shade200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: RadioListTile<String>(
          value: value,
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
          title: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0A3D7C)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF0A3D7C),
            ),
          ),
        ],
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