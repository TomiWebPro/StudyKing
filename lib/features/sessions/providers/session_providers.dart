import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final repo = SessionRepository();
  ref.onDispose(() {});
  return repo;
});

final allSessionsProvider = FutureProvider<Result<List<Session>>>((ref) {
  return ref.watch(sessionRepositoryProvider).getAll();
});

final todayStatsProvider = FutureProvider<Result<Map<String, dynamic>>>((ref) {
  return ref.watch(sessionRepositoryProvider).getTodayStats();
});
