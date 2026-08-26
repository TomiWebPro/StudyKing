import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// A tab/segmented switcher that lets the student scope the dashboard to a
/// single syllabus (subject) or view all syllabi aggregated. The selection is
/// stored in [dashboardSelectedSyllabusProvider] and consumed by the dashboard
/// widgets to filter their data.
class SyllabusSwitcher extends ConsumerWidget {
  final List<SyllabusBreakdown> breakdowns;

  const SyllabusSwitcher({super.key, required this.breakdowns});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(dashboardSelectedSyllabusProvider);

    final chips = <Widget>[
      _buildChip(
        context: context,
        label: l10n.syllabusAll,
        isSelected: selected == null,
        onTap: () =>
            ref.read(dashboardSelectedSyllabusProvider.notifier).state = null,
      ),
      for (final b in breakdowns)
        _buildChip(
          context: context,
          label: b.subjectTitle,
          isSelected: selected == b.subjectId,
          onTap: () => ref
              .read(dashboardSelectedSyllabusProvider.notifier)
              .state = b.subjectId,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: c,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
