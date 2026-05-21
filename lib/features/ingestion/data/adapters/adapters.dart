import 'package:hive_flutter/hive_flutter.dart';
import 'source_adapter.dart';

void registerIngestionAdapters() {
  if (!Hive.isAdapterRegistered(26)) {
    Hive.registerAdapter(SourceAdapter());
  }
}
