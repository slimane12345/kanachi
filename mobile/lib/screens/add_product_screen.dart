import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/local_db_service.dart';
import '../services/product_lookup_service.dart';
import 'package:uuid/uuid.dart';

class AddProductScreen extends StatefulWidget {
  final String? initialBarcode;

  const AddProductScreen({super.key, this.initialBarcode});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController(text: '100');
  bool _isSaving = false;
  bool _isSearching = false;
  final _lookupService = ProductLookupService();

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
      _lookupProduct(widget.initialBarcode!);
    }
  }

  Future<void> _lookupProduct(String barcode) async {
    setState(() => _isSearching = true);
    try {
      final result = await _lookupService.lookupBarcode(barcode);
      if (result.found && mounted) {
        setState(() {
          if (result.name != null) {
            _nameController.text = result.brand != null 
                ? "${result.brand} ${result.name}" 
                : result.name!;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product details found!'), backgroundColor: Colors.emerald),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = context.read<LocalDbService>();
      final product = Product()
        ..remoteId = const Uuid().v4()
        ..name = _nameController.text.trim()
        ..price = double.parse(_priceController.text)
        ..barcode = _barcodeController.text.trim()
        ..stock = int.parse(_stockController.text)
        ..minThreshold = 5
        ..updatedAt = DateTime.now()
        ..isDirty = true;

      await db.save(product);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.emerald),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Create New Product", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.emerald[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Product Details"),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.emerald)),
                      const SizedBox(width: 8),
                      Text("Searching for details...", style: GoogleFonts.poppins(fontSize: 12, color: Colors.emerald[700])),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Product Name",
                controller: _nameController,
                hint: "e.g. Fresh Milk 1L",
                icon: Icons.shopping_bag_outlined,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "Price (MAD)",
                      controller: _priceController,
                      hint: "0.00",
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: "Stock",
                      controller: _stockController,
                      hint: "0",
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Barcode",
                controller: _barcodeController,
                hint: "Scan or enter manually",
                icon: Icons.qr_code_scanner,
                readOnly: widget.initialBarcode != null,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.emerald[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("SAVE PRODUCT", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.1),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.emerald[900])),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          style: GoogleFonts.poppins(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[300]),
            prefixIcon: Icon(icon, color: Colors.emerald[600], size: 22),
            filled: true,
            fillColor: readOnly ? Colors.grey[50] : Colors.emerald.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.emerald.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.emerald, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
