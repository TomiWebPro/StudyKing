import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/plan_advisor_suggestion_model.dart';

class PlanAdvisorSuggestionAdapter extends TypeAdapter<PlanAdvisorSuggestionModel> {
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
