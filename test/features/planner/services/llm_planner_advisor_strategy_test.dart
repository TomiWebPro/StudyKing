import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/planner/services/llm_planner_advisor_strategy.dart';
import 'package:studyking/features/planner/services/planner_advisor_strategy.dart';

class _FakeLlmService extends LlmService {
  String? _response;
  bool _shouldThrow = false;
  String? capturedMessage;

  _FakeLlmService() : super(config: const LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test-key'));

  void setResponse(String response) => _response = response;
  void setThrowOnCall() => _shouldThrow = true;

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    capturedMessage = message;
    if (_shouldThrow) throw Exception('llm error');
    if (_response != null) return Result.success(_response!);
    return Result.success('{}');
  }
}

void main() {
  late _FakeLlmService fakeLlm;
  late LlmPlannerAdvisorStrategy strategy;

  setUp(() {
    fakeLlm = _FakeLlmService();
    strategy = LlmPlannerAdvisorStrategy(
      llmService: fakeLlm,
      modelId: 'test-model',
    );
  });

  group('LlmPlannerAdvisorStrategy', () {
    group('analyzeForPlanGeneration', () {
      test('returns AdvisorAnalysis when LLM responds with valid JSON', () async {
        fakeLlm.setResponse('''
{
  "workloadEstimate": "Moderate — 45-60 min/day",
  "pathwaySuggestion": "Start with foundational topics",
  "motivationalReasoning": "You can do this!",
  "adaptationReasoning": "Plan is on track"
}
''');

        final result = await strategy.analyzeForPlanGeneration(
          studentId: 'student-1',
          courseName: 'IB Physics',
          planDurationDays: 180,
          targetMinutesPerDay: 60,
        );

        expect(result.isSuccess, true);
        final analysis = result.data!;
        expect(analysis.workloadEstimate, 'Moderate — 45-60 min/day');
        expect(analysis.pathwaySuggestion, 'Start with foundational topics');
        expect(analysis.motivationalReasoning, 'You can do this!');
        expect(analysis.adaptationReasoning, 'Plan is on track');
      });

      test('handles JSON with extra whitespace and formatting', () async {
        fakeLlm.setResponse('''
  Some text before

{
  "workloadEstimate": "Light — 30 min/day",
  "pathwaySuggestion": "Review weak areas first",
  "motivationalReasoning": "Keep going!",
  "adaptationReasoning": null
}
''');

        final result = await strategy.analyzeForPlanGeneration(
          studentId: 'student-1',
          courseName: 'Math',
          planDurationDays: 90,
          targetMinutesPerDay: 30,
          weakTopicIds: ['topic-1', 'topic-2'],
        );

        expect(result.isSuccess, true);
        expect(result.data!.workloadEstimate, 'Light — 30 min/day');
        expect(result.data!.pathwaySuggestion, 'Review weak areas first');
      });

      test('handles empty JSON gracefully', () async {
        fakeLlm.setResponse('{}');

        final result = await strategy.analyzeForPlanGeneration(
          studentId: 'student-1',
          courseName: 'Physics',
          planDurationDays: 30,
          targetMinutesPerDay: 45,
        );

        expect(result.isSuccess, true);
        expect(result.data!.workloadEstimate, isNull);
        expect(result.data!.pathwaySuggestion, isNull);
      });

      test('handles LLM failure gracefully', () async {
        fakeLlm.setResponse('Some random text without JSON');

        final result = await strategy.analyzeForPlanGeneration(
          studentId: 'student-1',
          courseName: 'Physics',
          planDurationDays: 30,
          targetMinutesPerDay: 45,
        );

        expect(result.isSuccess, true);
        expect(result.data!.workloadEstimate, isNull);
        expect(result.data!.pathwaySuggestion, isNull);
        expect(result.data!.metadata, containsPair('raw_response', 'Some random text without JSON'));
      });

      test('handles throw from LLM service', () async {
        fakeLlm.setThrowOnCall();

        final result = await strategy.analyzeForPlanGeneration(
          studentId: 'student-1',
          courseName: 'Physics',
          planDurationDays: 30,
          targetMinutesPerDay: 45,
        );

        expect(result.isFailure, true);
      });

      test('includes weak and at-risk topic info in prompt for plan generation', () async {
        fakeLlm.setResponse('{}');

        await strategy.analyzeForPlanGeneration(
          studentId: 'student-1',
          courseName: 'Chemistry',
          planDurationDays: 60,
          targetMinutesPerDay: 90,
          weakTopicIds: ['weak-1', 'weak-2'],
          atRiskTopicIds: ['risk-1'],
          currentAdherence: 0.6,
          consecutiveLowAdherenceDays: 2,
        );

        expect(fakeLlm.capturedMessage, contains('Chemistry'));
        expect(fakeLlm.capturedMessage, contains('60'));
        expect(fakeLlm.capturedMessage, contains('90'));
      });

      test('returns AdvisorAnalysis with isA type checks', () async {
        fakeLlm.setResponse('{}');

        final result = await strategy.analyzeForPlanGeneration(
          studentId: 'student-1',
          courseName: 'Physics',
          planDurationDays: 30,
          targetMinutesPerDay: 45,
        );

        expect(result, isA<Result<AdvisorAnalysis>>());
        if (result.isSuccess) {
          expect(result.data, isA<AdvisorAnalysis>());
        }
      });
    });

    group('analyzeForAdaptation', () {
      test('returns adaptation advice when LLM responds with valid JSON', () async {
        fakeLlm.setResponse('''
{
  "workloadEstimate": "Reduce to 30 min/day",
  "pathwaySuggestion": "Focus on high-priority topics only",
  "motivationalReasoning": "It's okay to adjust your pace",
  "adaptationReasoning": "Student appears overwhelmed"
}
''');

        final result = await strategy.analyzeForAdaptation(
          studentId: 'student-1',
          currentAdherence: 0.3,
          consecutiveLowDays: 5,
          planSummary: '60-day plan for IB Physics',
        );

        expect(result.isSuccess, true);
        expect(result.data!.workloadEstimate, 'Reduce to 30 min/day');
        expect(result.data!.adaptationReasoning, 'Student appears overwhelmed');
      });

      test('handles empty response gracefully', () async {
        fakeLlm.setResponse('{}');

        final result = await strategy.analyzeForAdaptation(
          studentId: 'student-1',
          currentAdherence: 0.5,
          consecutiveLowDays: 3,
          planSummary: 'Test plan',
        );

        expect(result.isSuccess, true);
      });

      test('handles LLM failure for adaptation', () async {
        fakeLlm.setThrowOnCall();

        final result = await strategy.analyzeForAdaptation(
          studentId: 'student-1',
          currentAdherence: 0.2,
          consecutiveLowDays: 10,
          planSummary: 'Failing plan',
        );

        expect(result.isFailure, true);
      });
    });
  });
}
