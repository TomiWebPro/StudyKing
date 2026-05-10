import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('StudyKing app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyKingApp()));
  });

  testWidgets('StudyKing app has proper structure', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyKingApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
