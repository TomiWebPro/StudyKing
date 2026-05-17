import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../errors/result.dart';
import '../utils/logger.dart';

class DataBackupService {
  final Logger _logger = const Logger('DataBackupService');

  Future<Result<String>> exportAllData({
    required Map<String, List<Map<String, dynamic>>> boxData,
    String? filename,
  }) async {
    try {
      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'boxes': boxData,
      };

      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${filename ?? 'studyking_backup'}.json');
      await file.writeAsString(json);
      _logger.i('Backup exported to ${file.path} (${json.length} bytes)');
      return Result.success(file.path);
    } catch (e) {
      _logger.e('Failed to export backup', e);
      return Result.failure('Failed to export backup: $e');
    }
  }

  Future<Result<String>> exportSingleBox({
    required String boxName,
    required List<Map<String, dynamic>> records,
  }) async {
    return exportAllData(
      boxData: {boxName: records},
      filename: '${boxName}_backup',
    );
  }
}