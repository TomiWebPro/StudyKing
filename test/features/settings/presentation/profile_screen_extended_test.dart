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
  bool _shouldThrowOnClear = false;

  void setThrowOnGet(bool val) => _shouldThrowOnGet = val;
  void setThrowOnSave(bool val) => _shouldThrowOnSave = val;
  void setThrowOnClear(bool val) => _shouldThrowOnClear = val;

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
    _currentProfile = profile;
    return Result.success(null);
  }

  @override
  Future<Result<void>> clearProfile() async {
    if (_shouldThrowOnClear) return Result.failure('Simulated clear error');
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

  group('ProfileScreen - Loading State', () {
    testWidgets('shows loading indicator on initial load', (tester) async {
      final repo = _FakeSettingsRepository();
      repo._shouldThrowOnGet = true;

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 2000);
      await tester.pumpWidget(buildProfileScreen(repo: repo));
      // Don't settle - capture loading state
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('transitions from loading to content after load completes', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'test-loading',
        name: 'Loaded User',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Loaded User'), findsOneWidget);
    });
  });

  group('ProfileScreen - Error State', () {
    testWidgets('shows error screen when exception occurs during load', (tester) async {
      fakeRepo.setThrowOnGet(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsAtLeastNWidgets(1));
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping retry after error reloads data', (tester) async {
      fakeRepo.setThrowOnGet(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.text('Retry'), findsOneWidget);

      fakeRepo.setThrowOnGet(false);
      await fakeRepo.saveProfileData(UserProfile(
        id: 'retry-test',
        name: 'Retry User',
      ));

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retry User'), findsOneWidget);
    });
  });

  group('ProfileScreen - Save Exception', () {
    testWidgets('shows error snackbar when save throws exception', (tester) async {
      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Error User',
      );
      await tester.pumpAndSettle();

      fakeRepo.setThrowOnSave(true);

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('save error does not prevent subsequent saves', (tester) async {
      fakeRepo.setThrowOnSave(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Retry Save',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      fakeRepo.setThrowOnSave(false);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Retry Save Updated',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.text('Profile saved successfully'), findsOneWidget);
    });
  });

  group('ProfileScreen - Delete Account', () {
    testWidgets('delete confirmation shows warning message', (tester) async {
      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.textContaining('cannot be undone'), findsOneWidget);
    });

    testWidgets('cancel delete does not clear profile', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'cancel-delete-test',
        name: 'Cancel Delete Test',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      final profileResult = await fakeRepo.getProfileData();
      expect(profileResult.isSuccess, isTrue);
      expect(profileResult.data, isNotNull);
      expect(profileResult.data!.name, equals('Cancel Delete Test'));
    });

    testWidgets('delete failure returns without navigating', (tester) async {
      fakeRepo.setThrowOnClear(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      final openDeleteButton = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(openDeleteButton);
      await tester.pumpAndSettle();

      final confirmDelete = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('successful delete navigates back', (tester) async {
      final navigatorObserver = TestNavigatorObserver();
      await fakeRepo.saveProfileData(UserProfile(
        id: 'delete-test-success',
        name: 'Delete Me',
      ));

      await pumpProfileScreen(tester,
        repo: fakeRepo,
        navigatorObserver: navigatorObserver,
      );

      final openDeleteButton = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(openDeleteButton);
      await tester.pumpAndSettle();

      final confirmDelete = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      expect(navigatorObserver.poppedRoutes, isNotEmpty);
    });
  });

  group('ProfileScreen - Language Label', () {
    testWidgets('shows language display name for English locale', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'lang-display',
        name: 'Language Test',
        language: 'en',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.text('English'), findsWidgets);
    });

    testWidgets('shows language display name for Spanish locale', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'lang-es',
        name: 'Spanish User',
        language: 'es',
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.text('Spanish'), findsWidgets);
    });
  });

  group('ProfileScreen - Notifications Toggle', () {
    testWidgets('notifications can be toggled off', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'notif-test',
        name: 'Notif User',
        notificationsEnabled: true,
      ));

      await pumpProfileScreen(tester, repo: fakeRepo);

      final switchTile = find.widgetWithText(SwitchListTile, 'Notifications');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<SwitchListTile>(switchTile);
      expect(updatedSwitch.value, isFalse);
    });
  });
}
