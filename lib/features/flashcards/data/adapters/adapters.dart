import 'package:hive/hive.dart';
import 'package:studyking/features/flashcards/data/adapters/flashcard_adapters.dart';

void registerFlashcardAdapters() {
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(StudyGuideAdapter());
  Hive.registerAdapter(ConceptMapAdapter());
  Hive.registerAdapter(ConceptNodeAdapter());
  Hive.registerAdapter(ConceptEdgeAdapter());
}
