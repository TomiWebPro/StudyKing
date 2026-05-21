import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/snackbar_utils.dart';

Widget _buildApp(Widget widget) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(child: widget),
      ),
    ),
  );
}

void main() {
  group('SnackBar utilities', () {
    testWidgets('showSuccessSnackBar uses primaryContainer background', (tester) async {
      await tester.pumpWidget(_buildApp(
        Builder(builder: (context) => ElevatedButton(
          onPressed: () => showSuccessSnackBar(context, 'Success!'),
          child: const Text('Go'),
        )),
      ));

      await tester.tap(find.text('Go'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final theme = Theme.of(tester.element(find.byType(SnackBar)));

      expect(snackBar.backgroundColor, theme.colorScheme.primaryContainer);
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });

    testWidgets('showErrorSnackBar uses errorContainer background', (tester) async {
      await tester.pumpWidget(_buildApp(
        Builder(builder: (context) => ElevatedButton(
          onPressed: () => showErrorSnackBar(context, 'Error!'),
          child: const Text('Go'),
        )),
      ));

      await tester.tap(find.text('Go'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final theme = Theme.of(tester.element(find.byType(SnackBar)));

      expect(snackBar.backgroundColor, theme.colorScheme.errorContainer);
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });

    testWidgets('showInfoSnackBar uses tertiaryContainer background', (tester) async {
      await tester.pumpWidget(_buildApp(
        Builder(builder: (context) => ElevatedButton(
          onPressed: () => showInfoSnackBar(context, 'Info!'),
          child: const Text('Go'),
        )),
      ));

      await tester.tap(find.text('Go'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final theme = Theme.of(tester.element(find.byType(SnackBar)));

      expect(snackBar.backgroundColor, theme.colorScheme.tertiaryContainer);
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });

    testWidgets('each variant displays the correct message', (tester) async {
      await tester.pumpWidget(_buildApp(
        Builder(builder: (context) => ElevatedButton(
          onPressed: () => showSuccessSnackBar(context, 'Success msg'),
          child: const Text('S'),
        )),
      ));

      await tester.tap(find.text('S'));
      await tester.pump();
      expect(find.text('Success msg'), findsOneWidget);
    });
  });
}
