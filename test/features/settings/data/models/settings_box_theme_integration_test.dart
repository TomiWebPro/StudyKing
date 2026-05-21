import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

void main() {
  group('SettingsBox widget usage', () {
    testWidgets('theme mode is usable in widgets', (tester) async {
      final settings = SettingsBox(themeMode: ThemeMode.dark.index);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: settings.themeModeEnum,
          home: const Scaffold(body: Text('Settings')),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
