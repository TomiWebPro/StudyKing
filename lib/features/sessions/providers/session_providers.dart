import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});
