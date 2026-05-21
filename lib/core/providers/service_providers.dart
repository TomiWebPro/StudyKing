import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/voice_service.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

final studentIdServiceProvider = Provider<StudentIdService>((ref) {
  return StudentIdService();
});

final studentIdProvider = FutureProvider<String>((ref) async {
  final service = ref.read(studentIdServiceProvider);
  await service.init();
  return service.getStudentId();
});

final studentIdValueProvider = Provider<String>((ref) {
  return ref.watch(studentIdProvider).valueOrNull ?? '';
});
