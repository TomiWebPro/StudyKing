import 'package:hive/hive.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 38;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Flashcard(
      id: fields[0] as String,
      sourceId: fields[1] as String,
      topicId: fields[2] as String,
      subjectId: fields[3] as String,
      front: fields[4] as String,
      back: fields[5] as String,
      tags: (fields[6] as List?)?.cast<String>() ?? [],
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      nextReview: fields[9] as DateTime?,
      mastery: (fields[10] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.sourceId);
    writer.writeByte(2);
    writer.write(obj.topicId);
    writer.writeByte(3);
    writer.write(obj.subjectId);
    writer.writeByte(4);
    writer.write(obj.front);
    writer.writeByte(5);
    writer.write(obj.back);
    writer.writeByte(6);
    writer.write(obj.tags);
    writer.writeByte(7);
    writer.write(obj.createdAt);
    writer.writeByte(8);
    writer.write(obj.updatedAt);
    writer.writeByte(9);
    writer.write(obj.nextReview);
    writer.writeByte(10);
    writer.write(obj.mastery);
  }
}

class StudyGuideAdapter extends TypeAdapter<StudyGuide> {
  @override
  final int typeId = 39;

  @override
  StudyGuide read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return StudyGuide(
      id: fields[0] as String,
      sourceId: fields[1] as String,
      topicId: fields[2] as String,
      subjectId: fields[3] as String,
      title: fields[4] as String,
      content: fields[5] as String,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StudyGuide obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.sourceId);
    writer.writeByte(2);
    writer.write(obj.topicId);
    writer.writeByte(3);
    writer.write(obj.subjectId);
    writer.writeByte(4);
    writer.write(obj.title);
    writer.writeByte(5);
    writer.write(obj.content);
    writer.writeByte(6);
    writer.write(obj.createdAt);
  }
}

class ConceptMapAdapter extends TypeAdapter<ConceptMap> {
  @override
  final int typeId = 40;

  @override
  ConceptMap read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ConceptMap(
      id: fields[0] as String,
      sourceId: fields[1] as String,
      topicId: fields[2] as String,
      subjectId: fields[3] as String,
      title: fields[4] as String,
      nodes: (fields[5] as List?)?.cast<ConceptNode>() ?? [],
      edges: (fields[6] as List?)?.cast<ConceptEdge>() ?? [],
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ConceptMap obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.sourceId);
    writer.writeByte(2);
    writer.write(obj.topicId);
    writer.writeByte(3);
    writer.write(obj.subjectId);
    writer.writeByte(4);
    writer.write(obj.title);
    writer.writeByte(5);
    writer.write(obj.nodes);
    writer.writeByte(6);
    writer.write(obj.edges);
    writer.writeByte(7);
    writer.write(obj.createdAt);
  }
}

class ConceptNodeAdapter extends TypeAdapter<ConceptNode> {
  @override
  final int typeId = 41;

  @override
  ConceptNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ConceptNode(
      id: fields[0] as String,
      label: fields[1] as String,
      description: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConceptNode obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.label);
    writer.writeByte(2);
    writer.write(obj.description);
  }
}

class ConceptEdgeAdapter extends TypeAdapter<ConceptEdge> {
  @override
  final int typeId = 42;

  @override
  ConceptEdge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ConceptEdge(
      fromId: fields[0] as String,
      toId: fields[1] as String,
      relationship: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ConceptEdge obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.fromId);
    writer.writeByte(1);
    writer.write(obj.toId);
    writer.writeByte(2);
    writer.write(obj.relationship);
  }
}
