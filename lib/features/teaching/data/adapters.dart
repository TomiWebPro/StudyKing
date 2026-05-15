import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/conversation_message_adapter.dart';

void registerTeachingAdapters() {
  if (!Hive.isAdapterRegistered(27)) {
    Hive.registerAdapter(ConversationMessageAdapter());
  }
  if (!Hive.isAdapterRegistered(28)) {
    Hive.registerAdapter(TutorSessionAdapter());
  }
}
