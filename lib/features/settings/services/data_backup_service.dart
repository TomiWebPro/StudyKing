import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/logger.dart';

class DataBackupService {
  final Logger _logger = const Logger('DataBackupService');

  Future<Result<String>> exportAllData({
    required Map<String, List<Map<String, dynamic>>> boxData,
    String? filename,
    String? outputDir,
  }) async {
    if (kIsWeb) {
      return Result.failure('Backup/restore is not supported on web');
    }
    try {
      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'boxes': boxData,
      };

      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = outputDir == 'persistent'
          ? await getApplicationDocumentsDirectory()
          : await getTemporaryDirectory();
      final file = File('${dir.path}/${filename ?? 'studyking_backup'}.json');
      await file.writeAsString(json);
      _logger.i('Backup exported to ${file.path} (${json.length} bytes)');
      return Result.success(file.path);
    } catch (e) {
      _logger.e('Failed to export backup', e);
      return Result.failure(e.toString());
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

  Future<Result<Map<String, List<Map<String, dynamic>>>>> restoreData(
    String filePath,
  ) async {
    if (kIsWeb) {
      return Result.failure('Backup/restore is not supported on web');
    }
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.failure('Backup_not_found: $filePath');
      }
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;

      if (!data.containsKey('version') ||
          !data.containsKey('exportedAt') ||
          !data.containsKey('boxes')) {
        return Result.failure('Invalid_backup_format');
      }

      final boxes = data['boxes'] as Map<String, dynamic>;
      final result = <String, List<Map<String, dynamic>>>{};
      for (final entry in boxes.entries) {
        final list = entry.value as List;
        result[entry.key] = list.cast<Map<String, dynamic>>();
      }

      final totalRecords =
          result.values.fold(0, (int s, l) => s + l.length);
      _logger.i(
        'Backup loaded from $filePath (${result.length} boxes, $totalRecords records)',
      );
      return Result.success(result);
    } catch (e) {
      _logger.e('Failed to restore backup', e);
      return Result.failure(e.toString());
    }
  }
}
