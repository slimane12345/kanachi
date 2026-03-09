import 'package:isar/isar.dart';
import 'sync_metadata.dart';

part 'sale.g.dart';

@collection
class Sale with SyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late DateTime date;
  late double totalAmount;
  late List<SaleItem> items;
  String? customerId;

  @override
  late DateTime updatedAt;
  
  @override
  late bool isDirty;
  
  @override
  DateTime? lastSyncedAt;
}

@embedded
class SaleItem {
  late String productId;
  late String productName;
  late int quantity;
  late double price;
}
