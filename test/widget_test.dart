// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StudyKing app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the app title loads 
    expect(find.text('StudyKing'), findsOneWidget);
    
    // Verify home screen navigation
    await tester.pumpAndSettle();
    
    // Check for bottom navigation
    expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
  });
}
