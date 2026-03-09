import 'package:isar/isar.dart';
import 'sync_metadata.dart';

part 'product.g.dart';

@collection
class Product with SyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  @Index(unique: true)
  String? barcode;

  late String name;
  late double price;
  late int stock;
  late int minThreshold;
  String? category;

  @override
  late DateTime updatedAt;
  
  @override
  late bool isDirty;
  
  @override
  DateTime? lastSyncedAt;
}
