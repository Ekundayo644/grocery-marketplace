import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../providers/order_provider.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  bool _isDefault = false;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _labelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final address = await context.read<OrderProvider>().addAddress(
          recipientName: _recipientCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          addressLine1: _line1Ctrl.text.trim(),
          addressLine2: _line2Ctrl.text.trim().isEmpty
              ? null
              : _line2Ctrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
          deliveryNotes:
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isDefault: _isDefault,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save address')),
      );
      return;
    }

    Navigator.of(context).pop<Address>(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: const Text('Add Delivery Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              controller: _labelCtrl,
              label: 'Label (optional)',
              hint: 'Home, Office…',
              icon: Icons.label_outline,
            ),
            _field(
              controller: _recipientCtrl,
              label: 'Recipient Name',
              hint: 'Who will receive the order?',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _field(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: '08012345678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 7) return 'Enter a valid phone';
                return null;
              },
            ),
            _field(
              controller: _line1Ctrl,
              label: 'Street Address',
              hint: '12 Adeola Street',
              icon: Icons.home_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _field(
              controller: _line2Ctrl,
              label: 'Apartment / Landmark (optional)',
              hint: 'Flat 3B, near the church',
              icon: Icons.location_on_outlined,
            ),
            _field(
              controller: _cityCtrl,
              label: 'City',
              hint: 'Ikeja',
              icon: Icons.location_city_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _field(
              controller: _stateCtrl,
              label: 'State',
              hint: 'Lagos',
              icon: Icons.map_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _field(
              controller: _notesCtrl,
              label: 'Delivery Notes (optional)',
              hint: 'Gate code, best time to deliver…',
              icon: Icons.notes_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v ?? false),
              title: const Text('Set as default address'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D7C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Save Address',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
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