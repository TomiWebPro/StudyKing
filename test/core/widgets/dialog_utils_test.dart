import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/dialog_utils.dart';

void main() {
  group('showConfirmationDialog', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showConfirmationDialog(
              context,
              title: 'Test Title',
              message: 'Test Message',
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    testWidgets('confirm button pops with true', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmationDialog(
                context,
                title: 'Title',
                message: 'Message',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancel button pops with false', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmationDialog(
                context,
                title: 'Title',
                message: 'Message',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('backdrop dismiss returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmationDialog(
                context,
                title: 'Title',
                message: 'Message',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('shows custom confirm label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showConfirmationDialog(
              context,
              title: 'Title',
              message: 'Message',
              confirmLabel: 'Yes',
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Yes'), findsOneWidget);
    });

    testWidgets('shows custom cancel label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showConfirmationDialog(
              context,
              title: 'Title',
              message: 'Message',
              cancelLabel: 'No',
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('No'), findsOneWidget);
    });
  });
}
