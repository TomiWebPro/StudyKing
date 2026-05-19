import 'package:hive_flutter/hive_flutter.dart';
import 'session_adapter.dart';

void registerSessionAdapters() {
  if (!Hive.isAdapterRegistered(36)) {
    Hive.registerAdapter(SessionAdapter());
  }
}
