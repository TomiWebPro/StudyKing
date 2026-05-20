import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/data/hive_box_names.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/logger.dart';

class DataBackupService {
  static final Logger _logger = const Logger('DataBackupService');

  /// Collects data from all open Hive boxes into a map of box name → records.
  Map<String, List<Map<String, dynamic>>> collectAllBoxData() {
    final data = <String, List<Map<String, dynamic>>>{};
    final boxNames = HiveBoxNames.allBackupBoxes;
    for (final boxName in boxNames) {
      if (!Hive.isBoxOpen(boxName)) continue;
      final box = Hive.box(boxName);
      final records = <Map<String, dynamic>>[];
      for (final value in box.values) {
        final map = _toMap(value);
        if (map != null) records.add(map);
      }
      if (records.isNotEmpty) data[boxName] = records;
    }
    return data;
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    try {
      return (value as dynamic).toJson() as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Result<String>> exportAllData({
    required Map<String, List<Map<String, dynamic>>> boxData,
    String? filename,
    String? outputDir,
    bool compress = true,
  }) async {
    if (kIsWeb) {
      return Result.failure('Backup/restore is not supported on web');
    }
    try {
      final backup = {
        'version': compress ? 2 : 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'boxes': boxData,
      };

      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = outputDir == 'persistent'
          ? await getApplicationDocumentsDirectory()
          : await getTemporaryDirectory();
      final ext = compress ? '.skbak' : '.json';
      final file = File('${dir.path}/${filename ?? 'studyking_backup'}$ext');

      if (compress) {
        final compressed = GZipEncoder().encode(utf8.encode(json)) as Uint8List;
        await file.writeAsBytes(compressed);
        _logger.i('Backup exported to ${file.path} (${compressed.length} bytes, gzip)');
      } else {
        await file.writeAsString(json);
        _logger.i('Backup exported to ${file.path} (${json.length} bytes)');
      }
      return Result.success(file.path);
    } catch (e) {
      _logger.w('Failed to export backup', e);
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

      late Map<String, dynamic> data;
      if (filePath.endsWith('.skbak')) {
        final bytes = await file.readAsBytes();
        final decompressed = GZipDecoder().decodeBytes(bytes);
        final jsonStr = utf8.decode(decompressed);
        data = jsonDecode(jsonStr) as Map<String, dynamic>;
      } else {
        final json = await file.readAsString();
        data = jsonDecode(json) as Map<String, dynamic>;
      }

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
      _logger.w('Failed to restore backup', e);
      return Result.failure(e.toString());
    }
  }
}
