import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/session_model.dart';

IconData sessionIcon(SessionType type) {
  switch (type) {
    case SessionType.focus:
      return Icons.timer;
    case SessionType.practice:
      return Icons.play_arrow;
    case SessionType.tutoring:
      return Icons.school;
    case SessionType.manual:
      return Icons.edit_note;
  }
}

Color sessionColor(SessionType type, ThemeData theme) {
  switch (type) {
    case SessionType.focus:
      return theme.colorScheme.tertiary;
    case SessionType.practice:
      return theme.colorScheme.primary;
    case SessionType.tutoring:
      return theme.colorScheme.secondary;
    case SessionType.manual:
      return theme.colorScheme.onSurfaceVariant;
  }
}
