import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_db_service.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/debt_transaction.dart';

class SyncService {
  final LocalDbService localDb;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  SyncService(this.localDb);

  // --- Push Sync ---
  Future<void> pushToCloud() async {
    final products = await localDb.getDirtyProducts();
    for (var p in products) {
      await firestore.collection('products').doc(p.remoteId).set({
        'name': p.name,
        'price': p.price,
        'stock': p.stock,
        'minThreshold': p.minThreshold,
        'category': p.category,
        'updatedAt': p.updatedAt.toIso8601String(),
      });
      await localDb.markSynced(p, DateTime.now());
    }

    final customers = await localDb.getDirtyCustomers();
    for (var c in customers) {
      await firestore.collection('customers').doc(c.remoteId).set({
        'name': c.name,
        'phone': c.phone,
        'totalDebt': c.totalDebt,
        'updatedAt': c.updatedAt.toIso8601String(),
      });
      await localDb.markSynced(c, DateTime.now());
    }

    final sales = await localDb.getDirtySales();
    for (var s in sales) {
      await firestore.collection('sales').doc(s.remoteId).set({
        'date': s.date.toIso8601String(),
        'totalAmount': s.totalAmount,
        'customerId': s.customerId,
        'items': s.items.map((i) => {
          'productId': i.productId,
          'productName': i.productName,
          'quantity': i.quantity,
          'price': i.price,
        }).toList(),
        'updatedAt': s.updatedAt.toIso8601String(),
      });
      await localDb.markSynced(s, DateTime.now());
    }

    final debts = await localDb.getDirtyDebts();
    for (var d in debts) {
      await firestore.collection('debts').doc(d.remoteId).set({
        'customerId': d.customerId,
        'amount': d.amount,
        'type': d.type,
        'date': d.date.toIso8601String(),
        'note': d.note,
        'updatedAt': d.updatedAt.toIso8601String(),
      });
      await localDb.markSynced(d, DateTime.now());
    }
  }

  // --- Pull Sync ---
  Future<void> pullFromCloud() async {
    // Strategy: Fetch records updated after last local update
    // For simplicity, we'll fetch everything updated after the latest 'lastSyncedAt' among all records
    // or just fetch all and compare timestamps.
    
    // Example for Products
    final snapshot = await firestore.collection('products').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final remoteUpdatedAt = DateTime.parse(data['updatedAt']);
      final remoteId = doc.id;

      final localProduct = await localDb.isar.products.where().remoteIdEqualTo(remoteId).findFirst();
      
      if (localProduct == null || remoteUpdatedAt.isAfter(localProduct.updatedAt)) {
        // Overwrite or create local
        final p = localProduct ?? Product()..remoteId = remoteId;
        p.name = data['name'];
        p.price = data['price'];
        p.stock = data['stock'];
        p.minThreshold = data['minThreshold'];
        p.category = data['category'];
        p.updatedAt = remoteUpdatedAt;
        p.isDirty = false;
        p.lastSyncedAt = DateTime.now();
        await localDb.isar.writeTxn(() => localDb.isar.products.put(p));
      }
    }
    
    // Example for Customers
    final customerSnap = await firestore.collection('customers').get();
    for (var doc in customerSnap.docs) {
      final data = doc.data();
      final remoteUpdatedAt = DateTime.parse(data['updatedAt']);
      final remoteId = doc.id;
      final local = await localDb.isar.customers.where().remoteIdEqualTo(remoteId).findFirst();
      if (local == null || remoteUpdatedAt.isAfter(local.updatedAt)) {
        final c = local ?? Customer()..remoteId = remoteId;
        c.name = data['name'];
        c.phone = data['phone'];
        c.totalDebt = data['totalDebt'] ?? 0;
        c.updatedAt = remoteUpdatedAt;
        c.isDirty = false;
        c.lastSyncedAt = DateTime.now();
        await localDb.isar.writeTxn(() => localDb.isar.customers.put(c));
      }
    }

    // Example for Sales
    final salesSnap = await firestore.collection('sales').get();
    for (var doc in salesSnap.docs) {
      final data = doc.data();
      final remoteUpdatedAt = DateTime.parse(data['updatedAt']);
      final remoteId = doc.id;
      final local = await localDb.isar.sales.where().remoteIdEqualTo(remoteId).findFirst();
      if (local == null || remoteUpdatedAt.isAfter(local.updatedAt)) {
        final s = local ?? Sale()..remoteId = remoteId;
        s.date = DateTime.parse(data['date']);
        s.totalAmount = data['totalAmount'];
        s.customerId = data['customerId'];
        s.items = (data['items'] as List).map((i) => SaleItem()
          ..productId = i['productId']
          ..productName = i['productName']
          ..quantity = i['quantity']
          ..price = i['price']).toList();
        s.updatedAt = remoteUpdatedAt;
        s.isDirty = false;
        s.lastSyncedAt = DateTime.now();
        await localDb.isar.writeTxn(() => localDb.isar.sales.put(s));
      }
    }

    // Example for Debts
    final debtSnap = await firestore.collection('debts').get();
    for (var doc in debtSnap.docs) {
      final data = doc.data();
      final remoteUpdatedAt = DateTime.parse(data['updatedAt']);
      final remoteId = doc.id;
      final local = await localDb.isar.debtTransactions.where().remoteIdEqualTo(remoteId).findFirst();
      if (local == null || remoteUpdatedAt.isAfter(local.updatedAt)) {
        final d = local ?? DebtTransaction()..remoteId = remoteId;
        d.customerId = data['customerId'];
        d.amount = data['amount'];
        d.type = data['type'];
        d.date = DateTime.parse(data['date']);
        d.note = data['note'];
        d.updatedAt = remoteUpdatedAt;
        d.isDirty = false;
        d.lastSyncedAt = DateTime.now();
        await localDb.isar.writeTxn(() => localDb.isar.debtTransactions.put(d));
      }
    }
  }
}
