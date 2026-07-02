import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/services/llm_task_service.dart';

void main() {
  group('LlmTasks + Ingestion integration', () {
    late LlmTaskManager taskManager;
    late LlmTaskService taskService;

    setUp(() {
      taskManager = LlmTaskManager();
      taskService = LlmTaskService(manager: taskManager);
    });

    test('LlmService chat creates and completes a task', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': 'Classified as biology'}}
            ],
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final llmService = LlmService(
        config: const LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test-key',
        ),
        httpClient: mockClient,
        taskManager: taskManager,
      );

      final result = await llmService.chat(
        message: 'Classify this content',
        modelId: 'gemini-2.0-flash',
        feature: 'content_classification',
      );

      expect(result.isSuccess, isTrue);
      expect(taskService.getAllTasks(), hasLength(1));

      final task = taskService.getAllTasks().first;
      expect(task.feature, 'content_classification');
      expect(task.modelId, 'gemini-2.0-flash');
      expect(task.status, LlmTaskStatus.done);
      expect(task.startTime, isNotNull);
      expect(task.endTime, isNotNull);
    });

    test('LlmService chat creates task with different feature tags', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': 'OK'}}
            ],
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final llmService = LlmService(
        config: const LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test-key',
        ),
        httpClient: mockClient,
        taskManager: taskManager,
      );

      await llmService.chat(
        message: 'Classify this content',
        modelId: 'gemini-2.0-flash',
        feature: 'content_classification',
      );
      await llmService.chat(
        message: 'Summarize this',
        modelId: 'gemini-2.0-flash',
        feature: 'content_summarization',
      );

      expect(taskService.getAllTasks(), hasLength(2));
      expect(taskService.getTasksByFeature('content_classification'), hasLength(1));
      expect(taskService.getTasksByFeature('content_summarization'), hasLength(1));
    });

    test('LlmService handles API failure and marks task as failed', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 500);
      });

      final llmService = LlmService(
        config: const LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test-key',
        ),
        httpClient: mockClient,
        taskManager: taskManager,
      );

      final result = await llmService.chat(
        message: 'Test',
        modelId: 'gemini-2.0-flash',
        feature: 'question_generation',
      );

      expect(result.isFailure, isTrue);
      expect(taskService.getAllTasks(), hasLength(1));

      final task = taskService.getAllTasks().first;
      expect(task.feature, 'question_generation');
      expect(task.status, LlmTaskStatus.failed);
      expect(task.error, isNotEmpty);
    });

    test('LlmTaskService aggregates ingestion-like tasks', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': 'OK'}}
            ],
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final llmService = LlmService(
        config: const LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test-key',
        ),
        httpClient: mockClient,
        taskManager: taskManager,
      );

      for (var i = 0; i < 3; i++) {
        await llmService.chat(
          message: 'Generate question $i',
          modelId: 'gemini-2.0-flash',
          feature: 'question_generation',
        );
      }

      expect(taskService.getAllTasks(), hasLength(3));
      expect(taskService.getTasksByFeature('question_generation'), hasLength(3));
      expect(taskService.getFilteredTasks(
        feature: 'question_generation',
        status: LlmTaskStatus.done,
      ), hasLength(3));
    });

    test('Active tasks tracked during in-flight ingestion calls', () async {
      expect(taskService.getActiveTasks(), isEmpty);

      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 1));
        return http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': 'Delayed'}}
            ],
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final llmService = LlmService(
        config: const LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test-key',
        ),
        httpClient: mockClient,
        taskManager: taskManager,
      );

      final future = llmService.chat(
        message: 'Slow request',
        modelId: 'gemini-2.0-flash',
        feature: 'content_classification',
      );

      await Future.delayed(Duration.zero);
      expect(taskService.getActiveTasks(), hasLength(1));
      expect(taskService.getActiveTasks().first.status, LlmTaskStatus.running);

      await future;
      expect(taskService.getActiveTasks(), isEmpty);
    });
  });
}
