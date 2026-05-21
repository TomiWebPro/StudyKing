import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _aiConfigReadyCompleter = Completer<void>();

final aiConfigReadyProvider = FutureProvider<void>((ref) {
  return _aiConfigReadyCompleter.future;
});

bool get isAiConfigReady => _aiConfigReadyCompleter.isCompleted;

void markAiConfigReady() {
  if (!_aiConfigReadyCompleter.isCompleted) {
    _aiConfigReadyCompleter.complete();
  }
}
