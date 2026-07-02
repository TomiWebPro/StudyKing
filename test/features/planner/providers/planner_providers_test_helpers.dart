import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

ProviderContainer createProviderContainer({
  PlannerService? service,
  List<Override> extraOverrides = const [],
}) {
  final overrides = <Override>[
    if (service != null)
      plannerServiceProvider.overrideWithValue(service),
    ...extraOverrides,
  ];
  final container = ProviderContainer(overrides: overrides);
  return container;
}
