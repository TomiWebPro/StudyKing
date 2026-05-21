import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_backup_service.dart';

final dataBackupServiceProvider = Provider<DataBackupService>((ref) {
  return DataBackupService();
});
