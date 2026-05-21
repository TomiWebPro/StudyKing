import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/painters/grid_painter.dart';

const _painterKey = Key('grid_painter_custom_paint');

Widget buildGridPainterWidget({
  Color gridColor = const Color(0xFF9E9E9E),
  double width = 200,
  double height = 200,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          key: _painterKey,
          painter: GridPainter(gridColor: gridColor),
          size: Size(width, height),
        ),
      ),
    ),
  );
}

void main() {
  group('GridPainter widget', () {
    testWidgets('renders CustomPaint with default color', (tester) async {
      await tester.pumpWidget(buildGridPainterWidget());
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders CustomPaint with custom color', (tester) async {
      await tester.pumpWidget(
        buildGridPainterWidget(gridColor: Colors.blue),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with zero size without crashing', (tester) async {
      await tester.pumpWidget(
        buildGridPainterWidget(width: 0, height: 0),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with non-square size', (tester) async {
      await tester.pumpWidget(
        buildGridPainterWidget(width: 300, height: 100),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with very large size without crashing', (tester) async {
      await tester.pumpWidget(
        buildGridPainterWidget(width: 3000, height: 3000),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('renders with very small size', (tester) async {
      await tester.pumpWidget(
        buildGridPainterWidget(width: 3, height: 3),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });

    testWidgets('re-renders when grid color changes', (tester) async {
      await tester.pumpWidget(
        buildGridPainterWidget(gridColor: Colors.red),
      );
      expect(find.byKey(_painterKey), findsOneWidget);

      await tester.pumpWidget(
        buildGridPainterWidget(gridColor: Colors.blue),
      );
      expect(find.byKey(_painterKey), findsOneWidget);
    });
  });
}
