import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/connectivity_service.dart';
import 'services/local_db_service.dart';
import 'services/sync_service.dart';
import 'screens/pos_scanner_screen.dart';
import 'screens/bulk_import_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final localDb = LocalDbService();
  await localDb.init();
  
  final syncService = SyncService(localDb);
  final connectivityService = ConnectivityService(syncService);
  connectivityService.startListening();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: localDb),
        Provider.value(value: syncService),
        ChangeNotifierProvider.value(value: connectivityService),
      ],
      child: const KanachApp(),
    ),
  );
}

class KanachApp extends StatelessWidget {
  const KanachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KANACH',
      theme: ThemeData(primarySwatch: Colors.emerald, useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final isOffline = !isOnline;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('KANACH Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.emerald[900],
        elevation: 0,
        actions: [
          if (isOffline)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.red, size: 14),
                  SizedBox(width: 6),
                  Text("Offline", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
            Text("Shop Manager", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.emerald[900])),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardItem(
                    title: "POS Scanner",
                    icon: Icons.qr_code_scanner,
                    color: Colors.emerald,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const POSScannerScreen())),
                  ),
                  _DashboardItem(
                    title: "Bulk Import",
                    icon: Icons.grid_view_rounded,
                    color: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkImportExportScreen())),
                  ),
                  _DashboardItem(
                    title: "Inventory",
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  _DashboardItem(
                    title: "Sales Report",
                    icon: Icons.analytics_outlined,
                    color: Colors.purple,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardItem({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }
}
