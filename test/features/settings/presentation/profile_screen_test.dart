import 'package:flutter/material.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

class FakeSettingsRepositoryProfile {
  UserProfile? _profile;
  bool shouldThrow = false;

  Future<UserProfile?> getProfileData() async {
    if (shouldThrow) throw Exception('Test error');
    return _profile;
  }

  Future<void> saveProfileData(UserProfile profile) async {
    _profile = profile;
  }

  Future<void> clearProfile() async {
    _profile = null;
  }

  Future<void> init() async {}
}

final fakeProfileRepo = FakeSettingsRepositoryProfile();

class _TestSettingsNotifier extends StateNotifier<SettingsBox> {
  _TestSettingsNotifier() : super(SettingsBox());

  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
  }) async {
    state = SettingsBox(
      apiKey: apiKey ?? state.apiKey,
      apiBaseUrl: apiBaseUrl ?? state.apiBaseUrl,
      selectedModel: selectedModel ?? state.selectedModel,
      themeMode: themeMode?.index ?? state.themeMode,
      fontSize: fontSize ?? state.fontSize,
      totalSessionCount: state.totalSessionCount,
      totalStudyTimeMs: state.totalStudyTimeMs,
      totalQuestions: state.totalQuestions,
      studyRemindersEnabled: studyRemindersEnabled ?? state.studyRemindersEnabled,
      requestTimeoutSeconds: requestTimeoutSeconds ?? state.requestTimeoutSeconds,
      sessionDurationMinutes: sessionDurationMinutes ?? state.sessionDurationMinutes,
    );
  }
}

final testSettingsProvider = StateNotifierProvider<_TestSettingsNotifier, SettingsBox>((ref) {
  return _TestSettingsNotifier();
});

Widget buildProfileScreen({
  UserProfile? initialProfile,
  bool shouldThrowLoad = false,
}) {
  fakeProfileRepo._profile = initialProfile;
  fakeProfileRepo.shouldThrow = shouldThrowLoad;
  return ProviderScope(
    overrides: [
      testSettingsProvider,
    ],
    child: MaterialApp(
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  setUp(() {
    fakeProfileRepo._profile = null;
    fakeProfileRepo.shouldThrow = false;
  });

  group('ProfileScreen', () {
    testWidgets('renders profile screen with app bar', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows save button in app bar', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows avatar selection area', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      final avatarContainer = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration != null &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle);
      expect(avatarContainer, findsWidgets);
    });

    testWidgets('shows name text field with correct label', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('shows student ID field as optional', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Student ID (Optional)'), findsOneWidget);
    });

    testWidgets('shows learning goal text field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Learning Goal'), findsOneWidget);
      expect(find.text('e.g., Final Exams, Certifications'), findsOneWidget);
    });

    testWidgets('shows preferred study time text field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Preferred Study Time'), findsOneWidget);
      expect(find.text('e.g., Evening (6-9 PM)'), findsOneWidget);
    });

    testWidgets('shows account information card', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows language dropdown with English and Spanish', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
    });

    testWidgets('shows notifications switch', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      final switchTile = find.widgetWithText(SwitchListTile, 'Notifications');
      expect(switchTile, findsOneWidget);
    });

    testWidgets('shows delete account warning card', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.textContaining('will permanently remove'), findsOneWidget);
    });

    testWidgets('tapping avatar opens avatar picker bottom sheet', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
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
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsNothing);
    });

    testWidgets('can select face avatar', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.face));
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsNothing);
    });

    testWidgets('can select school avatar', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.school));
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsNothing);
    });

    testWidgets('shows error snackbar when name is empty on save', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows error snackbar when student ID is non-numeric', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
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
      await tester.pumpWidget(buildProfileScreen());
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
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spanish').last);
      await tester.pumpAndSettle();

      expect(find.text('Spanish'), findsWidgets);
    });

    testWidgets('can toggle notifications switch', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
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
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsWidgets);
      expect(find.textContaining('Are you sure'), findsOneWidget);
      expect(find.text('Cancel'), findsAtLeastNWidgets(1));
    });

    testWidgets('cancel delete closes dialog without action', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Are you sure'), findsNothing);
    });

    testWidgets('loads existing profile data into fields', (tester) async {
      fakeProfileRepo._profile = UserProfile(
        id: 'test-id',
        name: 'Jane Doe',
        studentId: '12345',
        avatarIcon: 'Icons.school',
        learningGoal: 'Learn Flutter',
        preferredStudyTime: 'Morning',
        notificationsEnabled: false,
        language: 'es',
      );

      await tester.pumpWidget(buildProfileScreen(initialProfile: fakeProfileRepo._profile));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('12345'), findsOneWidget);
      expect(find.text('Learn Flutter'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('handles profile load error gracefully', (tester) async {
      fakeProfileRepo.shouldThrow = true;

      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(find.byIcon(Icons.person), findsWidgets);
    });

    testWidgets('shows required asterisk for name field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      final nameLabel = find.text('Full Name');
      expect(nameLabel, findsOneWidget);

      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('student ID field only accepts digits', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      final studentIdField = find.widgetWithText(TextField, 'Student ID (Optional)');
      final textField = tester.widget<TextField>(studentIdField);

      expect(textField.inputFormatters, isNotNull);
      expect(textField.inputFormatters!.isNotEmpty, isTrue);
    });

    testWidgets('avatar picker has proper semantic labels', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      final semantics = find.bySemanticsLabel(RegExp('Select avatar'));
      expect(semantics, findsWidgets);
    });

    testWidgets('enter text in name field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Full Name'),
        'Test User',
      );
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('enter text in learning goal field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Learning Goal'),
        'Master programming',
      );
      await tester.pumpAndSettle();

      expect(find.text('Master programming'), findsOneWidget);
    });

    testWidgets('enter text in preferred study time field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
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
        fakeProfileRepo._profile = null;

        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Save Test User',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(fakeProfileRepo._profile, isNotNull);
        expect(fakeProfileRepo._profile!.name, equals('Save Test User'));
      });

      testWidgets('save includes student ID when provided', (tester) async {
        fakeProfileRepo._profile = null;

        await tester.pumpWidget(buildProfileScreen());
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

        expect(fakeProfileRepo._profile!.studentId, equals('12345'));
      });

      testWidgets('save includes learning goal when provided', (tester) async {
        fakeProfileRepo._profile = null;

        await tester.pumpWidget(buildProfileScreen());
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

        expect(fakeProfileRepo._profile!.learningGoal, equals('Pass Final Exam'));
      });

      testWidgets('save includes preferred study time when provided', (tester) async {
        fakeProfileRepo._profile = null;

        await tester.pumpWidget(buildProfileScreen());
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

        expect(fakeProfileRepo._profile!.preferredStudyTime, equals('Evening 7-10 PM'));
      });

      testWidgets('save shows loading indicator during save', (tester) async {
        await tester.pumpWidget(buildProfileScreen());
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
        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(find.text('Name is required'), findsOneWidget);
        expect(fakeProfileRepo._profile, isNull);
      });

      testWidgets('whitespace-only name shows error', (tester) async {
        await tester.pumpWidget(buildProfileScreen());
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
        fakeProfileRepo._profile = null;

        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          '  Trimmed User  ',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(fakeProfileRepo._profile!.name, equals('Trimmed User'));
      });

      testWidgets('student ID accepts numeric values only', (tester) async {
        fakeProfileRepo._profile = null;

        await tester.pumpWidget(buildProfileScreen());
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

        expect(fakeProfileRepo._profile!.studentId, equals('9876543210'));
      });

      testWidgets('empty student ID is stored as null', (tester) async {
        fakeProfileRepo._profile = null;

        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'No ID User',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(fakeProfileRepo._profile!.studentId, isNull);
      });
    });

    group('Delete Account Flow', () {
      testWidgets('delete confirmation calls clearProfile', (tester) async {
        fakeProfileRepo._profile = UserProfile(
          id: 'delete-test',
          name: 'Delete Test',
        );

        await tester.pumpWidget(buildProfileScreen(initialProfile: fakeProfileRepo._profile));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Are you sure'), findsOneWidget);
        expect(find.text('Delete Account'), findsWidgets);

        await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
        await tester.pumpAndSettle();

        expect(fakeProfileRepo._profile, isNull);
      });

      testWidgets('delete confirmation shows warning message', (tester) async {
        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.textContaining('cannot be undone'), findsOneWidget);
        expect(find.textContaining('permanently delete'), findsOneWidget);
      });

      testWidgets('cancel delete does not clear profile', (tester) async {
        fakeProfileRepo._profile = UserProfile(
          id: 'cancel-delete-test',
          name: 'Cancel Delete Test',
        );

        await tester.pumpWidget(buildProfileScreen(initialProfile: fakeProfileRepo._profile));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel').first);
        await tester.pumpAndSettle();

        expect(fakeProfileRepo._profile, isNotNull);
        expect(fakeProfileRepo._profile!.name, equals('Cancel Delete Test'));
      });

      testWidgets('delete button has danger styling', (tester) async {
        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        final deleteButton = find.widgetWithText(TextButton, 'Delete');
        expect(deleteButton, findsOneWidget);

        final button = tester.widget<TextButton>(deleteButton);
        expect(button.style, isNotNull);
      });
    });

    group('Language Switch Side Effects', () {
      testWidgets('language dropdown shows current language', (tester) async {
        fakeProfileRepo._profile = UserProfile(
          id: 'lang-test',
          name: 'Lang User',
          language: 'es',
        );

        await tester.pumpWidget(buildProfileScreen(initialProfile: fakeProfileRepo._profile));
        await tester.pumpAndSettle();

        expect(find.text('Spanish'), findsAtLeastNWidgets(1));
      });

      testWidgets('can switch from Spanish to English', (tester) async {
        fakeProfileRepo._profile = UserProfile(
          id: 'lang-switch-test',
          name: 'Switch User',
          language: 'es',
        );

        await tester.pumpWidget(buildProfileScreen(initialProfile: fakeProfileRepo._profile));
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
        fakeProfileRepo._profile = UserProfile(
          id: 'notif-test',
          name: 'Notif User',
          notificationsEnabled: false,
        );

        await tester.pumpWidget(buildProfileScreen(initialProfile: fakeProfileRepo._profile));
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
        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person).first);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.school));
        await tester.pumpAndSettle();

        expect(find.text('Choose Avatar'), findsNothing);
      });

      testWidgets('all avatar options are selectable', (tester) async {
        await tester.pumpWidget(buildProfileScreen());
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
      testWidgets('shows generic error message on save failure', (tester) async {
        fakeProfileRepo.shouldThrow = true;

        await tester.pumpWidget(buildProfileScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Error User',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error'), findsWidgets);
      });
    });
  });
}