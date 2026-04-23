import 'package:hive_flutter/hive_flutter.dart';
import '../enums.dart';

@HiveType(typeId: 4)
class Source extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final SourceType type;

  @HiveField(3, defaultValue: '')
  final String content;

  Source({
    required this.id,
    required this.title,
    required this.type,
    this.content = '',
  });
}
