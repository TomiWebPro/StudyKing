import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

void main() async {
  Hive.initFlutter();
  
  final taskBox = await Hive.openBox<Map<String, dynamic>>('tasks');
  
  final tasks = [
    {
      'id': 'T1',
      'title': 'research: Analyze current UX patterns',
      'description': 'Evaluate if the current UI feels modern and intuitive',
      'status': 'todo',
      'priority': 'medium',
      'createdAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'updatedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    },
    {
      'id': 'T2',
      'title': 'research: Check API integration health',
      'description': 'See if all API calls are working smoothly',
      'status': 'todo',
      'priority': 'medium',
      'createdAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'updatedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    },
    {
      'id': 'T3',
      'title': 'roadmap: Plan next sprint features',
      'description': 'Identify 3-5 features to ship in the next 2 weeks',
      'status': 'todo',
      'priority': 'high',
      'createdAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'updatedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    },
    {
      'id': 'T4',
      'title': 'maintenance: Review and update CHANGELOG.md',
      'description': 'Sync version numbers and recent commits',
      'status': 'todo',
      'priority': 'low',
      'createdAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'updatedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    },
    {
      'id': 'T5',
      'title': 'ui-test: Validate visual design on mobile',
      'description': 'Test on a physical device or emulator',
      'status': 'todo',
      'priority': 'medium',
      'createdAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'updatedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    },
  ];

  for (final task in tasks) {
    await taskBox.put(task['id'], task);
  }

  debugPrint('Created ${taskBox.length} tasks for "StudyKing Dev" Kanban board');
  debugPrint('\nTasks:');
  for (final task in tasks) {
    debugPrint('  - ${task['id']}: ${task['title']}');
  }
}
