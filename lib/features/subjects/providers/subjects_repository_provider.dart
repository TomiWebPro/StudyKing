// Repository Provider for subjects
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/subject_repository.dart';

final subjectsRepositoryProvider = Provider<SubjectRepository>((ref) {
  // In production, this would use a proper initialization
  // For now, just create a new instance
  return SubjectRepository();
});
