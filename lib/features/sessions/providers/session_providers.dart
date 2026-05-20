import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show databaseProvider;
import 'package:studyking/core/data/repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return ref.watch(databaseProvider).sessionRepository;
});

// Convenience providers wrapping sessionRepositoryProvider for future consumers.
final allSessionsProvider = FutureProvider<Result<List<Session>>>((ref) {
  return ref.watch(sessionRepositoryProvider).getAll();
});

final todayStatsProvider = FutureProvider<Result<Map<String, dynamic>>>((ref) {
  return ref.watch(sessionRepositoryProvider).getTodayStats();
});
