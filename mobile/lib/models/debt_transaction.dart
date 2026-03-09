import 'package:isar/isar.dart';
import 'sync_metadata.dart';

part 'debt_transaction.g.dart';

@collection
class DebtTransaction with SyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late String customerId;
  late double amount;
  late String type; // 'credit' or 'payment'
  late DateTime date;
  String? note;

  @override
  late DateTime updatedAt;
  
  @override
  late bool isDirty;
  
  @override
  DateTime? lastSyncedAt;
}
