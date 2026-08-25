import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show localeProvider, selectedModelProvider;
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/core/services/handwriting_recognition_service.dart';
import 'package:studyking/core/services/learning_method_analytics_service.dart';
import 'package:studyking/core/services/vision_interpretation_service.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

final studentIdServiceProvider = Provider<StudentIdService>((ref) {
  return StudentIdService();
});

final handwritingRecognitionServiceProvider =
    Provider<HandwritingRecognitionService>((ref) {
  return HandwritingRecognitionService();
});

final visionInterpretationServiceProvider =
    Provider<VisionInterpretationService>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final locale = ref.watch(localeProvider);
  final modelId = ref.watch(selectedModelProvider);
  final ocrExtractor = OcrExtractor(
    llmService: llmService,
    modelId: modelId,
    localeName: locale.languageCode,
  );
  return VisionInterpretationService(ocrExtractor: ocrExtractor);
});

final studentIdProvider = FutureProvider<String>((ref) async {
  final service = ref.read(studentIdServiceProvider);
  await service.init();
  return service.getStudentId();
});

final studentIdValueProvider = Provider<String>((ref) {
  return ref.watch(studentIdProvider).valueOrNull ?? '';
});

final learningMethodAnalyticsServiceProvider =
    Provider<LearningMethodAnalyticsService>((ref) {
  final service = LearningMethodAnalyticsService();
  service.init();
  return service;
});
