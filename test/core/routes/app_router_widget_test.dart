import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/not_found_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  group('_materialPageRoute (tested indirectly via onGenerateRoute)', () {
    testWidgets('transitionsBuilder produces FadeTransition widget',
        (tester) async {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.settings,
      )) as PageRouteBuilder;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              final animation = AnimationController(
                vsync: tester,
                value: 1,
              );
              final secondaryAnimation = AnimationController(
                vsync: tester,
                value: 1,
              );
              return route.transitionsBuilder(
                context,
                animation,
                secondaryAnimation,
                const Text('child'),
              );
            },
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
    });

    testWidgets('error route pageBuilder produces NotFoundScreen',
        (tester) async {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.subjectDetail,
      )) as PageRouteBuilder;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final animation = AnimationController(
                vsync: tester,
                value: 0,
              );
              return route.pageBuilder(context, animation, animation);
            },
          ),
        ),
      );

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });
}
