import 'package:hive_flutter/hive_flutter.dart';
import '../models/source_model.dart';

class SourceRepository {
  late Box<Source> _box;

  Future<void> init() async {
    _box = Hive.box<Source>('sources');
  }

  Future<void> create(Source source) async {
    await _box.put(source.id, source);
  }

  Future<Source?> get(String id) async {
    return _box.get(id);
  }

  Future<List<Source>> getAll() async {
    return _box.values.toList();
  }
}
