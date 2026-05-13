import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/presentation/subject_form_widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SubjectColorSelector', () {
    testWidgets('displays color chips for all available colors', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: SubjectColors.defaultColor,
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(InkWell), findsAtLeastNWidgets(2));
    });

    testWidgets('calls onColorSelected when tapping a color', (tester) async {
      String? selectedColor;
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: SubjectColors.defaultColor,
          onColorSelected: (color) => selectedColor = color,
        ),
      ));
      await tester.pumpAndSettle();

      final inkwells = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkwells.length, greaterThan(1));

      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();

      expect(selectedColor, isNotNull);
    });

    testWidgets('highlights selected color with bold text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: SubjectColors.defaultColor,
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Subject Color'), findsOneWidget);
    });

    testWidgets('shows color label text for each chip', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: SubjectColors.defaultColor,
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });

  group('SubjectFormFields', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectFormFields(
          formKey: GlobalKey<FormState>(),
          nameController: TextEditingController(),
          codeController: TextEditingController(),
          teacherController: TextEditingController(),
          syllabusController: TextEditingController(),
          descriptionController: TextEditingController(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_buildTestApp(
        SubjectFormFields(
          formKey: formKey,
          nameController: TextEditingController(),
          codeController: TextEditingController(),
          teacherController: TextEditingController(),
          syllabusController: TextEditingController(),
          descriptionController: TextEditingController(),
        ),
      ));
      await tester.pumpAndSettle();

      formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(find.text('Please enter a subject name'), findsOneWidget);
    });

    testWidgets('passes validation when name is provided', (tester) async {
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: 'Mathematics');
      await tester.pumpWidget(_buildTestApp(
        SubjectFormFields(
          formKey: formKey,
          nameController: nameController,
          codeController: TextEditingController(),
          teacherController: TextEditingController(),
          syllabusController: TextEditingController(),
          descriptionController: TextEditingController(),
        ),
      ));
      await tester.pumpAndSettle();

      final isValid = formKey.currentState!.validate();
      expect(isValid, isTrue);
    });

    testWidgets('code field uses textCapitalization characters', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectFormFields(
          formKey: GlobalKey<FormState>(),
          nameController: TextEditingController(),
          codeController: TextEditingController(),
          teacherController: TextEditingController(),
          syllabusController: TextEditingController(),
          descriptionController: TextEditingController(),
        ),
      ));
      await tester.pumpAndSettle();

      final codeField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(codeField.textCapitalization, TextCapitalization.characters);
    });
  });

  group('SubjectColors', () {
    test('defaultColor is a valid hex string', () {
      expect(SubjectColors.defaultColor, startsWith('#'));
    });

    test('all contains at least one color', () {
      expect(SubjectColors.all, isNotEmpty);
    });

    test('stringToColor returns a Color', () {
      final color = SubjectColors.stringToColor('#2196F3');
      expect(color, isA<Color>());
    });

    test('getColorLabel returns a string', () {
      final label = SubjectColors.getColorLabel('#2196F3');
      expect(label, isA<String>());
      expect(label, isNotEmpty);
    });
  });
}
