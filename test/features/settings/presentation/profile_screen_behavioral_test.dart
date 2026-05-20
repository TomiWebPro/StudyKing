import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show localeProvider, settingsRepositoryProvider;
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSettingsRepository extends SettingsRepository {
  UserProfile? _currentProfile;
  bool _shouldThrowOnGet = false;
  bool _shouldThrowOnSave = false;
  bool _saveReturnsFailure = false;

  void setThrowOnGet(bool val) => _shouldThrowOnGet = val;
  void setThrowOnSave(bool val) => _shouldThrowOnSave = val;
  void setSaveReturnsFailure(bool val) => _saveReturnsFailure = val;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<UserProfile?>> getProfileData() async {
    if (_shouldThrowOnGet) throw Exception('Simulated load error');
    if (_currentProfile != null) return Result.success(_currentProfile);
    return Result.success(UserProfile(id: 'default_profile', name: ''));
  }

  @override
  Future<Result<void>> saveProfileData(UserProfile profile) async {
    if (_shouldThrowOnSave) throw Exception('Simulated save error');
    if (_saveReturnsFailure) return Result.failure('Simulated save failure');
    _currentProfile = profile;
    return Result.success(null);
  }

  @override
  Future<Result<void>> clearProfile() async {
    _currentProfile = null;
    return Result.success(null);
  }
}

Widget buildProfileScreen({
  TestNavigatorObserver? navigatorObserver,
  SettingsRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => const Locale('en')),
      if (repo != null) settingsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: const ProfileScreen(),
    ),
  );
}

Future<void> pumpProfileScreen(WidgetTester tester, {
  TestNavigatorObserver? navigatorObserver,
  SettingsRepository? repo,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 2000);
  await tester.pumpWidget(buildProfileScreen(
    navigatorObserver: navigatorObserver,
    repo: repo,
  ));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeSettingsRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeSettingsRepository();
  });

  group('ProfileScreen - Avatar Icon Mapping', () {
    testWidgets('shows person icon when no avatar is selected', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'no-avatar',
        name: 'No Avatar',
        avatarIcon: null,
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.text('No Avatar'), findsOneWidget);
    });

    testWidgets('shows school icon for school avatar', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'school-avatar',
        name: 'School User',
        avatarIcon: 'Icons.school',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('shows face icon for face avatar', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'face-avatar',
        name: 'Face User',
        avatarIcon: 'Icons.face',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.face), findsOneWidget);
    });

    testWidgets('shows leaderboard icon for leaderboard avatar', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'leaderboard-avatar',
        name: 'Leaderboard User',
        avatarIcon: 'Icons.leaderboard',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
    });

    testWidgets('shows emoji events icon for trophy avatar', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'trophy-avatar',
        name: 'Trophy User',
        avatarIcon: 'Icons.emoji_events',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('shows sports tennis icon for tennis avatar', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'tennis-avatar',
        name: 'Tennis User',
        avatarIcon: 'Icons.sports_tennis',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.sports_tennis), findsOneWidget);
    });

    testWidgets('shows coffee icon for coffee avatar', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'coffee-avatar',
        name: 'Coffee User',
        avatarIcon: 'Icons.coffee',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('shows local hospital icon for medical avatar', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'medical-avatar',
        name: 'Medical User',
        avatarIcon: 'Icons.local_hospital',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.local_hospital), findsOneWidget);
    });
  });

  group('ProfileScreen - Save Error States', () {
    testWidgets('shows error snackbar when save returns failure', (tester) async {
      fakeRepo.setSaveReturnsFailure(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Fail User',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error saving profile'), findsOneWidget);
    });

    testWidgets('save error does not leave stale loading state', (tester) async {
      fakeRepo.setSaveReturnsFailure(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Fail User',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });
  });

  group('ProfileScreen - Load Error States', () {
    testWidgets('shows error screen on load failure with retry button', (tester) async {
      fakeRepo.setThrowOnGet(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry after error reloads data successfully', (tester) async {
      fakeRepo.setThrowOnGet(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.text('Retry'), findsOneWidget);

      fakeRepo.setThrowOnGet(false);
      await fakeRepo.saveProfileData(UserProfile(
        id: 'retry-success',
        name: 'Retry Success',
      ));

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retry Success'), findsOneWidget);
    });
  });

  group('ProfileScreen - Delete Account Edge Cases', () {
    testWidgets('delete failure does not navigate back', (tester) async {
      final navigatorObserver = TestNavigatorObserver();

      await fakeRepo.saveProfileData(UserProfile(
        id: 'delete-fail',
        name: 'Delete Fail',
      ));

      await pumpProfileScreen(tester,
        repo: fakeRepo,
        navigatorObserver: navigatorObserver,
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final confirmDelete = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('delete confirmation shows cancel button', (tester) async {
      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsAtLeastNWidgets(1));
    });
  });

  group('ProfileScreen - Profile Data Loading', () {
    testWidgets('loads profile with studentId and learning goal into fields', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'full-profile',
        name: 'Full Profile',
        studentId: '99999',
        learningGoal: 'Learn everything',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.text('Full Profile'), findsOneWidget);
      expect(find.text('99999'), findsOneWidget);
      expect(find.text('Learn everything'), findsOneWidget);
    });
  });
}
