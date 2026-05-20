import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show localeProvider, settingsRepositoryProvider;
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSettingsRepository extends SettingsRepository {
  UserProfile? _currentProfile;
  bool _shouldReturnFailure = false;
  bool _shouldReturnNull = false;
  bool _shouldThrowOnSave = false;

  void setReturnFailure(bool val) {
    _shouldReturnFailure = val;
    _shouldReturnNull = false;
  }

  void setReturnNull(bool val) {
    _shouldReturnNull = val;
    _shouldReturnFailure = false;
  }

  void setThrowOnSave(bool val) => _shouldThrowOnSave = val;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<UserProfile?>> getProfileData() async {
    if (_shouldReturnFailure) return Result.failure('Test failure');
    if (_shouldReturnNull) return Result.success(null);
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
    _currentProfile = null;
    return Result.success(null);
  }
}

Widget buildProfileScreen({SettingsRepository? repo}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => const Locale('en')),
      if (repo != null) settingsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const ProfileScreen(),
    ),
  );
}

Future<void> pumpProfileScreen(WidgetTester tester, {SettingsRepository? repo}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 2000);
  await tester.pumpWidget(buildProfileScreen(repo: repo));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeSettingsRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeSettingsRepository();
  });

  group('ProfileScreen - Failure on getProfileData', () {
    testWidgets('shows error state with failure message when repo returns failure', (tester) async {
      fakeRepo.setReturnFailure(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('ProfileScreen - null profile data', () {
    testWidgets('shows empty form with default person avatar when profile is null', (tester) async {
      fakeRepo.setReturnNull(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      expect(find.byType(TextField), findsWidgets);
      expect(find.byIcon(Icons.person), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
    });

    testWidgets('null profile shows empty text fields', (tester) async {
      fakeRepo.setReturnNull(true);

      await pumpProfileScreen(tester, repo: fakeRepo);

      final nameField = find.widgetWithText(TextField, 'Full Name');
      expect(nameField, findsOneWidget);
      final textField = tester.widget<TextField>(nameField);
      expect(textField.controller?.text, isEmpty);
    });
  });

  group('ProfileScreen - Exception during save', () {
    testWidgets('shows error snackbar when save throws exception', (tester) async {
      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Save Error User',
      );
      await tester.pumpAndSettle();

      fakeRepo.setThrowOnSave(true);

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('screen remains stable after save exception', (tester) async {
      await pumpProfileScreen(tester, repo: fakeRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Save Error User',
      );
      await tester.pumpAndSettle();

      fakeRepo.setThrowOnSave(true);

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
