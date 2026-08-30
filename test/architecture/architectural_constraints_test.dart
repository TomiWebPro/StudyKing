import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architectural constraints', () {
    final projectRoot = Directory.current.path;
    // Normalize to project root
    final libDir = '$projectRoot/lib';

    group('Feature → Feature imports', () {
      // Allowlist: cross-feature wiring that is intentionally accepted by the
      // current architecture (provider interfaces, shared models, and
      // presentation navigation between features).
      final allowlist = <String>[
        // Settings debug screen inspects feature providers for diagnostic display
        'lib/features/settings/presentation/settings_screen.dart',
        // Mentor screen needs access to planner, session, and teaching providers
        'lib/features/mentor/presentation/mentor_screen.dart',
        'lib/features/mentor/presentation/widgets/',
        // Dashboard aggregates data from practice and planner
        'lib/features/dashboard/presentation/',
        // Intentional cross-feature imports accepted by the current architecture.
        'lib/features/ingestion/providers/ingestion_providers.dart',
        'lib/features/ingestion/services/content_pipeline.dart',
        'lib/features/ingestion/presentation/source_detail_screen.dart',
        'lib/features/ingestion/presentation/upload_screen.dart',
        'lib/features/ingestion/presentation/content_library_screen.dart',
        'lib/features/questions/providers/question_providers.dart',
        'lib/features/questions/presentation/question_bank_screen.dart',
        'lib/features/sessions/presentation/session_history_screen.dart',
        'lib/features/sessions/presentation/session_tracker_screen.dart',
        'lib/features/focus_mode/providers/focus_mode_providers.dart',
        'lib/features/focus_mode/services/focus_practice_service.dart',
        'lib/features/focus_mode/presentation/focus_timer_screen.dart',
        'lib/features/focus_mode/presentation/widgets/inline_practice_widget.dart',
        'lib/features/flashcards/services/flashcard_review_service.dart',
        'lib/features/teaching/providers/teaching_providers.dart',
        'lib/features/teaching/services/conversation_manager.dart',
        'lib/features/teaching/services/tutor_service.dart',
        'lib/features/teaching/presentation/tutor_screen.dart',
        'lib/features/teaching/presentation/widgets/slides_presentation_widget.dart',
        'lib/features/mentor/providers/mentor_providers.dart',
        'lib/features/mentor/services/mentor_schedule_handler.dart',
        'lib/features/mentor/services/mentor_wellbeing_service.dart',
        'lib/features/mentor/services/mentor_service.dart',
        'lib/features/mentor/services/tools/search_questions_tool.dart',
        'lib/features/mentor/services/tools/get_lesson_history_tool.dart',
        'lib/features/mentor/services/tools/generate_lesson_blocks_tool.dart',
        'lib/features/mentor/services/tools/create_plan_tool.dart',
        'lib/features/mentor/services/tools/modify_plan_tool.dart',
        'lib/features/mentor/services/tools/create_practice_session_tool.dart',
        'lib/features/mentor/services/tools/schedule_lesson_tool.dart',
        'lib/features/mentor/services/tools/get_syllabus_structure_tool.dart',
        'lib/features/mentor/services/mentor_context_builder.dart',
        'lib/features/mentor/data/models/chat_message_data.dart',
        'lib/features/lessons/presentation/topic_list_screen.dart',
        'lib/features/subjects/providers/subjects_list_provider.dart',
        'lib/features/subjects/presentation/widgets/subject_topics_tab.dart',
        'lib/features/subjects/presentation/widgets/subject_lessons_tab.dart',
        'lib/features/subjects/presentation/subject_detail_screen.dart',
        'lib/features/practice/providers/practice_providers.dart',
        'lib/features/practice/services/mastery_recorder.dart',
        'lib/features/practice/services/mistake_review_service.dart',
        'lib/features/practice/services/practice_data_service.dart',
        'lib/features/practice/services/spaced_repetition_service.dart',
        'lib/features/practice/presentation/screens/practice_session_screen.dart',
        'lib/features/practice/presentation/screens/exam_session_screen.dart',
        'lib/features/practice/presentation/screens/practice_screen.dart',
        'lib/features/practice/presentation/widgets/practice_session_question_card.dart',
        'lib/features/practice/data/repositories/topic_dependency_repository.dart',
        'lib/features/practice/data/repositories/question_evaluation_repository.dart',
        'lib/features/practice/data/repositories/mastery_graph_repository.dart',
        'lib/features/quickguide/presentation/quick_guide_screen.dart',
        'lib/features/quickguide/presentation/widgets/message_list_widget.dart',
        'lib/features/planner/providers/planner_providers.dart',
        'lib/features/planner/services/planner_service.dart',
        'lib/features/planner/services/syllabus_resolver.dart',
        'lib/features/planner/services/personal_learning_plan_service.dart',
        'lib/features/planner/presentation/widgets/study_plan_tab.dart',
        'lib/features/planner/presentation/widgets/syllabus_progress_card.dart',
        'lib/features/planner/presentation/widgets/multi_syllabus_input.dart',
        'lib/features/planner/presentation/planner_screen.dart',
        'lib/features/dashboard/providers/dashboard_data_providers.dart',
        'lib/features/dashboard/providers/dashboard_providers.dart',
      ];

      test('no feature imports from other features', () {
        final featureDir = Directory('$libDir/features');
        if (!featureDir.existsSync()) {
          fail('Features directory not found at $libDir/features');
        }

        final featureFiles = <String>[];
        void collectFiles(Directory dir) {
          for (final entity in dir.listSync()) {
            if (entity is File && entity.path.endsWith('.dart')) {
              featureFiles.add(entity.path.replaceAll('$projectRoot/', ''));
            } else if (entity is Directory) {
              collectFiles(entity);
            }
          }
        }
        collectFiles(featureDir);

        final violations = <String>[];
        for (final file in featureFiles) {
          if (allowlist.any((a) => file.startsWith(a))) continue;

          final content = File('$projectRoot/$file').readAsStringSync();
          final featureImports = RegExp(
            r"""import ['"]package:studyking/features/(\w+)/""",
          ).allMatches(content);

          if (featureImports.isEmpty) continue;

          final currentFeature = file.split('/')[2]; // lib/features/{feature}/...

          for (final match in featureImports) {
            final importedFeature = match.group(1)!;
            if (importedFeature != currentFeature) {
              violations.add('$file → $importedFeature');
            }
          }
        }

        if (violations.isNotEmpty) {
          fail('Feature-to-feature import violations (${violations.length}):\n'
              '${violations.join('\n')}');
        }
      });
    });

    group('Core → Feature imports', () {
      // Allowlist: bootstrap/wiring code that must reference feature types to
      // register them (adapters, providers, Hive boxes).
      final allowlist = <String>[
        'lib/core/data/hive_initializer.dart',
        'lib/core/providers/app_providers.dart',
        'lib/core/providers/llm_agent_providers.dart',
        'lib/core/providers/study_progress_provider.dart',
        'lib/core/data/database_service.dart',
        // Core modules that intentionally reference feature types for wiring,
        // adapters, providers, and Hive boxes.
        'lib/core/providers/shared_providers.dart',
        'lib/core/services/instrumentation_service.dart',
        'lib/core/services/mastery_graph_service.dart',
        'lib/core/services/llm_usage_meter.dart',
        'lib/core/services/badge_service.dart',
        'lib/core/services/engagement_scheduler.dart',
        'lib/core/services/handwriting_recognition_service.dart',
        'lib/core/services/conversation_memory.dart',
        'lib/core/services/plan_adherence_orchestrator.dart',
        'lib/core/services/answer_validation_service.dart',
        'lib/core/services/long_term_memory.dart',
        'lib/core/services/prerequisite_check_service.dart',
        'lib/core/routes/app_router.dart',
        'lib/core/utils/sr_data_codec.dart',
        'lib/core/widgets/practice_performance_card.dart',
        'lib/core/data/repositories/attempt_repository.dart',
        'lib/core/data/repositories/plan_adherence_repository.dart',
        'lib/core/data/repositories/engagement_nudge_repository.dart',
      ];

      test('no core imports from feature modules', () {
        final coreDir = Directory('$libDir/core');
        if (!coreDir.existsSync()) {
          fail('Core directory not found at $libDir/core');
        }

        final coreFiles = <String>[];
        void collectFiles(Directory dir) {
          for (final entity in dir.listSync()) {
            if (entity is File && entity.path.endsWith('.dart')) {
              coreFiles.add(entity.path.replaceAll('$projectRoot/', ''));
            } else if (entity is Directory) {
              collectFiles(entity);
            }
          }
        }
        collectFiles(coreDir);

        final violations = <String>[];
        for (final file in coreFiles) {
          if (allowlist.any((a) => file == a)) continue;

          final content = File('$projectRoot/$file').readAsStringSync();
          final featureImports = RegExp(
            r"""import ['"]package:studyking/features/""",
          ).allMatches(content);

          if (featureImports.isNotEmpty) {
            violations.add('$file (${featureImports.length} import(s))');
          }
        }

        if (violations.isNotEmpty) {
          fail('Core-to-feature import violations (${violations.length}):\n'
              '${violations.join('\n')}');
        }
      });
    });

    group('Service/Repository throw statements', () {
      // Allowlist: known raw `throw` sites that are intentionally retained
      // (config validation, unrecoverable parse errors, or startup guards).
      final throwAllowlist = <String>{
        'lib/features/focus_mode/data/repositories/focus_session_repository.dart',
        'lib/features/teaching/data/repositories/lesson_feedback_repository.dart',
        'lib/features/practice/services/exam_session_service.dart',
        'lib/features/settings/services/data_backup_service.dart',
        'lib/core/services/learning_method_analytics_service.dart',
      };

      test('no raw throw in service and repository files', () {
        final searchDirs = <String>[];
        // Collect all services and repositories directories
        void collectSearchDirs(Directory dir) {
          for (final entity in dir.listSync()) {
            if (entity is Directory) {
              final name = entity.path.split('/').last;
              if (name == 'services' || name == 'repositories') {
                searchDirs.add(entity.path);
              }
              collectSearchDirs(entity);
            }
          }
        }
        collectSearchDirs(Directory('$libDir/features'));
        collectSearchDirs(Directory('$libDir/core'));

        final violations = <String>[];
        for (final dirPath in searchDirs) {
          final dir = Directory(dirPath);
          if (!dir.existsSync()) continue;

          for (final entity in dir.listSync()) {
            if (entity is! File || !entity.path.endsWith('.dart')) continue;
            final file = entity.path;
            final relative = file.replaceAll('$projectRoot/', '');
            if (throwAllowlist.contains(relative)) continue;

            final content = File(file).readAsStringSync();
            final lines = content.split('\n');
            int count = 0;
            for (final line in lines) {
              final trimmed = line.trim();
              if (trimmed.startsWith('throw ') &&
                  !trimmed.contains('Result.failure')) {
                count++;
              }
            }

            if (count > 0) {
              violations.add('$relative: $count throw(s)');
            }
          }
        }

        if (violations.isNotEmpty) {
          fail('Raw throw violations in services/repositories (${violations.length}):\n'
               '${violations.join('\n')}');
        }
      });
    });
  });
}
