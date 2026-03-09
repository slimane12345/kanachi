import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final SyncService syncService;
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityService(this.syncService);

  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
      
      if (wasOffline && _isOnline) {
        // Just came back online
        print("Device is back online. Starting sync...");
        syncService.pushToCloud();
        syncService.pullFromCloud();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
