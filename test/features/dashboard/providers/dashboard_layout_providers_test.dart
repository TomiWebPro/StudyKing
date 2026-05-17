import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/dashboard/providers/dashboard_layout_providers.dart';

void main() {
  group('DashboardLayoutPreferences', () {
    group('constructor', () {
      test('creates instance with empty collapsedCards by default', () {
        final prefs = DashboardLayoutPreferences();
        expect(prefs.collapsedCards, isEmpty);
      });

      test('creates instance with provided collapsed set', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1', 'card-2'},
        );
        expect(prefs.collapsedCards, {'card-1', 'card-2'});
      });
    });

    group('isCollapsed', () {
      test('returns false for any card when set is empty', () {
        final prefs = DashboardLayoutPreferences();
        expect(prefs.isCollapsed('any-card'), isFalse);
      });

      test('returns true for card in collapsed set', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        expect(prefs.isCollapsed('card-1'), isTrue);
        expect(prefs.isCollapsed('card-2'), isFalse);
      });
    });

    group('copyWith', () {
      test('returns same values when no arguments provided', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        final copy = prefs.copyWith();
        expect(copy.collapsedCards, {'card-1'});
      });

      test('replaces collapsedCards when provided', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        final copy = prefs.copyWith(collapsedCards: {'card-2'});
        expect(copy.collapsedCards, {'card-2'});
      });

      test('does not mutate original instance', () {
        final prefs = DashboardLayoutPreferences(
          collapsedCards: {'card-1'},
        );
        prefs.copyWith(collapsedCards: {'card-2'});
        expect(prefs.collapsedCards, {'card-1'});
      });
    });
  });

  group('DashboardLayoutNotifier', () {
    test('default state has empty collapsedCards', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(dashboardLayoutPreferencesProvider).collapsedCards,
        isEmpty,
      );
    });

    group('toggleCollapsed', () {
      test('adds card to collapsed set', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(dashboardLayoutPreferencesProvider.notifier)
            .toggleCollapsed('card-1');
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .isCollapsed('card-1'),
          isTrue,
        );
      });

      test('removes card from collapsed set on second toggle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container
            .read(dashboardLayoutPreferencesProvider.notifier);
        notifier.toggleCollapsed('card-1');
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .isCollapsed('card-1'),
          isTrue,
        );
        notifier.toggleCollapsed('card-1');
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .isCollapsed('card-1'),
          isFalse,
        );
      });

      test('multiple cards toggle independently', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container
            .read(dashboardLayoutPreferencesProvider.notifier);
        notifier.toggleCollapsed('card-a');
        notifier.toggleCollapsed('card-b');
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .isCollapsed('card-a'),
          isTrue,
        );
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .isCollapsed('card-b'),
          isTrue,
        );
        notifier.toggleCollapsed('card-a');
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .isCollapsed('card-a'),
          isFalse,
        );
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .isCollapsed('card-b'),
          isTrue,
        );
      });

      test('emits new state after toggle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container
            .read(dashboardLayoutPreferencesProvider.notifier);
        final states = <DashboardLayoutPreferences>[];
        notifier.addListener(
          (state) => states.add(state),
          fireImmediately: false,
        );
        notifier.toggleCollapsed('card');
        expect(states.length, 1);
        expect(states[0].isCollapsed('card'), isTrue);
      });

      test('returns to empty set after toggle and untoggle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container
            .read(dashboardLayoutPreferencesProvider.notifier);
        notifier.toggleCollapsed('card');
        notifier.toggleCollapsed('card');
        expect(
          container.read(dashboardLayoutPreferencesProvider)
              .collapsedCards,
          isEmpty,
        );
      });
    });


  });

  group('dashboardLayoutPreferencesProvider', () {
    test('resolves DashboardLayoutNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(dashboardLayoutPreferencesProvider.notifier);
      expect(notifier, isA<DashboardLayoutNotifier>());
    });

    test('returns DashboardLayoutPreferences', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = container.read(dashboardLayoutPreferencesProvider);
      expect(prefs, isA<DashboardLayoutPreferences>());
      expect(prefs.collapsedCards, isEmpty);
    });

    test('can toggle through provider notifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(dashboardLayoutPreferencesProvider.notifier)
          .toggleCollapsed('card-1');
      expect(
        container.read(dashboardLayoutPreferencesProvider)
            .isCollapsed('card-1'),
        isTrue,
      );
    });

    test('toggle and untoggle through provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(dashboardLayoutPreferencesProvider.notifier);
      notifier.toggleCollapsed('card-1');
      expect(
        container.read(dashboardLayoutPreferencesProvider)
            .isCollapsed('card-1'),
        isTrue,
      );
      notifier.toggleCollapsed('card-1');
      expect(
        container.read(dashboardLayoutPreferencesProvider)
            .isCollapsed('card-1'),
        isFalse,
      );
    });
  });
}
