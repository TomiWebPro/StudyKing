import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';

class SourceAdapter extends TypeAdapter<Source> {
  @override
  final int typeId = 26;

  @override
  Source read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Source(
      id: fields[0] as String,
      title: fields[1] as String,
      type: SourceType.values[fields[2] as int],
      content: fields[3] as String? ?? '',
      subjectId: fields[4] as String? ?? '',
      topicId: fields[5] as String? ?? '',
      syllabusId: fields[6] as String? ?? '',
      sourceUrl: fields[7] as String? ?? '',
      studentId: fields[8] as String? ?? '',
      language: fields[9] as String? ?? '',
      summary: fields[10] as String? ?? '',
      processingStatus: fields[11] as String? ?? 'pending',
      extractedText: fields[12] as String? ?? '',
      generatedQuestionIds: fields[13] != null
          ? List<String>.from(fields[13] as List)
          : const [],
      extractionMethod: fields[14] as String? ?? '',
      chunks: fields[15] as String? ?? '',
      extractionMeta: fields[16] as String? ?? '',
      createdAt: fields[17] as DateTime?,
      errorMessage: fields[18] as String? ?? '',
      contentHash: fields[19] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Source obj) {
    writer.writeByte(20);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.type.index);
    writer.writeByte(3);
    writer.write(obj.content);
    writer.writeByte(4);
    writer.write(obj.subjectId);
    writer.writeByte(5);
    writer.write(obj.topicId);
    writer.writeByte(6);
    writer.write(obj.syllabusId);
    writer.writeByte(7);
    writer.write(obj.sourceUrl);
    writer.writeByte(8);
    writer.write(obj.studentId);
    writer.writeByte(9);
    writer.write(obj.language);
    writer.writeByte(10);
    writer.write(obj.summary);
    writer.writeByte(11);
    writer.write(obj.processingStatus);
    writer.writeByte(12);
    writer.write(obj.extractedText);
    writer.writeByte(13);
    writer.write(obj.generatedQuestionIds);
    writer.writeByte(14);
    writer.write(obj.extractionMethod);
    writer.writeByte(15);
    writer.write(obj.chunks);
    writer.writeByte(16);
    writer.write(obj.extractionMeta);
    writer.writeByte(17);
    writer.write(obj.createdAt);
    writer.writeByte(18);
    writer.write(obj.errorMessage);
    writer.writeByte(19);
    writer.write(obj.contentHash);
  }
}
