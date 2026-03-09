import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import '../models/product.dart';
import 'package:uuid/uuid.dart';

class ImportResult {
  final List<Product> validProducts;
  final List<String> errors;
  final int totalRows;

  ImportResult({required this.validProducts, required this.errors, required this.totalRows});
}

class ProductImportService {
  Future<ImportResult> parseFile(File file, String extension) async {
    if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcel(file);
    } else if (extension == 'csv') {
      return _parseCsv(file);
    }
    return ImportResult(validProducts: [], errors: ['Unsupported file format'], totalRows: 0);
  }

  Future<ImportResult> _parseExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final List<Product> validProducts = [];
    final List<String> errors = [];
    int totalRows = 0;

    for (var table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      if (rows.isEmpty) continue;

      // Skip header
      for (var i = 1; i < rows.length; i++) {
        totalRows++;
        final row = rows[i];
        final res = _validateRow(
          name: row[0]?.value?.toString(),
          price: row[1]?.value?.toString(),
          barcode: row[2]?.value?.toString(),
          stock: row[3]?.value?.toString(),
          rowIdx: i + 1,
        );

        if (res.error != null) {
          errors.add(res.error!);
        } else if (res.product != null) {
          validProducts.add(res.product!);
        }
      }
    }

    return ImportResult(validProducts: validProducts, errors: errors, totalRows: totalRows);
  }

  Future<ImportResult> _parseCsv(File file) async {
    final input = file.openRead();
    final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
    
    final List<Product> validProducts = [];
    final List<String> errors = [];
    int totalRows = 0;

    if (fields.length <= 1) return ImportResult(validProducts: [], errors: [], totalRows: 0);

    // Skip header
    for (var i = 1; i < fields.length; i++) {
      totalRows++;
      final row = fields[i];
      if (row.length < 2) continue;

      final res = _validateRow(
        name: row[0]?.toString(),
        price: row[1]?.toString(),
        barcode: row.length > 2 ? row[2]?.toString() : null,
        stock: row.length > 3 ? row[3]?.toString() : null,
        rowIdx: i + 1,
      );

      if (res.error != null) {
        errors.add(res.error!);
      } else if (res.product != null) {
        validProducts.add(res.product!);
      }
    }

    return ImportResult(validProducts: validProducts, errors: errors, totalRows: totalRows);
  }

  _ValidationResult _validateRow({String? name, String? price, String? barcode, String? stock, required int rowIdx}) {
    if (name == null || name.isEmpty) {
      return _ValidationResult(error: 'Row $rowIdx: Name is missing');
    }
    
    final p = double.tryParse(price ?? '');
    if (p == null) {
      return _ValidationResult(error: 'Row $rowIdx: Invalid price ($price)');
    }

    final s = int.tryParse(stock ?? '0') ?? 0;

    final product = Product()
      ..remoteId = const Uuid().v4()
      ..name = name
      ..price = p
      ..barcode = barcode?.trim()
      ..stock = s
      ..minThreshold = 5
      ..isDirty = true
      ..updatedAt = DateTime.now();

    return _ValidationResult(product: product);
  }
}

class _ValidationResult {
  final Product? product;
  final String? error;
  _ValidationResult({this.product, this.error});
}
