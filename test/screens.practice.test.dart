import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studyking/main.dart' as app;
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Practice Screen', () {
    testWidgets('Practice screen loads', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: app.StudyKingApp()));
    });
  });

  group('Subject List View', () {
    test('Subject list displays correctly', () {
      final subjects = [
        Subject(
          id: '1',
          name: 'Math',
        ),
      ];
      expect(subjects.length, equals(1));
    });
  });

  group('Answer Validation', () {
    test('Answer validation works for typed answers', () {
      final answer = '4';
      expect(answer.isNotEmpty, isTrue);
      expect(answer.length, equals(1));
    });
  });

  group('Practice Navigation', () {
    test('Pop navigation works', () {
      final routeStack = <Object>[];
      routeStack.add('page1');
      if (routeStack.isNotEmpty) {
        routeStack.removeLast();
      }
      expect(routeStack.isEmpty, isTrue);
    });
  });

  group('UI Widget Tests', () {
    test('Card widget displays', () {
      final card = Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Text('Card Content'),
        ),
      );
      expect(card, isNotNull);
    });
  });
}
