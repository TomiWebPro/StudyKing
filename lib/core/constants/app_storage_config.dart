import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageConfig {
  const StorageConfig._();

  static const String databaseName = 'studyking_v1.db';
  static const String hiveBoxName = 'studyking_storage_v1';
  static const String tempDirectoryName = 'temp';
  static const String cacheDirectoryName = 'cache';
  static const String studyMaterialsDirectoryName = 'studyking';

  static Future<String> appStoragePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, studyMaterialsDirectoryName);
    await Directory(path).create(recursive: true);
    return path;
  }

  static Future<String> tempDirectoryPath() async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, tempDirectoryName);
    await Directory(path).create(recursive: true);
    return path;
  }

  static Future<String> cacheDirectoryPath() async {
    final dir = await getApplicationCacheDirectory();
    final path = p.join(dir.path, cacheDirectoryName);
    await Directory(path).create(recursive: true);
    return path;
  }
}
