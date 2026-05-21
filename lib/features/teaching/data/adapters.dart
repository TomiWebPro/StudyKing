import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/conversation_message_adapter.dart';
import 'adapters/tutor_session_adapter.dart';

void registerTeachingAdapters() {
  if (!Hive.isAdapterRegistered(27)) {
    Hive.registerAdapter(ConversationMessageAdapter());
  }
  if (!Hive.isAdapterRegistered(28)) {
    Hive.registerAdapter(TutorSessionAdapter());
  }
}
