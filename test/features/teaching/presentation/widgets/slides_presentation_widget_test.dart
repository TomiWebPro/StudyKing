import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/teaching/presentation/widgets/slides_presentation_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: widget),
  );
}

LessonBlock slideBlock({String content = 'Slide content', SlideType? slideType}) {
  return LessonBlock(
    id: 'block-1',
    subjectId: 'subj-1',
    lessonId: 'lesson-1',
    type: LessonBlockType.slide,
    content: content,
    slideType: slideType,
  );
}

void main() {
  group('SlidesPresentationWidget', () {
    testWidgets('renders slide content', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock(content: 'Hello World')],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('shows page indicator', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'Slide 1'),
            slideBlock(content: 'Slide 2'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('shows close button', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock()],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows full-screen toggle button', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock()],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('shows thumbnail grid button', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock()],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    testWidgets('navigates to next slide', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'First slide'),
            slideBlock(content: 'Second slide'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('First slide'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Second slide'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('navigates to previous slide', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'First slide'),
            slideBlock(content: 'Second slide'),
          ],
          initialIndex: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Second slide'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('First slide'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('close button pops navigator', (tester) async {
      final observer = NavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SlidesPresentationWidget(
                      blocks: [slideBlock()],
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
        navigatorObservers: [observer],
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('toggling controls shows and hides top/bottom bars', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock()],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.fullscreen), findsNothing);

      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('thumbnail grid button opens grid view', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'Slide 1'),
            slideBlock(content: 'Slide 2'),
            slideBlock(content: 'Slide 3'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tapping thumbnail navigates to that slide', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'Slide A'),
            slideBlock(content: 'Slide B'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.text('Slide B'), findsOneWidget);
    });

    testWidgets('back button from grid returns to presentation', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock(content: 'Slide 1')],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('slide dots indicator shows correct count', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'S1'),
            slideBlock(content: 'S2'),
            slideBlock(content: 'S3'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('previous button is disabled on first slide', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'Slide 1'),
            slideBlock(content: 'Slide 2'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      final prevIcon = tester.widget<Icon>(find.byIcon(Icons.chevron_left));
      final prevButton = tester.widget<IconButton>(
        find.ancestor(of: find.byWidget(prevIcon), matching: find.byType(IconButton)),
      );
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('next button is disabled on last slide', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'Slide 1'),
            slideBlock(content: 'Slide 2'),
          ],
          initialIndex: 1,
        ),
      ));
      await tester.pumpAndSettle();

      final nextIcon = tester.widget<Icon>(find.byIcon(Icons.chevron_right));
      final nextButton = tester.widget<IconButton>(
        find.ancestor(of: find.byWidget(nextIcon), matching: find.byType(IconButton)),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('InteractiveViewer wraps slide content', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock(content: 'Zoomable content')],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('single slide shows 1/1 indicator', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [slideBlock(content: 'Only slide')],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('thumbnail grid shows slide type icons', (tester) async {
      await tester.pumpWidget(buildApp(
        SlidesPresentationWidget(
          blocks: [
            slideBlock(content: 'Concept', slideType: SlideType.concept),
            slideBlock(content: 'Formula', slideType: SlideType.formula),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.byIcon(Icons.functions), findsOneWidget);
    });
  });
}
