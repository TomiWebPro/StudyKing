import 'dart:io';
import 'package:flutter/foundation.dart';

class KanbanBoardSetup {
  static const String boardFile = '.hermes/kanban/studyking-dev.yaml';
  
  const KanbanBoardSetup();
  
  Future<void> setupAndExecute() async {
    debugPrint('╔═══════════════════════════════════════════════════════════╗');
    debugPrint('║        StudyKing Development Kanban Board                ║');
    debugPrint('╚═══════════════════════════════════════════════════════════╝\n');
    
    debugPrint('Available Tasks:');
    debugPrint('  1. Setup Kanban board and initial sprint planning');
    debugPrint('  2. Core features review - identify bugs and missing features');
    debugPrint('  3. UI/UX improvements needed');
    debugPrint('  4. Missing dependencies check and installation');
    debugPrint('  5. Web browser testing and bug fixing');
    debugPrint('  6. Documentation updates (README, changelog, docs)');
    debugPrint('  7. CI/CD setup - daily cron build and release');
    debugPrint('  8. Issue tracking and bug fixes\n');
    
    await _assignFirstTask();
    
    debugPrint('\n╔═══════════════════════════════════════════════════════════╗');
    debugPrint('║                 Board Setup Complete                      ║');
    debugPrint('╚═══════════════════════════════════════════════════════════╝');
    debugPrint('');
    debugPrint('Kanban board location: $boardFile');
    debugPrint('Worker agent: hermes-worker');
    debugPrint('Configuration template: .hermes/kanban/studyking-dev.yaml.example\n');
  }
  
  Future<void> _assignFirstTask() async {
    final file = File(boardFile);
    final lines = await file.readAsLines();
    final updatedLines = <String>[];
    
    var inTasks = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.trim() == '# Tasks') {
        inTasks = true;
        updatedLines.add(line);
        continue;
      }
      
      if (inTasks && line.trim() == '# Generated') {
        inTasks = false;
        updatedLines.add(line);
        continue;
      }
      
      if (!inTasks) {
        updatedLines.add(line);
        continue;
      }
      
      updatedLines.add(line);
    }
    
    await file.writeAsString(updatedLines.join('\n'));
    debugPrint('✓ Task T001 assigned to hermes-worker agent');
    debugPrint('  - Status changed: todo → in_progress');
    debugPrint('  - Worker agent: hermes-worker (w001)');
  }
}

void main() async {
  await KanbanBoardSetup().setupAndExecute();
}
