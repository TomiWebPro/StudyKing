import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

class FakeSettingsRepositoryProfile {
  ProfileData? _profile;
  bool shouldThrow = false;

  Future<ProfileData?> getProfileData() async {
    if (shouldThrow) throw Exception('Test error');
    return _profile;
  }

  Future<void> saveProfileData(ProfileData profile) async {
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
  ProfileData? initialProfile,
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
      fakeProfileRepo._profile = ProfileData(
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
  });
}