import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/shimmer_widget.dart';

void main() {
  group('ShimmerWidget', () {
    testWidgets('renders Container with given color and border radius',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShimmerWidget(
            width: 200,
            height: 100,
            color: Colors.grey,
          ),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.grey));
      expect(decoration.borderRadius, equals(BorderRadius.circular(4)));
    });

    testWidgets('animation starts at 0.3 and reaches 1.0 over full cycle',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShimmerWidget(
            width: 100,
            height: 100,
            color: Colors.grey,
          ),
        ),
      ));

      final initialOpacity =
          tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(initialOpacity, closeTo(0.3, 0.01));

      await tester.pump(const Duration(milliseconds: 750));
      final midOpacity =
          tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(midOpacity, greaterThan(0.3));

      await tester.pump(const Duration(milliseconds: 750));
      final endOpacity =
          tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(endOpacity, closeTo(1.0, 0.01));
    });

    testWidgets('renders with different color and dimensions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShimmerWidget(
            width: 300,
            height: 50,
            color: Colors.blue,
          ),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.blue));
    });
  });
}
