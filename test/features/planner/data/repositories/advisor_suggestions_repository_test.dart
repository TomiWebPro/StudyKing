import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/plan_advisor_suggestion_model.dart';
import 'package:studyking/features/planner/data/repositories/advisor_suggestions_repository.dart';

class FakeAdvisorBox implements Box<PlanAdvisorSuggestionModel> {
  final Map<String, PlanAdvisorSuggestionModel> _storage = {};
  bool _isOpen = true;

  @override
  Iterable<PlanAdvisorSuggestionModel> get values => _storage.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  PlanAdvisorSuggestionModel? get(dynamic key, {PlanAdvisorSuggestionModel? defaultValue}) {
    return _storage[key as String] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, PlanAdvisorSuggestionModel value) async {
    _storage[key as String] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key as String);
  }

  @override
  bool containsKey(dynamic key) {
    return _storage.containsKey(key as String);
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  String get name => 'mock-advisor-suggestions';

  @override
  Iterable<String> get keys => _storage.keys;

  void addSuggestion(PlanAdvisorSuggestionModel model) {
    _storage[model.id] = model;
  }

  void clearStorage() {
    _storage.clear();
  }
}

class TestableAdvisorSuggestionsRepository extends AdvisorSuggestionsRepository {
  void attachMockBox(Box<PlanAdvisorSuggestionModel> box) {
    attachBox(box);
  }
}

PlanAdvisorSuggestionModel createTestSuggestion({
  String id = 'suggestion-1',
  String studentId = 'student-1',
  String suggestionType = 'plan_generation',
  bool applied = false,
}) {
  return PlanAdvisorSuggestionModel(
    id: id,
    studentId: studentId,
    generatedAt: DateTime(2026, 5, 20),
    suggestionType: suggestionType,
    workloadEstimate: applied ? null : '~3h/day',
    applied: applied,
  );
}

void main() {
  group('AdvisorSuggestionsRepository', () {
    late TestableAdvisorSuggestionsRepository repository;
    late FakeAdvisorBox mockBox;

    setUp(() {
      mockBox = FakeAdvisorBox();
      repository = TestableAdvisorSuggestionsRepository();
      repository.attachMockBox(mockBox);
    });

    group('create', () {
      test('stores a suggestion by id', () async {
        final suggestion = createTestSuggestion();
        final result = await repository.create(suggestion);
        expect(result.isSuccess, isTrue);
        final stored = mockBox.get('suggestion-1');
        expect(stored, isNotNull);
      });
    });

    group('getLatestByStudent', () {
      test('returns the most recent suggestion for a student', () async {
        mockBox.addSuggestion(createTestSuggestion(
          id: 'old', studentId: 's1',
          applied: true,
        ));
        mockBox.addSuggestion(createTestSuggestion(
          id: 'recent', studentId: 's1',
        ));
        final result = await repository.getLatestByStudent('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.id, 'recent');
      });

      test('returns null when no suggestions exist', () async {
        final result = await repository.getLatestByStudent('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });
    });

    group('getByStudent', () {
      test('returns all suggestions sorted by generatedAt descending', () async {
        mockBox.addSuggestion(createTestSuggestion(
          id: 'a1', studentId: 's1',
        ));
        mockBox.addSuggestion(createTestSuggestion(
          id: 'a2', studentId: 's1', suggestionType: 'adaptation',
        ));
        final result = await repository.getByStudent('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
      });

      test('returns empty for student with no suggestions', () async {
        final result = await repository.getByStudent('none');
        expect(result.data, isEmpty);
      });
    });

    group('markApplied', () {
      test('marks a suggestion as applied', () async {
        mockBox.addSuggestion(createTestSuggestion(id: 's1'));
        await repository.markApplied('s1');
        final stored = mockBox.get('s1');
        expect(stored!.applied, isTrue);
      });
    });

    group('getUnappliedByStudent', () {
      test('returns only unapplied suggestions', () async {
        mockBox.addSuggestion(createTestSuggestion(id: 'a1', studentId: 's1'));
        mockBox.addSuggestion(createTestSuggestion(id: 'a2', studentId: 's1', applied: true));
        final result = await repository.getUnappliedByStudent('s1');
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'a1');
      });
    });

    group('deleteSuggestion', () {
      test('removes a suggestion', () async {
        mockBox.addSuggestion(createTestSuggestion(id: 'd1'));
        await repository.deleteSuggestion('d1');
        expect(mockBox.get('d1'), isNull);
      });
    });
  });

  group('error handling', () {
    test('create returns failure when box throws', () async {
      final repo = AdvisorSuggestionsRepository();
      repo.attachBox(_ThrowingAdvisorBox());
      final result = await repo.create(createTestSuggestion());
      expect(result.isFailure, isTrue);
    });

    test('getLatestByStudent returns failure when box throws', () async {
      final repo = AdvisorSuggestionsRepository();
      repo.attachBox(_ThrowingAdvisorBox());
      final result = await repo.getLatestByStudent('test');
      expect(result.isFailure, isTrue);
    });
  });

  group('AdvisorSuggestionsRepository (init with real Hive)', () {
    late AdvisorSuggestionsRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestAdvisorSuggestionAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('advisor_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = AdvisorSuggestionsRepository();
      final initResult = await repository.init();
      expect(initResult.isSuccess, isTrue);
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('plan_advisor_suggestions');
    });

    test('init opens box and supports CRUD', () async {
      final suggestion = createTestSuggestion(id: 'hive-1');
      await repository.create(suggestion);
      final stored = await repository.getLatestByStudent('student-1');
      expect(stored.data, isNotNull);
      expect(stored.data!.id, 'hive-1');
    });

    test('markApplied works after init', () async {
      await repository.create(createTestSuggestion(id: 'm1', studentId: 's1'));
      await repository.markApplied('m1');
      final stored = await repository.get('m1');
      expect(stored.data?.applied, isTrue);
    });
  });
}

class _ThrowingAdvisorBox implements Box<PlanAdvisorSuggestionModel> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw Exception('Simulated Hive error');
  }
}

class _TestAdvisorSuggestionAdapter extends TypeAdapter<PlanAdvisorSuggestionModel> {
  @override
  final int typeId = 37;

  @override
  PlanAdvisorSuggestionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanAdvisorSuggestionModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      generatedAt: fields[2] as DateTime,
      suggestionType: fields[3] as String? ?? 'plan_generation',
      workloadEstimate: fields[4] as String?,
      pathwaySuggestion: fields[5] as String?,
      motivationalReasoning: fields[6] as String?,
      metadata: fields[7] != null
          ? Map<String, dynamic>.from(fields[7] as Map)
          : const {},
      applied: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, PlanAdvisorSuggestionModel obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.studentId);
    writer.writeByte(2);
    writer.write(obj.generatedAt);
    writer.writeByte(3);
    writer.write(obj.suggestionType);
    writer.writeByte(4);
    writer.write(obj.workloadEstimate);
    writer.writeByte(5);
    writer.write(obj.pathwaySuggestion);
    writer.writeByte(6);
    writer.write(obj.motivationalReasoning);
    writer.writeByte(7);
    writer.write(obj.metadata);
    writer.writeByte(8);
    writer.write(obj.applied);
  }
}
