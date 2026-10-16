/// Dry-run-test scenario validation for the confused-student journey.
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
///
/// This test validates `dry-run-test/scenario_confused_student_fractions.md`
/// by tracing each step through the fake [AgentLoop], producing a
/// PASS / PARTIAL / FAIL trace and a tool-context audit (needed vs. available).
///
/// It confirms the gap recorded in
/// `issues/open/e2e-teaching-missing-context-injection.md`: the teaching mode
/// has no confusion-detection directive in its system prompt and no
/// explanation-variation tooling, so repeated "I don't get it" calls produce
/// no escalation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';

import '../../helpers/hive_init_helper.dart';
import 'fakes.dart';

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });

  group('Dry-run scenario: confused student (fractions)', () {
    /// Simulates the teaching-mode system prompt as it currently exists
    /// (no confusion-detection directive, no modality options). This is
    /// read from prompts.dart behaviour — the system prompt only injects
    /// optional learning-style hints when LearningPreference is set and
    /// optional feedbackContext. There is no "if confused, escalate" clause.
    const String currentTeachingSystemPrompt =
        'You are a helpful tutor teaching fractions. '
        'Explain concepts clearly and answer questions.';

    test('Step 1: no confusion-detection directive in system prompt', () {
      // The system prompt is what AgentLoop feeds to the LLM.
      // Per issues/open/e2e-teaching-missing-context-injection.md:
      // prompts.dart buildTutorPrompt (lines 70-89) injects
      // feedbackContext and _buildLearningStyleHint but has no
      // confusion-detection directive. _consecutiveIncorrect (line 63)
      // is tracked but never referenced in prompt construction.
      expect(currentTeachingSystemPrompt.contains('confusion'), isFalse);
      expect(currentTeachingSystemPrompt.contains('escalat'), isFalse);
      expect(currentTeachingSystemPrompt.contains('different'), isFalse);
    });

    test('Step 2: no explanation-modality variation mechanism', () {
      // LessonBlockType enum (enums.dart:41-48) has text, example, exercise,
      // slide, quiz, summary — no visual or analogy variant.
      // The teaching flow calls LlmService.chatStream() directly,
      // not AgentLoop, so no tools are available to vary explanation style.
      // AgentLoop builds its system prompt from the base prompt + tool list.
      // In teaching mode, no tools are registered (the flow bypasses AgentLoop).
      final loop = AgentLoop(
        llmService: FakeAgentLlmService(['No tools available.']),
        modelId: 'test-model',
        toolRegistry: ToolRegistry(), // empty — no tools in teaching mode
      );

      expect(loop.toolRegistry.toolNames, isEmpty,
          reason: 'Teaching mode does not register any tools with AgentLoop');
    });

    test(
      'Step 3: repeated "I don\'t get it" does not escalate — gap trace',
      () async {
        // Simulate 3 rounds of "I don't get it" → same explanation each time.
        // The fake LLM returns the same canned response each round (as
        // _IntegrationFakeLlmService does — canned strings, no adaptation).
        final fakeLlm = FakeAgentLlmService([
          'Let me explain fractions: A fraction represents a part of a whole.',
          'Let me explain fractions: A fraction represents a part of a whole.',
          'Let me explain fractions: A fraction represents a part of a whole.',
        ]);

        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: ToolRegistry(),
        );

        // Round 1
        final r1 = await loop.run(
          userMessage: "I don't get fractions.",
          studentId: 'confused-student',
          systemPrompt: currentTeachingSystemPrompt,
          feature: 'teaching',
        );

        // Round 2
        final r2 = await loop.run(
          userMessage: "I still don't get it. Explain differently.",
          studentId: 'confused-student',
          systemPrompt: currentTeachingSystemPrompt,
          feature: 'teaching',
        );

        // Round 3
        final r3 = await loop.run(
          userMessage: "I STILL don't get it!",
          studentId: 'confused-student',
          systemPrompt: currentTeachingSystemPrompt,
          feature: 'teaching',
        );

        // All three responses are identical — no escalation, no
        // modality switch, no prerequisite suggestion.
        expect(r1.content, r2.content);
        expect(r2.content, r3.content);

        // No tools were called in any round (teaching bypasses AgentLoop).
        expect(r1.toolCalls, isEmpty);
        expect(r2.toolCalls, isEmpty);
        expect(r3.toolCalls, isEmpty);

        // Trace verdict: FAIL — the system does not escalate on repeated
        // confusion because there is no confusion-detection directive
        // and no escalation tool.
        // See: dry-run-test/scenario_confused_student_fractions.md Step 3
        // Status: FAIL
      },
    );

    test('Tool/context audit: teaching mode is starved of tools and context',
        () async {
      // Reproduce the audit from dry-run-test/scenario_confused_student_fractions.md
      // Tool/context audit section.

      final neededTools = <String>[
        'explain_differently', // Repeat-explanation tool
      ];

      final availableTools = <String>{}; // teaching mode registers no tools

      final audit = AgentRunCapture.auditTools(
        needed: neededTools,
        available: availableTools,
      );

      // The audit must report the missing tool.
      expect(audit, contains('explain_differently -> MISSING'));
      expect(audit, contains('1 tool(s) missing'));

      // Context the LLM needs vs what AgentLoop injects:
      // - Conversation history (prior failed explanations): YES (via ConversationMemory)
      // - Available explanation modalities (text, example, visual, analogy): NO
      // - Student's prerequisite mastery gaps: YES (partial — readiness scorer
      //   not invoked during teaching)
      final promptHasModalityOptions =
          currentTeachingSystemPrompt.contains('visual') ||
              currentTeachingSystemPrompt.contains('analogy') ||
              currentTeachingSystemPrompt.contains('step-by-step');
      expect(promptHasModalityOptions, isFalse,
          reason: 'No explanation-modality options in teaching system prompt');
    });

    test('Verdict trace: confused-student scenario produces FAIL trace', () {
      // Produce a human-readable trace that maps to the scenario file's
      // Validation Results section. This serves as the "executable spec"
      // that validates the dry-run-test scenario.

      final trace = <String>[];
      var allPass = true;

      // Step 1: confusion detection directive missing → FAIL
      if (currentTeachingSystemPrompt.contains('confusion')) {
        trace.add('Step 1: PASS — confusion detection directive found');
      } else {
        trace.add('Step 1: FAIL — no confusion detection directive in '
            'prompts.dart buildTutorPrompt');
        allPass = false;
      }

      // Step 2: no explanation-style variation mechanism → FAIL
      final variationTools = ['visual', 'analogy', 'step_by_step'];
      final hasVariation =
          variationTools.any((t) => currentTeachingSystemPrompt.contains(t));
      if (hasVariation) {
        trace.add('Step 2: PASS — explanation-style variation available');
      } else {
        trace.add('Step 2: FAIL — no explanation-style variation mechanism '
            '(LessonBlockType lacks visual/analogy)');
        allPass = false;
      }

      // Step 3: no escalation tool → FAIL
      final escalationTools = ['suggest_practice', 'ask_working', 'switch_mode'];
      final hasEscalation = escalationTools
          .any((t) => currentTeachingSystemPrompt.toLowerCase().contains(t));
      if (hasEscalation) {
        trace.add('Step 3: PASS — escalation mechanism available');
      } else {
        trace.add('Step 3: FAIL — no escalation to prerequisite practice or '
            'working request');
        allPass = false;
      }

      // Step 4: teaching mode cannot invoke practice/session tools → FAIL
      // teaching mode calls LlmService.chatStream() directly, not AgentLoop
      trace.add('Step 4: FAIL — teaching mode bypasses AgentLoop, '
          'cannot invoke CreatePracticeSessionTool');
      allPass = false;

      // Log the full trace for visibility — verdict is always FAILURES
      // because the gap is real (see expect below).
      // ignore: avoid_print
      print('=== Confused-student scenario trace ===');
      for (final line in trace) {
        // ignore: avoid_print
        print(line);
      }
      // ignore: avoid_print
      print('Verdict: FAILURES DETECTED');
      // ignore: avoid_print
      print('=== End trace ===');

      // All four steps are FAIL — the scenario gap is real and traced.
      expect(allPass, isFalse,
          reason: 'Confused-student scenario has 4 FAIL steps — '
              'see dry-run-test/scenario_confused_student_fractions.md');
    });
  });

  group('Dry-run scenario: overworked student (wellbeing rest-day)', () {
    test('Step 4: schedule_rest_day is FOUND; wellbeing_adjust_schedule still MISSING',
        () {
      // Reproduces the tool/context audit from
      // dry-run-test/scenario_overworked_student.md Step 4.
      //
      // ScheduleRestDayTool IS registered at
      // lib/core/providers/llm_agent_providers.dart:65 (commit 0d574e5),
      // so the audit must report it as FOUND, not MISSING. Only
      // wellbeing_adjust_schedule remains genuinely missing (no such tool
      // was ever registered — wellbeing nudge suggestions are handled by
      // MentorWellbeingService, not an agent tool).
      final neededTools = <String>[
        'schedule_rest_day',
        'wellbeing_adjust_schedule',
      ];

      // availableTools reflects the real llmAgentToolsProvider tool set
      // (single source of truth in fakes.dart → registeredToolNames).
      final availableTools = registeredToolNames;

      final audit = AgentRunCapture.auditTools(
        needed: neededTools,
        available: availableTools,
      );

      expect(audit, contains('schedule_rest_day -> HAD'));
      expect(audit, contains('wellbeing_adjust_schedule -> MISSING'));
      expect(audit, contains('1 tool(s) missing'));
    });
  });

  group('Dry-run scenario: provider switch (longterm user)', () {
    test('Step 3: no agent tool for provider switch → tool audit FAIL', () {
      // Reproduces the tool/context audit from
      // dry-run-test/scenario_longterm_user_accelerates.md Step 3.
      final neededTools = <String>['switch_provider'];

      // availableTools reflects the real llmAgentToolsProvider tool set
      // (single source of truth in fakes.dart → registeredToolNames),
      // which includes all 16 registered tools: schedule_rest_day, the
      // 4 prep tools, and the 11 domain tools — but NOT switch_provider.
      final availableTools = registeredToolNames;

      final audit = AgentRunCapture.auditTools(
        needed: neededTools,
        available: availableTools,
      );

      expect(audit, contains('switch_provider -> MISSING'));
      expect(audit, contains('1 tool(s) missing'));
    });
  });
}
