import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/export_section.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

AppLocalizations _testL10n() => lookupAppLocalizations(const Locale('en'));

void main() {
  group('ExportSection.formatInstrumentation', () {
    test('formats instrumentation with complete data', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
        'planAdherence': {'overall': '85%', 'weekly': '72%'},
        'masteryImprovement': {'algebra': '+15%', 'geometry': '+8%'},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationGenerated('2024-06-15T10:00:00.000')));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains('overall: 85%'));
      expect(result, contains('weekly: 72%'));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
      expect(result, contains('algebra: +15%'));
      expect(result, contains('geometry: +8%'));
    });

    test('formats instrumentation with empty data', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationGenerated('2024-06-15T10:00:00.000')));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });

    test('formats instrumentation with null sections', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
        'planAdherence': null,
        'masteryImprovement': null,
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });

    test('formats instrumentation with empty map sections', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
        'planAdherence': <String, dynamic>{},
        'masteryImprovement': <String, dynamic>{},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });

    test('formats instrumentation with generatedAt as empty string', () {
      final l10n = _testL10n();
      final Map<String, dynamic> data = {
        'generatedAt': '',
        'planAdherence': <String, dynamic>{'metric': 'value'},
        'masteryImprovement': <String, dynamic>{'topic': 'improvement'},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationGenerated('')));
    });

    test('formats instrumentation with missing generatedAt', () {
      final l10n = _testL10n();
      final Map<String, dynamic> data = {
        'planAdherence': <String, dynamic>{'overall': '80%'},
        'masteryImprovement': <String, dynamic>{},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
    });

    test('formats instrumentation with generatedAt as null', () {
      final l10n = _testL10n();
      final Map<String, dynamic> data = {
        'generatedAt': null,
        'planAdherence': null,
        'masteryImprovement': null,
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });
  });
}
