import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductLookupResult {
  final String? name;
  final String? brand;
  final String? imageUrl;
  final bool found;

  ProductLookupResult({this.name, this.brand, this.imageUrl, required this.found});

  factory ProductLookupResult.notFound() => ProductLookupResult(found: false);
}

class ProductLookupService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product/';

  Future<ProductLookupResult> lookupBarcode(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$barcode.json')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final p = data['product'];
          return ProductLookupResult(
            name: p['product_name'] ?? p['product_name_fr'] ?? p['product_name_en'],
            brand: p['brands'],
            imageUrl: p['image_front_url'],
            found: true,
          );
        }
      }
      return ProductLookupResult.notFound();
    } catch (e) {
      print('Lookup error: $e');
      return ProductLookupResult.notFound();
    }
  }
}
