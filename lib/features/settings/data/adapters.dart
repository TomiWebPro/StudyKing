import 'package:hive_flutter/hive_flutter.dart';
import 'models/settings_box.dart';

void registerSettingsAdapters() {
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(SettingsBoxAdapter());
  }
}
