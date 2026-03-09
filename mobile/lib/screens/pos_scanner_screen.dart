import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/local_db_service.dart';
import 'add_product_screen.dart';

class POSScannerScreen extends StatefulWidget {
  const POSScannerScreen({super.key});

  @override
  State<POSScannerScreen> createState() => _POSScannerScreenState();
}

class _POSScannerScreenState extends State<POSScannerScreen> {
  Map<String, Product> _productMap = {};
  final List<CartItem> _cart = [];
  bool _isLoading = true;
  bool _showSuccessFlash = false;
  final MobileScannerController _controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final db = context.read<LocalDbService>();
    final map = await db.getBarcodeMap();
    if (mounted) {
      setState(() {
        _productMap = map;
        _isLoading = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isLoading) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null) {
        // Explicitly stop scanning to prevent duplicates
        await _controller.stop();
        _handleBarcode(code);
        
        // Re-enable scanning after 500ms
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _controller.start();
        });
        break; 
      }
    }
  }

  void _handleBarcode(String code) {
    final product = _productMap[code];
    if (product != null) {
      _triggerSuccess();
      _addToCart(product);
    } else {
      _triggerFailure();
      _showProductNotFound(code);
    }
  }

  void _triggerSuccess() {
    _successFeedback();
    setState(() => _showSuccessFlash = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showSuccessFlash = false);
    });
  }

  void _triggerFailure() {
    _failFeedback();
  }

  void _addToCart(Product product) {
    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  Future<void> _successFeedback() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
    try {
      await _audioPlayer.play(AssetSource('sounds/beep.wav'));
    } catch (_) {}
  }

  void _failFeedback() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 400);
    }
  }

  void _showProductNotFound(String code) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            Text(
              "Product Not Found",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.emerald[800]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProductScreen(initialBarcode: code),
                    ),
                  );
                  if (result == true) {
                    _loadProducts(); // Refresh map if product was added
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Create New Product"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _totalAmount => _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("POS Scanner", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.emerald[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scanner Port
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                  ),
                  // Animated Flash Indicator
                  AnimatedOpacity(
                    opacity: _showSuccessFlash ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.emerald.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.emerald, width: 4),
                      ),
                    ),
                  ),
                  // Frame Overlay
                  Center(
                    child: Container(
                      width: 240,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Cart List
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _cart.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Ready to scan", style: GoogleFonts.poppins(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _cart.length,
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.emerald.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(item.product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: Text("${item.product.price.toStringAsFixed(2)} MAD", style: const TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.emerald.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "x${item.quantity}",
                                style: GoogleFonts.roboto(fontWeight: FontWeight.w900, color: Colors.emerald[700], fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Checkout Summary
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -10)),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                    Text("${_totalAmount.toStringAsFixed(2)} MAD", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.emerald[900])),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty ? null : () {
                      // Handle Checkout
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.emerald[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text("COMPLETE ORDER", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}
