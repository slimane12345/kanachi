import 'package:isar/isar.dart';
import 'sync_metadata.dart';

part 'customer.g.dart';

@collection
class Customer with SyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late String name;
  String? phone;
  double totalDebt = 0;

  @override
  late DateTime updatedAt;
  
  @override
  late bool isDirty;
  
  @override
  DateTime? lastSyncedAt;
}
