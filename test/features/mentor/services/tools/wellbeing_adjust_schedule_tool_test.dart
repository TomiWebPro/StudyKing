import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/services/tools/wellbeing_adjust_schedule_tool.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  group('WellbeingAdjustScheduleTool', () {
    setUpAll(() async {
      await AppLocalizations.delegate.load(const Locale('en'));
    });

    WellbeingAdjustScheduleTool buildTool({
      required List<Map<String, dynamic>> receivedCalls,
      bool shouldPersistSucceed = true,
    }) {
      return WellbeingAdjustScheduleTool(
        localeName: 'en',
        onAdjust: ({
          required String reminderType,
          required String time,
          required bool enabled,
          String? note,
        }) async {
          receivedCalls.add({
            'reminderType': reminderType,
            'time': time,
            'enabled': enabled,
            if (note != null) 'note': note,
          });
          return shouldPersistSucceed
              ? Result.success(null)
              : Result.failure('persistence error');
        },
      );
    }

    test('sets a bedtime reminder and reports success', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);
      final l10n = lookupAppLocalizations(const Locale('en'));

      final result = await tool.execute({
        'reminderType': 'bedtime',
        'time': '22:00',
      });

      expect(result['success'], isTrue);
      expect(result['reminderType'], 'bedtime');
      expect(result['time'], '22:00');
      expect(result['message'], l10n.toolWellbeingReminderResult('bedtime', '22:00'));
      expect(receivedCalls, hasLength(1));
      expect(receivedCalls.first['reminderType'], 'bedtime');
      expect(receivedCalls.first['time'], '22:00');
      expect(receivedCalls.first['enabled'], isTrue);
    });

    test('sets a break reminder and reports success', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'break',
        'time': '15:30',
      });

      expect(result['success'], isTrue);
      expect(result['reminderType'], 'break');
      expect(result['time'], '15:30');
      expect(receivedCalls, hasLength(1));
      expect(receivedCalls.first['reminderType'], 'break');
    });

    test('sets a pacing reminder with valid time and reports success', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'pacing',
        'time': '00:30',
      });

      expect(result['success'], isTrue);
      expect(result['reminderType'], 'pacing');
      expect(result['time'], '00:30');
    });

    test('tolerates case-insensitive reminderType from the LLM', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'BEDTIME',
        'time': '22:00',
      });

      expect(result['success'], isTrue);
      expect(result['reminderType'], 'bedtime');
      expect(receivedCalls.first['reminderType'], 'bedtime');
    });

    test('tolerates whitespace in reminderType from the LLM', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': '  bedtime  ',
        'time': '22:00',
      });

      expect(result['success'], isTrue);
      expect(result['reminderType'], 'bedtime');
    });

    test('returns validation failure for an unknown reminderType', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final l10n = lookupAppLocalizations(const Locale('en'));
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'meditation',
        'time': '08:00',
      });

      expect(result['success'], isFalse);
      expect(result['message'], l10n.toolWellbeingReminderInvalidType);
      expect(receivedCalls, isEmpty);
    });

    test('returns validation failure when reminderType is missing', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final l10n = lookupAppLocalizations(const Locale('en'));
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'time': '22:00',
      });

      expect(result['success'], isFalse);
      expect(result['message'], l10n.toolWellbeingReminderInvalidType);
      expect(receivedCalls, isEmpty);
    });

    test('returns validation failure for an invalid time format', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final l10n = lookupAppLocalizations(const Locale('en'));
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'bedtime',
        'time': '22:00:00',
      });

      expect(result['success'], isFalse);
      expect(result['message'], l10n.toolWellbeingReminderInvalidTime);
      expect(receivedCalls, isEmpty);
    });

    test('returns validation failure for 2400 without colon', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final l10n = lookupAppLocalizations(const Locale('en'));
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'bedtime',
        'time': '2400',
      });

      expect(result['success'], isFalse);
      expect(result['message'], l10n.toolWellbeingReminderInvalidTime);
    });

    test('accepts 23:59 as the latest valid time', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'bedtime',
        'time': '23:59',
      });

      expect(result['success'], isTrue);
      expect(receivedCalls.first['time'], '23:59');
    });

    test('accepts 00:00 as the earliest valid time', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'break',
        'time': '00:00',
      });

      expect(result['success'], isTrue);
      expect(receivedCalls.first['time'], '00:00');
    });

    test('disables a reminder when enabled is false', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final l10n = lookupAppLocalizations(const Locale('en'));
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'bedtime',
        'time': '22:00',
        'enabled': false,
      });

      expect(result['success'], isTrue);
      expect(result['message'], l10n.toolWellbeingReminderDisabled('bedtime'));
      expect(receivedCalls, hasLength(1));
      expect(receivedCalls.first['enabled'], isFalse);
    });

    test('does not validate time format when disabling', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      final result = await tool.execute({
        'reminderType': 'bedtime',
        'time': 'invalid',
        'enabled': false,
      });

      // When disabling, the callback is still called — the time is just
      // recorded without HH:MM format validation.
      expect(result['success'], isTrue);
      expect(receivedCalls, hasLength(1));
    });

    test('reports failure when persistence callback fails', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final l10n = lookupAppLocalizations(const Locale('en'));
      final tool = buildTool(
        receivedCalls: receivedCalls,
        shouldPersistSucceed: false,
      );

      final result = await tool.execute({
        'reminderType': 'bedtime',
        'time': '22:00',
      });

      expect(result['success'], isFalse);
      expect(result['message'], l10n.toolWellbeingReminderFail);
      expect(receivedCalls, hasLength(1));
    });

    test('passes the optional note to the callback', () async {
      final receivedCalls = <Map<String, dynamic>>[];
      final tool = buildTool(receivedCalls: receivedCalls);

      await tool.execute({
        'reminderType': 'break',
        'time': '15:30',
        'note': 'after math practice',
      });

      expect(receivedCalls.first['note'], 'after math practice');
    });

    test('tool name and description are correct', () {
      final tool = buildTool(receivedCalls: []);
      expect(tool.name, 'wellbeing_adjust_schedule');
      expect(tool.description, contains('wellbeing'));
    });

    test('parameters include reminderType, time, enabled, and note', () {
      final tool = buildTool(receivedCalls: []);
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['properties'], containsPair('reminderType', isA<Map>()));
      expect(params['properties'], containsPair('time', isA<Map>()));
      expect(params['properties'], containsPair('enabled', isA<Map>()));
      expect(params['properties'], containsPair('note', isA<Map>()));
      expect(params['required'], containsAll(['reminderType', 'time']));
      expect(params['required'], isNot(contains('enabled')));
      expect(params['required'], isNot(contains('note')));
    });

    test('reminderType enum matches validReminderTypes', () {
      final tool = buildTool(receivedCalls: []);
      final reminderTypeProp =
          tool.parameters['properties']['reminderType'] as Map;
      final enumValues = reminderTypeProp['enum'] as List<String>;
      expect(
        enumValues.toSet(),
        WellbeingAdjustScheduleTool.validReminderTypes,
      );
    });

    test('enabled defaults to true in schema', () {
      final tool = buildTool(receivedCalls: []);
      final enabledProp =
          tool.parameters['properties']['enabled'] as Map;
      expect(enabledProp['default'], isTrue);
    });
  });
}
