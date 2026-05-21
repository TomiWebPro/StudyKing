import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/services/prerequisite_check_service.dart';

Topic _topic(String id, String subjectId, String title) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: title,
    syllabusText: '',
    description: '',
  );
}

void main() {
  group('showPrerequisiteDialog', () {
    testWidgets('shows dialog with unmet topics', (tester) async {
      final topics = <Topic>[
        _topic('t1', 's1', 'Algebra'),
        _topic('t2', 's1', 'Geometry'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await PrerequisiteCheckService
                      .showPrerequisiteDialog(
                    context,
                    unmetTopics: topics,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Prerequisites Not Met'), findsOneWidget);
      expect(find.textContaining('Algebra'), findsOneWidget);
      expect(find.textContaining('Geometry'), findsOneWidget);
      expect(find.text('Continue Anyway'), findsOneWidget);
      expect(find.text('Practice Prerequisites'), findsOneWidget);
    });

    testWidgets('tapping Practice Prerequisites returns true', (tester) async {
      final topics = <Topic>[
        _topic('t1', 's1', 'Algebra'),
      ];

      bool? dialogResult;
      bool callbackCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await PrerequisiteCheckService
                      .showPrerequisiteDialog(
                    context,
                    unmetTopics: topics,
                    onPracticePrerequisites: () {
                      callbackCalled = true;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice Prerequisites'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(callbackCalled, isTrue);
    });

    testWidgets('tapping Continue Anyway returns false', (tester) async {
      final topics = <Topic>[
        _topic('t1', 's1', 'Algebra'),
      ];

      bool? dialogResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await PrerequisiteCheckService
                      .showPrerequisiteDialog(
                    context,
                    unmetTopics: topics,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Anyway'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });
  });
}
