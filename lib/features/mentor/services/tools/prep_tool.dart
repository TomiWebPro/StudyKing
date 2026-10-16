import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/utils/logger.dart';

/// CPU and network intensity classification for prep tools.
///
/// Heavy tasks defer under CPU/battery pressure (Vision Next-Term §4.3);
/// light tasks (e.g. mastery refresh that only reads existing data) proceed
/// immediately.
enum PrepCpuClass { light, medium, heavy }

/// Base class for off-period preparation agent tools.
///
/// Mirrors the existing mentor tools pattern (`AgentTool`) but adds the
/// token estimates and CPU/network classification required by the
/// prep budget scheduler (Vision Next-Term §4.2/§4.3). Each tool also
/// carries a [PrepCategory] so spend can be attributed to the right
/// budget bucket via [PrepBudgetService].
abstract class PrepTool extends AgentTool {
  static final Logger _logger = const Logger('PrepTool');

  /// Estimated input tokens this prep task will consume.
  int get estimatedInputTokens;

  /// Estimated output tokens this prep task will produce.
  int get estimatedOutputTokens;

  /// Total estimated tokens (input + output).
  int get estimatedTotalTokens => estimatedInputTokens + estimatedOutputTokens;

  /// CPU and network intensity class for the prep scheduler.
  PrepCpuClass get cpuClass;

  /// Whether this prep tool requires network access.
  bool get needsNetwork => cpuClass != PrepCpuClass.light;

  /// The [PrepCategory] this tool belongs to, for budget tracking.
  PrepCategory get prepCategory;
}
