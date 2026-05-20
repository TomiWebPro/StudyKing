import 'dart:convert';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/services/planner_advisor_strategy.dart';

class LlmPlannerAdvisorStrategy implements PlannerAdvisorStrategy {
  static final Logger _logger = const Logger('LlmPlannerAdvisorStrategy');

  final LlmService _llmService;
  final String _modelId;
  final String _localeName;

  LlmPlannerAdvisorStrategy({
    required LlmService llmService,
    required String modelId,
    String localeName = 'en',
  })  : _llmService = llmService,
        _modelId = modelId,
        _localeName = localeName;

  @override
  Future<Result<AdvisorAnalysis>> analyzeForPlanGeneration({
    required String studentId,
    required String courseName,
    required int planDurationDays,
    required double targetMinutesPerDay,
    List<String> weakTopicIds = const [],
    List<String> atRiskTopicIds = const [],
    double currentAdherence = 0.0,
    int consecutiveLowAdherenceDays = 0,
  }) async {
    final prompt = _buildPlanGenerationPrompt(
      studentId: studentId,
      courseName: courseName,
      planDurationDays: planDurationDays,
      targetMinutesPerDay: targetMinutesPerDay,
      weakTopicIds: weakTopicIds,
      atRiskTopicIds: atRiskTopicIds,
      currentAdherence: currentAdherence,
      consecutiveLowAdherenceDays: consecutiveLowAdherenceDays,
    );

    return _callAndParse(prompt, 'plan_generation');
  }

  @override
  Future<Result<AdvisorAnalysis>> analyzeForAdaptation({
    required String studentId,
    required double currentAdherence,
    required int consecutiveLowDays,
    required String planSummary,
  }) async {
    final prompt = _buildAdaptationPrompt(
      studentId: studentId,
      currentAdherence: currentAdherence,
      consecutiveLowDays: consecutiveLowDays,
      planSummary: planSummary,
    );

    return _callAndParse(prompt, 'plan_adaptation');
  }

  String _buildPlanGenerationPrompt({
    required String studentId,
    required String courseName,
    required int planDurationDays,
    required double targetMinutesPerDay,
    required List<String> weakTopicIds,
    required List<String> atRiskTopicIds,
    required double currentAdherence,
    required int consecutiveLowAdherenceDays,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert academic planner advisor. '
        'Analyze the student\'s study situation and provide structured advice for creating a study plan.');
    buffer.writeln();
    buffer.writeln('## Student Context');
    buffer.writeln('- Course: $courseName');
    buffer.writeln('- Plan duration: $planDurationDays days');
    buffer.writeln('- Target daily study time: ${targetMinutesPerDay.toStringAsFixed(0)} minutes');
    buffer.writeln('- Current plan adherence: ${(currentAdherence * 100).toStringAsFixed(0)}%');
    if (consecutiveLowAdherenceDays > 0) {
      buffer.writeln('- Consecutive low-adherence days: $consecutiveLowAdherenceDays');
    }
    if (weakTopicIds.isNotEmpty) {
      buffer.writeln('- Weak topic count: ${weakTopicIds.length}');
    }
    if (atRiskTopicIds.isNotEmpty) {
      buffer.writeln('- At-risk topic count: ${atRiskTopicIds.length}');
    }
    buffer.writeln();
    buffer.writeln('## Instructions');
    buffer.writeln('Provide a JSON response with these fields:');
    buffer.writeln(
        '- "workloadEstimate": A brief estimate of daily workload (e.g., "Moderate — 45-60 min/day recommended"). Consider the student\'s historical adherence and course complexity.');
    buffer.writeln(
        '- "pathwaySuggestion": A suggested learning pathway or ordering strategy (e.g., "Start with foundational topics, then progress to advanced").');
    buffer.writeln(
        '- "motivationalReasoning": A short motivational message tailored to the student\'s situation.');
    buffer.writeln(
        '- "adaptationReasoning": If adherence is low, suggest why (overwhelmed vs busy vs bored) and how to adjust.');
    buffer.writeln();
    buffer.writeln('Return ONLY valid JSON with no markdown formatting:');
    buffer.writeln('{');
    buffer.writeln('  "workloadEstimate": "...",');
    buffer.writeln('  "pathwaySuggestion": "...",');
    buffer.writeln('  "motivationalReasoning": "...",');
    buffer.writeln('  "adaptationReasoning": "..."');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _buildAdaptationPrompt({
    required String studentId,
    required double currentAdherence,
    required int consecutiveLowDays,
    required String planSummary,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert academic planner advisor. '
        'The student\'s existing study plan needs adaptation due to changing circumstances.');
    buffer.writeln();
    buffer.writeln('## Current Situation');
    buffer.writeln('- Plan adherence: ${(currentAdherence * 100).toStringAsFixed(0)}%');
    buffer.writeln('- Consecutive low-adherence days: $consecutiveLowDays');
    buffer.writeln();
    buffer.writeln('## Current Plan Summary');
    buffer.writeln(planSummary);
    buffer.writeln();
    buffer.writeln('## Instructions');
    buffer.writeln(
        'Analyze WHY the student is falling behind (overwhelmed, busy, bored, or other) and suggest specific adjustments.');
    buffer.writeln('Provide a JSON response with these fields:');
    buffer.writeln(
        '- "workloadEstimate": Revised workload estimate considering the adherence data.');
    buffer.writeln(
        '- "pathwaySuggestion": Suggested adjustments to the learning pathway or schedule.');
    buffer.writeln(
        '- "motivationalReasoning": Encouraging message to help the student get back on track.');
    buffer.writeln(
        '- "adaptationReasoning": Detailed reasoning for the suggested adaptations.');
    buffer.writeln();
    buffer.writeln('Return ONLY valid JSON with no markdown formatting:');
    buffer.writeln('{');
    buffer.writeln('  "workloadEstimate": "...",');
    buffer.writeln('  "pathwaySuggestion": "...",');
    buffer.writeln('  "motivationalReasoning": "...",');
    buffer.writeln('  "adaptationReasoning": "..."');
    buffer.writeln('}');
    return buffer.toString();
  }

  Future<Result<AdvisorAnalysis>> _callAndParse(
    String prompt,
    String feature,
  ) async {
    try {
      final result = await _llmService.chat(
        message: prompt,
        modelId: _modelId,
        feature: 'planner_advisor_$feature',
        localeName: _localeName,
      );

      if (result.isFailure) {
        return Result.failure(result.error!);
      }

      final response = result.data!;
      final parsed = _parseResponse(response);
      return Result.success(parsed);
    } catch (e) {
      _logger.w('LLM planner advisor call failed', e);
      return Result.failure('LlmPlannerAdvisorStrategy: $e');
    }
  }

  AdvisorAnalysis _parseResponse(String response) {
    try {
      Map<String, dynamic> json;
      final jsonMatch = RegExp(r'\{[^{}]*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      } else {
        json = jsonDecode(response.trim()) as Map<String, dynamic>;
      }

      return AdvisorAnalysis(
        workloadEstimate: json['workloadEstimate'] as String?,
        pathwaySuggestion: json['pathwaySuggestion'] as String?,
        motivationalReasoning: json['motivationalReasoning'] as String?,
        adaptationReasoning: json['adaptationReasoning'] as String?,
        metadata: {
          'raw_response': response,
          'parse_method': jsonMatch != null ? 'regex_extract' : 'full_parse',
        },
      );
    } catch (e) {
      _logger.w('Failed to parse advisor response', e);
      return AdvisorAnalysis(
        workloadEstimate: null,
        pathwaySuggestion: null,
        motivationalReasoning: null,
        adaptationReasoning: null,
        metadata: {
          'raw_response': response,
          'parse_error': e.toString(),
        },
      );
    }
  }
}
