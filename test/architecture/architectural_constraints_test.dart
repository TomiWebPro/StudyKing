import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architectural constraints', () {
    final projectRoot = Directory.current.path;
    // Normalize to project root
    final libDir = '$projectRoot/lib';

    group('Feature → Feature imports', () {
      // Allowlist: cross-feature screen navigation or provider wiring that is
      // architecturally acceptable (presentation layer only, via well-defined
      // provider interfaces).
      final allowlist = <String>[
        // Settings debug screen inspects feature providers for diagnostic display
        'lib/features/settings/presentation/settings_screen.dart',
        // Mentor screen needs access to planner, session, and teaching providers
        'lib/features/mentor/presentation/mentor_screen.dart',
        'lib/features/mentor/presentation/widgets/',
        // Dashboard aggregates data from practice and planner
        'lib/features/dashboard/presentation/',
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
              violations.add(
                  '${file.replaceAll('$projectRoot/', '')}: $count throw(s)');
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
