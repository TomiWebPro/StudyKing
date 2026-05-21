import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/utils/logger.dart';

const _layoutBoxName = HiveBoxNames.dashboardLayoutPrefs;

class DashboardLayoutPreferences {
  final Set<String> collapsedCards;

  const DashboardLayoutPreferences({
    this.collapsedCards = const {},
  });

  DashboardLayoutPreferences copyWith({
    Set<String>? collapsedCards,
  }) {
    return DashboardLayoutPreferences(
      collapsedCards: collapsedCards ?? this.collapsedCards,
    );
  }

  bool isCollapsed(String cardId) => collapsedCards.contains(cardId);
}

class DashboardLayoutNotifier extends StateNotifier<DashboardLayoutPreferences> {
  static final _logger = const Logger('DashboardLayoutNotifier');
  Box? _box;

  DashboardLayoutNotifier() : super(const DashboardLayoutPreferences());

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_layoutBoxName);
      final saved = _box?.get('collapsedCards') as List<String>?;
      if (saved != null) {
        state = DashboardLayoutPreferences(collapsedCards: saved.toSet());
      }
    } catch (e) {
      _logger.w('Failed to open Hive box, using defaults', e);
      state = const DashboardLayoutPreferences();
    }
  }

  void toggleCollapsed(String cardId) {
    final updated = Set<String>.from(state.collapsedCards);
    if (updated.contains(cardId)) {
      updated.remove(cardId);
    } else {
      updated.add(cardId);
    }
    state = state.copyWith(collapsedCards: updated);
    _box?.put('collapsedCards', updated.toList());
  }
}

final dashboardLayoutPreferencesProvider =
    StateNotifierProvider<DashboardLayoutNotifier, DashboardLayoutPreferences>(
        (ref) {
  return DashboardLayoutNotifier();
});
