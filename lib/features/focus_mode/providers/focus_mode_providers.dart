import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';

final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return FocusSessionRepository();
});

final focusSessionServiceProvider = Provider<FocusSessionService>((ref) {
  final repository = ref.watch(focusSessionRepositoryProvider);
  return FocusSessionService(repository: repository);
});
