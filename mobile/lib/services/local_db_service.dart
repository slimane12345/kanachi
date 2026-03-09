import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/debt_transaction.dart';

class LocalDbService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ProductSchema, CustomerSchema, SaleSchema, DebtTransactionSchema],
      directory: dir.path,
    );
  }

  // Generic Save with Sync Metadata
  Future<void> save<T>(T item) async {
    if (item is Product) {
      item.updatedAt = DateTime.now();
      item.isDirty = true;
      await isar.writeTxn(() => isar.products.put(item));
    } else if (item is Customer) {
      item.updatedAt = DateTime.now();
      item.isDirty = true;
      await isar.writeTxn(() => isar.customers.put(item));
    } else if (item is Sale) {
      item.updatedAt = DateTime.now();
      item.isDirty = true;
      await isar.writeTxn(() => isar.sales.put(item));
    } else if (item is DebtTransaction) {
      item.updatedAt = DateTime.now();
      item.isDirty = true;
      await isar.writeTxn(() => isar.debtTransactions.put(item));
    }
  }

  // Get Dirty Records (to be pushed)
  Future<List<Product>> getDirtyProducts() => isar.products.where().isDirtyEqualTo(true).findAll();
  Future<List<Customer>> getDirtyCustomers() => isar.customers.where().isDirtyEqualTo(true).findAll();
  Future<List<Sale>> getDirtySales() => isar.sales.where().isDirtyEqualTo(true).findAll();
  Future<List<DebtTransaction>> getDirtyDebts() => isar.debtTransactions.where().isDirtyEqualTo(true).findAll();

  // Mark as Synced
  Future<void> markSynced<T>(T item, DateTime syncTime) async {
    if (item is Product) {
      item.isDirty = false;
      item.lastSyncedAt = syncTime;
      await isar.writeTxn(() => isar.products.put(item));
    } else if (item is Customer) {
      item.isDirty = false;
      item.lastSyncedAt = syncTime;
      await isar.writeTxn(() => isar.customers.put(item));
    } else if (item is Sale) {
      item.isDirty = false;
      item.lastSyncedAt = syncTime;
      await isar.writeTxn(() => isar.sales.put(item));
    } else if (item is DebtTransaction) {
      item.isDirty = false;
      item.lastSyncedAt = syncTime;
      await isar.writeTxn(() => isar.debtTransactions.put(item));
    }
  }

  // Preload Products for fast lookup
  Future<Map<String, Product>> getBarcodeMap() async {
    final products = await isar.products.where().findAll();
    return {
      for (var p in products)
        if (p.barcode != null) p.barcode!: p
    };
  }

  Future<void> bulkSaveProducts(List<Product> products) async {
    await isar.writeTxn(() async {
      final now = DateTime.now();
      for (var p in products) {
        p.updatedAt = now;
        p.isDirty = true;
      }
      await isar.products.putAll(products);
    });
  }

  Future<List<Product>> getAllProducts() async {
    return await isar.products.where().findAll();
  }
}
