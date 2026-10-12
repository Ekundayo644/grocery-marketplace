import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/vendor_provider.dart';

class BecomeVendorScreen extends StatefulWidget {
  const BecomeVendorScreen({super.key});

  @override
  State<BecomeVendorScreen> createState() => _BecomeVendorScreenState();
}

class _BecomeVendorScreenState extends State<BecomeVendorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _cacCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  String _businessType = 'individual';

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _cacCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<VendorProvider>().applyAsVendor(
          storeName: _storeNameCtrl.text.trim(),
          storeDescription: _descriptionCtrl.text.trim(),
          businessType: _businessType,
          cacNumber: _cacCtrl.text.trim().isEmpty ? null : _cacCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          bankName: _bankNameCtrl.text.trim(),
          bankAccountNumber: _accountNumberCtrl.text.trim(),
          bankAccountName: _accountNameCtrl.text.trim(),
        );

    if (!mounted) return;

    if (!ok) {
      final err = context.read<VendorProvider>().error ?? 'Unknown error';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Could not submit application'),
          content: Text(err, style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    // On success, VendorProvider notifies and MainShell rebuilds to the pending screen
  }

  @override
  Widget build(BuildContext context) {
    final applying = context.watch<VendorProvider>().applying;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: const Text('Become a Vendor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _intro(),
            const SizedBox(height: 16),
            _sectionHeader('Store Details'),
            _field(
              controller: _storeNameCtrl,
              label: 'Store Name',
              hint: 'e.g. Lekki Fresh Market',
              icon: Icons.storefront_outlined,
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Enter a store name' : null,
            ),
            _field(
              controller: _descriptionCtrl,
              label: 'Short Description',
              hint: 'What do you sell?',
              icon: Icons.description_outlined,
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Add a description' : null,
            ),
            _dropdown(),
            _field(
              controller: _cacCtrl,
              label: 'CAC Number (optional)',
              hint: 'RC1234567',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 20),
            _sectionHeader('Location'),
            _field(
              controller: _addressCtrl,
              label: 'Pickup Address',
              hint: '12 Adeola Street',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter an address' : null,
            ),
            _field(
              controller: _cityCtrl,
              label: 'City',
              hint: 'Ikeja',
              icon: Icons.location_city_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a city' : null,
            ),
            _field(
              controller: _stateCtrl,
              label: 'State',
              hint: 'Lagos',
              icon: Icons.map_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a state' : null,
            ),
            const SizedBox(height: 20),
            _sectionHeader('Bank Account (for payouts)'),
            _field(
              controller: _bankNameCtrl,
              label: 'Bank Name',
              hint: 'GTBank',
              icon: Icons.account_balance_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a bank' : null,
            ),
            _field(
              controller: _accountNumberCtrl,
              label: 'Account Number',
              hint: '0123456789',
              icon: Icons.numbers_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an account number';
                if (v.trim().length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
            _field(
              controller: _accountNameCtrl,
              label: 'Account Holder Name',
              hint: 'As it appears on your bank statement',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter the account holder name' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: applying ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D7C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: applying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Application',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3D7C).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0A3D7C).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0A3D7C)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Applications are reviewed within 24–48 hours. You\'ll be able to add products once approved.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0A3D7C),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _businessType,
        decoration: const InputDecoration(
          labelText: 'Business Type',
          prefixIcon: Icon(Icons.business_outlined),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: const [
          DropdownMenuItem(value: 'individual', child: Text('Individual')),
          DropdownMenuItem(
              value: 'registered_company', child: Text('Registered Company')),
        ],
        onChanged: (v) => setState(() => _businessType = v ?? 'individual'),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }
}