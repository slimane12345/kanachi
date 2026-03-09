import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/connectivity_service.dart';
import 'services/local_db_service.dart';
import 'services/sync_service.dart';

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
      appBar: AppBar(
        title: const Text('KANACH Dashboard'),
        actions: [
          if (isOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                   Icon(Icons.cloud_off, color: Colors.red, size: 16),
                   SizedBox(width: 4),
                   Text("Offline Mode", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to KANACH Mobile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Example: Add a sale locally
              },
              child: const Text("Create Sale (Offline Ready)"),
            ),
          ],
        ),
      ),
    );
  }
}
