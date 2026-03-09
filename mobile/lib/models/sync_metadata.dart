import 'package:isar/isar.dart';

mixin SyncMetadata {
  late DateTime updatedAt;
  late bool isDirty;
  DateTime? lastSyncedAt;
}
