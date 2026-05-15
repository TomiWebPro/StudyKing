import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';

void main() {
  testWidgets('open plan_adherence box', (tester) async {
    Hive.init(Directory.systemTemp.createTempSync('test_').path);
    
    final repo = PlanAdherenceRepository();
    await repo.init();
  });
}
