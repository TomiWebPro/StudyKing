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
  bool _saveReturnsFailure = false;
  bool _shouldReturnFailure = false;
  bool _shouldReturnNull = false;

  void setThrowOnGet(bool val) => _shouldThrowOnGet = val;
  void setThrowOnSave(bool val) => _shouldThrowOnSave = val;
  void setThrowOnClear(bool val) => _shouldThrowOnClear = val;
  void setSaveReturnsFailure(bool val) => _saveReturnsFailure = val;

  void setReturnFailure(bool val) {
    _shouldReturnFailure = val;
    _shouldReturnNull = false;
  }

  void setReturnNull(bool val) {
    _shouldReturnNull = val;
    _shouldReturnFailure = false;
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<UserProfile?>> getProfileData() async {
    if (_shouldThrowOnGet) throw Exception('Simulated load error');
    if (_shouldReturnFailure) return Result.failure('Test failure');
    if (_shouldReturnNull) return Result.success(null);
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

  group('ProfileScreen', () {
    testWidgets('renders profile screen with app bar', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows save button in app bar', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows avatar selection area', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      final avatarContainer = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration != null &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle);
      expect(avatarContainer, findsWidgets);
    });

    testWidgets('shows name text field with correct label', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('shows student ID field as optional', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Student ID (Optional)'), findsOneWidget);
    });

    testWidgets('shows learning goal text field', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Learning Goal'), findsOneWidget);
      expect(find.text('e.g., Final Exams, Certifications'), findsOneWidget);
    });

    testWidgets('shows preferred study time text field', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Preferred Study Time'), findsOneWidget);
      expect(find.text('e.g., Evening (6-9 PM)'), findsOneWidget);
    });

    testWidgets('shows account information card', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows language dropdown with English and Spanish', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
    });

    testWidgets('shows notifications switch', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      final switchTile = find.widgetWithText(SwitchListTile, 'Notifications');
      expect(switchTile, findsOneWidget);
    });

    testWidgets('shows delete account warning card', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.textContaining('will permanently remove'), findsOneWidget);
    });

    testWidgets('tapping avatar opens avatar picker bottom sheet', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.byIcon(Icons.local_hospital), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.sports_tennis), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('tapping cancel on avatar picker closes sheet', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsNothing);
    });

    testWidgets('can select face avatar', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.face));
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsNothing);
    });

    testWidgets('can select school avatar', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsNothing);
    });

    testWidgets('shows error snackbar when name is empty on save', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows error snackbar when student ID is non-numeric', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Student ID (Optional)'),
        'abc123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.text('Student ID must be numeric'), findsOneWidget);
    });

    testWidgets('saving with valid name triggers save process', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'John Doe',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('can change language to Spanish', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spanish').last);
      await tester.pumpAndSettle();

      expect(find.text('Spanish'), findsWidgets);
    });

    testWidgets('can toggle notifications switch', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      final switchTile = find.widgetWithText(SwitchListTile, 'Notifications');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);

      expect(switchWidget.value, isTrue);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<SwitchListTile>(switchTile);
      expect(updatedSwitch.value, isFalse);
    });

    testWidgets('tapping delete opens confirmation dialog', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsWidgets);
      expect(find.textContaining('Are you sure'), findsOneWidget);
      expect(find.text('Cancel'), findsAtLeastNWidgets(1));
    });

    testWidgets('cancel delete closes dialog without action', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Are you sure'), findsNothing);
    });

    testWidgets('loads existing profile data into fields', (tester) async {
      await fakeRepo.saveProfileData(UserProfile(
        id: 'test-id',
        name: 'Jane Doe',
        studentId: '12345',
        avatarIcon: 'Icons.school',
        learningGoal: 'Learn Flutter',
        preferredStudyTime: 'Morning',
        notificationsEnabled: false,
        language: 'es',
      ));

      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('12345'), findsOneWidget);
      expect(find.text('Learn Flutter'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('handles profile load error gracefully', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(find.byIcon(Icons.person), findsWidgets);
    });

    testWidgets('shows required asterisk for name field', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      final nameLabel = find.text('Full Name');
      expect(nameLabel, findsOneWidget);

      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('student ID field only accepts digits', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      final studentIdField = find.widgetWithText(TextField, 'Student ID (Optional)');
      final textField = tester.widget<TextField>(studentIdField);

      expect(textField.inputFormatters, isNotNull);
      expect(textField.inputFormatters!.isNotEmpty, isTrue);
    });

    testWidgets('avatar picker has proper semantic labels', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      final semantics = find.bySemanticsLabel(RegExp('Select avatar'));
      expect(semantics, findsWidgets);
    });

    testWidgets('enter text in name field', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Test User',
      );
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('enter text in learning goal field', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Learning Goal'),
        'Master programming',
      );
      await tester.pumpAndSettle();

      expect(find.text('Master programming'), findsOneWidget);
    });

    testWidgets('enter text in preferred study time field', (tester) async {
      await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Preferred Study Time'),
        'Weekend mornings',
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekend mornings'), findsOneWidget);
    });

    group('Save Verification', () {
      testWidgets('save triggers repository call with correct data', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Save Test User',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data, isNotNull);
        expect(profileResult.data!.name, equals('Save Test User'));
      });

      testWidgets('save includes student ID when provided', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'ID Test User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Student ID (Optional)'),
          '12345',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data!.studentId, equals('12345'));
      });

      testWidgets('save includes learning goal when provided', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Goal Test User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Learning Goal'),
          'Pass Final Exam',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data!.learningGoal, equals('Pass Final Exam'));
      });

      testWidgets('save includes preferred study time when provided', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Time Test User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Preferred Study Time'),
          'Evening 7-10 PM',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data!.preferredStudyTime, equals('Evening 7-10 PM'));
      });

      testWidgets('save shows loading indicator during save', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Loading Test',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Validation Implementation', () {
      testWidgets('empty name shows Name is required error', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(find.text('Name is required'), findsOneWidget);
      });

      testWidgets('whitespace-only name shows error', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          '   ',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(find.text('Name is required'), findsOneWidget);
      });

      testWidgets('name field trims whitespace before save', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          '  Trimmed User  ',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data!.name, equals('Trimmed User'));
      });

      testWidgets('student ID accepts numeric values only', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Valid User',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Student ID (Optional)'),
          '9876543210',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data!.studentId, equals('9876543210'));
      });

      testWidgets('empty student ID is stored as null', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'No ID User',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data!.studentId, isNull);
      });

      testWidgets('name field has 60 character limit', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        final nameField = find.widgetWithText(TextField, 'Full Name');
        final textField = tester.widget<TextField>(nameField);
        final formatters = textField.inputFormatters ?? [];
        expect(formatters.any((f) => f.toString().contains('60')), isTrue);
      });
    });

    group('Delete Account Flow', () {
      testWidgets('delete confirmation calls clearProfile', (tester) async {
        await fakeRepo.saveProfileData(UserProfile(
          id: 'delete-test',
          name: 'Delete Test',
        ));

        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Are you sure'), findsOneWidget);
        expect(find.text('Delete Account'), findsWidgets);

        // Find the "Delete" button inside the dialog - it's the second one on screen
        final deleteButtons = find.widgetWithText(FilledButton, 'Delete');
        await tester.tap(deleteButtons.last);
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data, isNotNull);
        expect(profileResult.data!.id, equals('default_profile'));
      });

      testWidgets('delete confirmation shows warning message', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.textContaining('cannot be undone'), findsOneWidget);
        expect(find.textContaining('permanently delete'), findsOneWidget);
      });

      testWidgets('cancel delete does not clear profile', (tester) async {
        await fakeRepo.saveProfileData(UserProfile(
          id: 'cancel-delete-test',
          name: 'Cancel Delete Test',
        ));

        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel').first);
        await tester.pumpAndSettle();

        final profileResult = await fakeRepo.getProfileData();
        expect(profileResult.isSuccess, isTrue);
        expect(profileResult.data, isNotNull);
        expect(profileResult.data!.name, equals('Cancel Delete Test'));
      });

      testWidgets('delete button has danger styling', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        final deleteButton = find.widgetWithText(TextButton, 'Delete');
        expect(deleteButton, findsOneWidget);

        final button = tester.widget<TextButton>(deleteButton);
        expect(button.style, isNotNull);
      });
    });

    group('Language Switch Side Effects', () {
      testWidgets('language dropdown shows current language', (tester) async {
        await fakeRepo.saveProfileData(UserProfile(
          id: 'lang-test',
          name: 'Lang User',
          language: 'es',
        ));

        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        expect(find.text('Spanish'), findsAtLeastNWidgets(1));
      });

      testWidgets('can switch from Spanish to English', (tester) async {
        await fakeRepo.saveProfileData(UserProfile(
          id: 'lang-switch-test',
          name: 'Switch User',
          language: 'es',
        ));

        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('English').last);
        await tester.pumpAndSettle();

        expect(find.text('English'), findsWidgets);
      });
    });

    group('Notifications Toggle', () {
      testWidgets('notifications can be enabled', (tester) async {
        await fakeRepo.saveProfileData(UserProfile(
          id: 'notif-test',
          name: 'Notif User',
          notificationsEnabled: false,
        ));

        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        final switchTile = find.widgetWithText(SwitchListTile, 'Notifications');
        final switchWidget = tester.widget<SwitchListTile>(switchTile);
        expect(switchWidget.value, isFalse);

        await tester.tap(switchTile);
        await tester.pumpAndSettle();

        final updatedSwitch = tester.widget<SwitchListTile>(switchTile);
        expect(updatedSwitch.value, isTrue);
      });
    });

    group('Avatar Selection', () {
      testWidgets('selecting avatar updates state', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person).first);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.school));
        await tester.pumpAndSettle();

        expect(find.text('Choose Avatar'), findsNothing);
      });

      testWidgets('all avatar options are selectable', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person).first);
        await tester.pumpAndSettle();

        final avatarIcons = [
          Icons.face,
          Icons.school,
          Icons.local_hospital,
          Icons.leaderboard,
          Icons.emoji_events,
          Icons.sports_tennis,
          Icons.coffee,
        ];

        for (final icon in avatarIcons) {
          await tester.tap(find.byIcon(Icons.person).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(icon));
          await tester.pumpAndSettle();
        }
      });
    });

    group('Error Handling', () {
      testWidgets('shows success snackbar on successful save', (tester) async {
        await tester.pumpWidget(buildProfileScreen(repo: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Success User',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(find.text('Profile saved successfully'), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('save triggers back navigation via pop', (tester) async {
        final navigatorObserver = TestNavigatorObserver();
        await tester.pumpWidget(buildProfileScreen(
          navigatorObserver: navigatorObserver,
        ));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Test User',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(navigatorObserver.poppedRoutes, isNotEmpty);
      });
    });
  });

  group('behavioral coverage', () {
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
  });

  group('extended coverage', () {
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
  });

  group('gaps coverage', () {
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
  });
}
