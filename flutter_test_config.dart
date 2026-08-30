import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Global test bootstrap (lightweight, non-regressive).
///
/// Only guarantees Hive has a storage path set (an isolated per-process temp
/// dir) so tests that open boxes without first calling `Hive.init` get a sane
/// default instead of "Hive is not initialized".
///
/// It deliberately does NOT register adapters or open boxes: many test suites
/// register their own adapters in `setUpAll`/`setUp`, and pre-registering
/// globally would throw "adapter already registered" and regress them. Boxes
/// and adapters remain each suite's responsibility.
///
/// The isolated temp path also avoids cross-process contention when tests are
/// run in parallel.
Future<void> testExecutable(Future<void> Function() testMain) async {
  try {
    final dir = Directory.systemTemp.createTempSync('studyking_hive_');
    // Hive.init just (re)sets the storage path; safe to call even if a test
    // later calls Hive.init again with its own path.
    Hive.init(dir.path);
  } catch (_) {
    // Hive unavailable in this environment; suites manage their own storage.
  }
  await testMain();
}
