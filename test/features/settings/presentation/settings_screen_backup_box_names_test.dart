import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'settings_screen_test_helpers.dart';

/// Backup service fake that reports fixed per-box record counts, so the
/// export summary dialog renders one summary line per box.
class _FixedBoxDataBackupService extends FakeDataBackupService {
  final Map<String, List<Map<String, dynamic>>> _boxData;

  _FixedBoxDataBackupService(this._boxData);

  @override
  Map<String, List<Map<String, dynamic>>> collectAllBoxData() => _boxData;
}

Map<String, List<Map<String, dynamic>>> _boxDataWithOneRecordPerBox() => {
      HiveBoxNames.agentMemory: [{'id': 'am-1'}],
      HiveBoxNames.examResults: [
        {'id': 'er-1'},
        {'id': 'er-2'},
        {'id': 'er-3'},
      ],
      HiveBoxNames.studentId: [{'id': 'sid-1'}],
      HiveBoxNames.dashboardLayoutPrefs: [{'id': 'dlp-1'}],
      HiveBoxNames.dbVersion: [{'id': 'dv-1'}],
    };

Future<void> _openExportSummaryDialog(WidgetTester tester, String exportTileText) async {
  await scrollToWidget(tester, find.widgetWithText(ListTile, exportTileText));
  await tester.tap(find.widgetWithText(ListTile, exportTileText));
  await tester.pumpAndSettle();

  // Full export (includeSensitive == false) first asks to confirm the
  // sensitive-data warning, then shows the summary dialog.
  await tester.tap(find.widgetWithText(FilledButton, exportTileText));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, exportTileText));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    fakeRepo.settings = SettingsBox(themeMode: 0, fontSize: 16.0);
  });

  group('SettingsScreen - backup box display names', () {
    testWidgets('export summary shows localized box names in Spanish', (tester) async {
      await pumpWithSettings(
        tester,
        backupService: _FixedBoxDataBackupService(_boxDataWithOneRecordPerBox()),
        locale: const Locale('es'),
      );

      await _openExportSummaryDialog(tester, 'Exportar Copia');

      expect(find.text('Memoria del agente: 1 registro'), findsOneWidget);
      expect(find.text('Resultados de examen: 3 registros'), findsOneWidget);
      expect(find.text('ID del estudiante: 1 registro'), findsOneWidget);
      expect(find.text('Diseño del panel: 1 registro'), findsOneWidget);
      expect(find.text('Versión de la BD: 1 registro'), findsOneWidget);

      // The five previously-hardcoded English names must not leak into the
      // Spanish UI.
      expect(find.text('Agent Memory'), findsNothing);
      expect(find.text('Exam Results'), findsNothing);
      expect(find.text('Student ID'), findsNothing);
      expect(find.text('Dashboard Layout'), findsNothing);
      expect(find.text('DB Version'), findsNothing);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });

    testWidgets('export summary shows English box names via l10n', (tester) async {
      await pumpWithSettings(
        tester,
        backupService: _FixedBoxDataBackupService(_boxDataWithOneRecordPerBox()),
      );

      await _openExportSummaryDialog(tester, 'Export Backup');

      expect(find.text('Agent Memory: 1 record'), findsOneWidget);
      expect(find.text('Exam Results: 3 records'), findsOneWidget);
      expect(find.text('Student ID: 1 record'), findsOneWidget);
      expect(find.text('Dashboard Layout: 1 record'), findsOneWidget);
      expect(find.text('DB Version: 1 record'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });
}
