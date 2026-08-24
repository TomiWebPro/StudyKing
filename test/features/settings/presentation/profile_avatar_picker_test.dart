import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show localeProvider, settingsRepositoryProvider;
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _AvatarFakeSettingsRepository extends SettingsRepository {
  UserProfile? _currentProfile;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<UserProfile?>> getProfileData() async {
    if (_currentProfile != null) return Result.success(_currentProfile);
    return Result.success(UserProfile(id: 'default_profile', name: ''));
  }

  @override
  Future<Result<void>> saveProfileData(UserProfile profile) async {
    _currentProfile = profile;
    return Result.success(null);
  }

  @override
  Future<Result<void>> clearProfile() async {
    _currentProfile = null;
    return Result.success(null);
  }
}

const List<String> _avatarIconKeys = [
  'Icons.face',
  'Icons.person',
  'Icons.school',
  'Icons.local_hospital',
  'Icons.leaderboard',
  'Icons.emoji_events',
  'Icons.sports_tennis',
  'Icons.coffee',
];

Widget buildAvatarProfileScreen({required SettingsRepository repo}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => const Locale('en')),
      settingsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const ProfileScreen(),
    ),
  );
}

Future<void> pumpAvatarProfileScreen(WidgetTester tester, {required SettingsRepository repo}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 2000);
  await tester.pumpWidget(buildAvatarProfileScreen(repo: repo));
  await tester.pumpAndSettle();
}

void main() {
  group('ProfileScreen avatar picker redesign', () {
    late _AvatarFakeSettingsRepository fakeRepo;

    setUp(() {
      fakeRepo = _AvatarFakeSettingsRepository();
    });

    testWidgets('opens avatar bottom sheet with a centered, even grid of icons', (tester) async {
      await pumpAvatarProfileScreen(tester, repo: fakeRepo);

      await tester.tap(find.byKey(const Key('avatarPickerTrigger')));
      await tester.pumpAndSettle();

      // Sheet is open.
      expect(find.text('Choose Avatar'), findsOneWidget);

      // All eight avatar options are present and tappable (unique semantics).
      for (final key in _avatarIconKeys) {
        expect(find.bySemanticsLabel('Select avatar $key'), findsOneWidget);
      }

      // Redesigned layout: a centered grid of tappable tiles, no ChoiceChip.
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('tapping an icon updates the selected avatar (avatarIcon)', (tester) async {
      await pumpAvatarProfileScreen(tester, repo: fakeRepo);

      await tester.tap(find.byKey(const Key('avatarPickerTrigger')));
      await tester.pumpAndSettle();

      final schoolTile = find.bySemanticsLabel('Select avatar Icons.school');
      expect(schoolTile, findsOneWidget);

      await tester.tap(schoolTile);
      await tester.pumpAndSettle();

      // Sheet closes after selection.
      expect(find.text('Choose Avatar'), findsNothing);

      // Re-open and confirm the chosen icon is the selected one.
      await tester.tap(find.byKey(const Key('avatarPickerTrigger')));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.bySemanticsLabel('Select avatar Icons.school'));
      expect(semantics.getSemanticsData().flagsCollection.isSelected, equals(Tristate.isTrue));

      // A non-selected tile must not report selected.
      final faceSemantics = tester.getSemantics(find.bySemanticsLabel('Select avatar Icons.face'));
      expect(faceSemantics.getSemanticsData().flagsCollection.isSelected, equals(Tristate.isFalse));
    });

    testWidgets('selected icon is reflected on the profile body avatar', (tester) async {
      await pumpAvatarProfileScreen(tester, repo: fakeRepo);

      await tester.tap(find.byKey(const Key('avatarPickerTrigger')));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Select avatar Icons.coffee'));
      await tester.pumpAndSettle();

      // Sheet closed after selection.
      expect(find.text('Choose Avatar'), findsNothing);

      // Re-open to confirm persistence via the selected outline semantics.
      await tester.tap(find.byKey(const Key('avatarPickerTrigger')));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Select avatar Icons.coffee')).getSemanticsData().flagsCollection.isSelected,
        equals(Tristate.isTrue),
      );
    });

    testWidgets('selected state moves when a different icon is chosen', (tester) async {
      await pumpAvatarProfileScreen(tester, repo: fakeRepo);

      await tester.tap(find.byKey(const Key('avatarPickerTrigger')));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Select avatar Icons.leaderboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatarPickerTrigger')));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Select avatar Icons.leaderboard')).getSemanticsData().flagsCollection.isSelected,
        equals(Tristate.isTrue),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Select avatar Icons.person')).getSemanticsData().flagsCollection.isSelected,
        equals(Tristate.isFalse),
      );
    });
  });
}
