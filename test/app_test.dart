import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('StudyKing App', () {
    testWidgets('App loads successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: app.StudyKingApp()));
    });
  });
}
