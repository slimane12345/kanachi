import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/local_db_service.dart';
import '../services/product_import_service.dart';
import '../models/product.dart';

class BulkImportExportScreen extends StatefulWidget {
  const BulkImportExportScreen({super.key});

  @override
  State<BulkImportExportScreen> createState() => _BulkImportExportScreenState();
}

class _BulkImportExportScreenState extends State<BulkImportExportScreen> {
  final _importService = ProductImportService();
  bool _isProcessing = false;
  List<String> _errors = [];
  int _successCount = 0;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _isProcessing = true;
      _errors = [];
      _successCount = 0;
    });

    try {
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension!;
      final importResult = await _importService.parseFile(file, extension);

      if (importResult.validProducts.isNotEmpty) {
        final db = context.read<LocalDbService>();
        await db.bulkSaveProducts(importResult.validProducts);
        _successCount = importResult.validProducts.length;
      }

      setState(() {
        _errors = importResult.errors;
      });

      if (mounted) {
        _showResultSummary(importResult.totalRows);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResultSummary(int total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Import Result", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total rows processed: $total"),
            const SizedBox(height: 8),
            Text("Successfully imported: $_successCount", style: const TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold)),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("Errors: ${_errors.length}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  Future<void> _exportProducts(String format) async {
    setState(() => _isProcessing = true);
    try {
      final db = context.read<LocalDbService>();
      final products = await db.getAllProducts();
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/products_export_${DateTime.now().millisecondsSinceEpoch}.$format";
      final file = File(path);

      if (format == 'xlsx') {
        var excel = Excel.createExcel();
        Sheet sheetObject = excel['Products'];
        sheetObject.appendRow([TextCellValue('Name'), TextCellValue('Price'), TextCellValue('Barcode'), TextCellValue('Stock')]);
        for (var p in products) {
          sheetObject.appendRow([
            TextCellValue(p.name),
            DoubleCellValue(p.price),
            TextCellValue(p.barcode ?? ''),
            IntCellValue(p.stock),
          ]);
        }
        file.writeAsBytesSync(excel.save()!);
      } else {
        List<List<dynamic>> rows = [
          ["Name", "Price", "Barcode", "Stock"]
        ];
        for (var p in products) {
          rows.add([p.name, p.price, p.barcode ?? '', p.stock]);
        }
        String csv = const ListToCsvConverter().convert(rows);
        file.writeAsStringSync(csv);
      }

      await Share.shareXFiles([XFile(path)], text: 'Products Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareTemplate() async {
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/product_import_template.xlsx";
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    sheetObject.appendRow([
      TextCellValue('Name'),
      TextCellValue('Price'),
      TextCellValue('Barcode'),
      TextCellValue('Stock')
    ]);
    sheetObject.appendRow([
      TextCellValue('Sample Product'),
      DoubleCellValue(10.5),
      TextCellValue('123456789'),
      IntCellValue(100)
    ]);
    
    final file = File(path);
    file.writeAsBytesSync(excel.save()!);
    await Share.shareXFiles([XFile(path)], text: 'Product Import Template');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Bulk Import / Export", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.emerald[900],
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  title: "Import Products",
                  subtitle: "Upload Excel or CSV file to add products in bulk.",
                  icon: Icons.upload_file,
                  color: Colors.emerald,
                  onTap: _pickAndImport,
                  actionLabel: "PICK FILE",
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: "Download Template",
                  subtitle: "Get the required Excel format for bulk import.",
                  icon: Icons.download_for_offline,
                  color: Colors.blue,
                  onTap: _shareTemplate,
                  actionLabel: "GET TEMPLATE",
                ),
                const SizedBox(height: 32),
                Text("Export Data", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.1)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildExportButton("Export Excel", Icons.table_chart, Colors.green, () => _exportProducts('xlsx')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildExportButton("Export CSV", Icons.description, Colors.blueGrey, () => _exportProducts('csv')),
                    ),
                  ],
                ),
                if (_errors.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text("Import Errors (${_errors.length})", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red[400])),
                  const SizedBox(height: 12),
                  Container(
                    maxHeight: 300,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.1))),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _errors.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        title: Text(_errors[index], style: GoogleFonts.poppins(fontSize: 13, color: Colors.red[900])),
                        dense: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Colors.emerald)),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, required String actionLabel}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[900])), Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]))])),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: Text(actionLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1)))),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
