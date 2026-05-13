import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/practice_screen.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';

class _FakeSubjectRepository extends SubjectRepository {
  _FakeSubjectRepository(this.subjects);
  final List<Subject> subjects;

  @override
  Future<List<Subject>> getAll() async => subjects;
}

class _TestSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  _TestSubjectsRepositoryNotifier(this.loader);
  final Future<SubjectRepository> Function() loader;

  @override
  Future<SubjectRepository> build() => loader();
}

class _TestNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  Subject subject(String id, String name) => Subject(id: id, name: name, createdAt: DateTime.utc(2024, 1, 1));

  Widget buildApp({
    required Future<SubjectRepository> Function() loader,
    NavigatorObserver? observer,
  }) {
    return ProviderScope(
      overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestSubjectsRepositoryNotifier(loader),
        ),
      ],
      child: MaterialApp(
        navigatorObservers: observer == null ? const [] : [observer],
        home: const PracticeScreen(),
      ),
    );
  }

  group('PracticeScreen', () {
    testWidgets('shows loading indicator before subjects resolve', (tester) async {
      final completer = Completer<SubjectRepository>();

      await tester.pumpWidget(buildApp(loader: () => completer.future));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_FakeSubjectRepository(const []));
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when no subjects exist', (tester) async {
      await tester.pumpWidget(buildApp(loader: () async => _FakeSubjectRepository(const [])));
      await tester.pumpAndSettle();

      expect(find.text('No Practice Sessions Yet'), findsOneWidget);
      expect(find.text('No Subjects'), findsOneWidget);
      expect(find.text('Practice'), findsNothing);
    });

    testWidgets('navigates to practice session from FAB tap', (tester) async {
      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        buildApp(loader: () async => _FakeSubjectRepository([subject('s1', 'Math')]), observer: observer),
      );
      await tester.pumpAndSettle();

      final initialPushes = observer.pushCount;
      await tester.tap(find.text('Practice'));
      await tester.pump();
      expect(observer.pushCount, greaterThan(initialPushes));

      expect(find.byType(PracticeScreen), findsOneWidget);
    });

  });
}
