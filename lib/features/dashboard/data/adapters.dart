import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/badge_adapter.dart';

void registerDashboardAdapters() {
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(BadgeModelAdapter());
  }
}
