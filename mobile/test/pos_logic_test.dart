import 'package:flutter_test/flutter_test.dart';
import '../lib/models/product.dart';

// Mock class for testing logic since we can't easily run the UI in unit tests
class POSLogic {
  final Map<String, Product> productMap;
  final List<CartItem> cart = [];

  POSLogic(this.productMap);

  void handleBarcode(String code) {
    final product = productMap[code];
    if (product != null) {
      _addToCart(product);
    }
  }

  void _addToCart(Product product) {
    final index = cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      cart[index].quantity++;
    } else {
      cart.add(CartItem(product: product, quantity: 1));
    }
  }

  double get totalAmount => cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}

void main() {
  group('POS Scanning Logic Tests', () {
    late Map<String, Product> mockProductMap;

    setUp(() {
      final p1 = Product()
        ..id = 1
        ..name = "Milk"
        ..price = 10.0
        ..barcode = "12345";
      
      final p2 = Product()
        ..id = 2
        ..name = "Bread"
        ..price = 5.0
        ..barcode = "67890";

      mockProductMap = {
        "12345": p1,
        "67890": p2,
      };
    });

    test('Should add product to cart when scanned', () {
      final pos = POSLogic(mockProductMap);
      pos.handleBarcode("12345");
      
      expect(pos.cart.length, 1);
      expect(pos.cart[0].product.name, "Milk");
      expect(pos.cart[0].quantity, 1);
    });

    test('Should increase quantity when same product is scanned twice', () {
      final pos = POSLogic(mockProductMap);
      pos.handleBarcode("12345");
      pos.handleBarcode("12345");
      
      expect(pos.cart.length, 1);
      expect(pos.cart[0].quantity, 2);
      expect(pos.totalAmount, 20.0);
    });

    test('Should add multiple different products to cart', () {
      final pos = POSLogic(mockProductMap);
      pos.handleBarcode("12345");
      pos.handleBarcode("67890");
      
      expect(pos.cart.length, 2);
      expect(pos.totalAmount, 15.0);
    });

    test('Should ignore unknown barcodes', () {
      final pos = POSLogic(mockProductMap);
      pos.handleBarcode("99999");
      
      expect(pos.cart.isEmpty, true);
    });
  });
}
