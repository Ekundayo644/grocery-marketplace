import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product_category.dart';
import '../../providers/product_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../services/vendor_service.dart';

class VendorProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const VendorProductFormScreen({super.key, this.product});

  @override
  State<VendorProductFormScreen> createState() =>
      _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends State<VendorProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'piece');
  final _unitValueCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _compareCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  String? _categoryId;
  String _status = 'active';
  bool _saving = false;
  bool _uploading = false;
  List<ProductCategory> _categories = [];
  List<String> _imageUrls = [];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final p = widget.product!;
      _nameCtrl.text = (p['name'] ?? '') as String;
      _descCtrl.text = (p['description'] ?? '') as String;
      _unitCtrl.text = (p['unit'] ?? 'piece') as String;
      _unitValueCtrl.text = ((p['unit_value'] ?? 1) as num).toString();
      _priceCtrl.text = ((p['price'] ?? 0) as num).toString();
      _compareCtrl.text = p['compare_price'] == null
          ? ''
          : (p['compare_price'] as num).toString();
      _stockCtrl.text = ((p['stock_quantity'] ?? 0) as int).toString();
      _categoryId = p['category_id'] as String?;
      _status = (p['status'] ?? 'active') as String;

      final existing = p['images'];
      if (existing is List) {
        _imageUrls = existing.cast<String>();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    final cats = await context.read<ProductProvider>().allCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    _unitValueCtrl.dispose();
    _priceCtrl.dispose();
    _compareCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _uploading = true);

      final bytes = await picked.readAsBytes();
      final url = await VendorService.instance.uploadProductImage(
        bytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _imageUrls = [url];
        _uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _save() async {
    print('>>> [DEBUG] _save START. isEditing=$isEditing');
    print('>>> [DEBUG] _save imageUrls=$_imageUrls');

    if (!_formKey.currentState!.validate()) {
      print('>>> [DEBUG] _save: form validation failed');
      return;
    }
    if (_categoryId == null) {
      print('>>> [DEBUG] _save: categoryId is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category')),
      );
      return;
    }
    if (_uploading) {
      print('>>> [DEBUG] _save: still uploading');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for image upload to finish')),
      );
      return;
    }

    setState(() => _saving = true);

    final vp = context.read<VendorProvider>();

    final ok = isEditing
        ? await vp.updateProduct(
            productId: widget.product!['id'] as String,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            unit: _unitCtrl.text.trim(),
            unitValue: double.tryParse(_unitValueCtrl.text) ?? 1,
            price: double.tryParse(_priceCtrl.text) ?? 0,
            comparePrice: _compareCtrl.text.isEmpty
                ? null
                : double.tryParse(_compareCtrl.text),
            stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
            categoryId: _categoryId!,
            status: _status,
            imageUrls: _imageUrls,
          )
        : await vp.createProduct(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            unit: _unitCtrl.text.trim(),
            unitValue: double.tryParse(_unitValueCtrl.text) ?? 1,
            price: double.tryParse(_priceCtrl.text) ?? 0,
            comparePrice: _compareCtrl.text.isEmpty
                ? null
                : double.tryParse(_compareCtrl.text),
            stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
            categoryId: _categoryId!,
            imageUrls: _imageUrls,
          );

    print('>>> [DEBUG] _save: ok=$ok');
    if (!ok) {
      print('>>> [DEBUG] _save error: ${vp.error}');
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vp.error ?? 'Could not save product')),
      );
      return;
    }

    print('>>> [DEBUG] _save: popping with true');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D7C),
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Edit Product' : 'New Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _imageSection(),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Product Name', Icons.inventory_2_outlined,
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Required' : null),
            _field(_descCtrl, 'Description', Icons.description_outlined,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null),
            _categoryDropdown(),
            Row(
              children: [
                Expanded(
                    child: _field(_unitCtrl, 'Unit', Icons.straighten,
                        hint: 'kg, bag')),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(
                        _unitValueCtrl, 'Unit Value', Icons.numbers,
                        keyboardType: TextInputType.number)),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _field(_priceCtrl, 'Price (₦)',
                        Icons.attach_money_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || double.tryParse(v) == null)
                                ? 'Invalid'
                                : null)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(_compareCtrl, 'Compare Price',
                        Icons.compare_arrows,
                        keyboardType: TextInputType.number)),
              ],
            ),
            _field(_stockCtrl, 'Stock Quantity', Icons.inventory_outlined,
                keyboardType: TextInputType.number),
            if (isEditing) _statusDropdown(),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D7C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
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
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Product',
                        style: const TextStyle(
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

  Widget _imageSection() {
    Widget body;
    if (_uploading) {
      body = Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_imageUrls.isNotEmpty) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: _imageUrls.first,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(height: 180, color: Colors.grey.shade100),
          errorWidget: (_, __, ___) => Container(
            height: 180,
            color: Colors.grey.shade100,
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      );
    } else {
      body = Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_photo_alternate_outlined,
                size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image selected',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Image',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        body,
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                    _imageUrls.isEmpty ? 'Choose from gallery' : 'Replace'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0A3D7C),
                  side: const BorderSide(color: Color(0xFF0A3D7C)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_imageUrls.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _uploading
                    ? null
                    : () => setState(() => _imageUrls = []),
                icon:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Remove image',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _categoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _categoryId,
        decoration: const InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category_outlined),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _categories
            .map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.parentId != null ? '  └ ' : ''}${c.name}'),
                ))
            .toList(),
        onChanged: (v) => setState(() => _categoryId = v),
      ),
    );
  }

  Widget _statusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _status,
        decoration: const InputDecoration(
          labelText: 'Status',
          prefixIcon: Icon(Icons.toggle_on_outlined),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: const [
          DropdownMenuItem(value: 'active', child: Text('Active')),
          DropdownMenuItem(value: 'draft', child: Text('Draft')),
          DropdownMenuItem(value: 'out_of_stock', child: Text('Out of stock')),
        ],
        onChanged: (v) => setState(() => _status = v ?? 'active'),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }
}