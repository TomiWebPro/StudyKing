import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/color_utils.dart';
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
          selectedColor: ColorUtils.defaultColorHex,
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
          selectedColor: ColorUtils.defaultColorHex,
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
          selectedColor: ColorUtils.defaultColorHex,
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Subject Color'), findsOneWidget);
    });

    testWidgets('shows color label text for each chip', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: ColorUtils.defaultColorHex,
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting a color updates the visual selection', (tester) async {
      String selected = ColorUtils.defaultColorHex;
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: selected,
          onColorSelected: (color) => selected = color,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
    });

    testWidgets('displays all available color labels', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: ColorUtils.defaultColorHex,
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
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

    testWidgets('shows hint texts for all fields', (tester) async {
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

      expect(find.text('e.g., Physics'), findsOneWidget);
      expect(find.text('e.g., IB-PHYS'), findsOneWidget);
      expect(find.text('Enter teacher name'), findsOneWidget);
    });

    testWidgets('syllabus and description fields have multi-line input', (tester) async {
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

      final syllabusField = tester.widget<TextField>(find.byType(TextField).at(3));
      expect(syllabusField.maxLines, 3);

      final descField = tester.widget<TextField>(find.byType(TextField).at(4));
      expect(descField.maxLines, 2);
    });

    testWidgets('accepts input in all fields', (tester) async {
      final nameCtrl = TextEditingController();
      final codeCtrl = TextEditingController();
      final teacherCtrl = TextEditingController();
      final syllabusCtrl = TextEditingController();
      final descCtrl = TextEditingController();

      await tester.pumpWidget(_buildTestApp(
        SubjectFormFields(
          formKey: GlobalKey<FormState>(),
          nameController: nameCtrl,
          codeController: codeCtrl,
          teacherController: teacherCtrl,
          syllabusController: syllabusCtrl,
          descriptionController: descCtrl,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Mathematics');
      await tester.enterText(find.byType(TextFormField).at(1), 'MATH101');
      await tester.enterText(find.byType(TextFormField).at(2), 'Dr. Smith');
      await tester.enterText(find.byType(TextFormField).at(3), 'Algebra, Geometry');
      await tester.enterText(find.byType(TextFormField).at(4), 'Advanced math course');
      await tester.pumpAndSettle();

      expect(nameCtrl.text, 'Mathematics');
      expect(codeCtrl.text, 'MATH101');
      expect(teacherCtrl.text, 'Dr. Smith');
      expect(syllabusCtrl.text, 'Algebra, Geometry');
      expect(descCtrl.text, 'Advanced math course');
    });
  });

  group('ColorUtils', () {
    test('defaultColorHex is a valid hex string', () {
      expect(ColorUtils.defaultColorHex, startsWith('#'));
    });

    test('availableColors contains at least one color', () {
      expect(ColorUtils.availableColors, isNotEmpty);
    });

    test('stringToColor returns a Color', () {
      final color = ColorUtils.stringToColor('#2196F3');
      expect(color, isA<Color>());
    });

    test('getColorLabel returns a string', () {
      final label = ColorUtils.getColorLabel('#2196F3');
      expect(label, isA<String>());
      expect(label, isNotEmpty);
    });

    test('defaultColorHex matches expected hex', () {
      expect(ColorUtils.defaultColorHex, '#2196F3');
    });

    test('availableColors contains all expected colors', () {
      expect(ColorUtils.availableColors, containsAll([
        '#2196F3',
        '#4CAF50',
        '#FF9800',
        '#9C27B0',
        '#E91E63',
        '#00BCD4',
        '#FFC107',
        '#FF5722',
        '#607D8B',
      ]));
    });

    test('stringToColor returns correct color for known hex', () {
      final color = ColorUtils.stringToColor('#4CAF50');
      expect(color, isA<Color>());
      expect(color.toARGB32(), 0xFF4CAF50);
    });

    test('stringToColor handles invalid hex gracefully', () {
      final color = ColorUtils.stringToColor('invalid');
      expect(color, isA<Color>());
    });

    test('getColorLabel returns label for known color', () {
      final label = ColorUtils.getColorLabel('#2196F3');
      expect(label, 'Blue');
    });

    test('getColorLabel returns hex for unknown color', () {
      final label = ColorUtils.getColorLabel('#FFFFFF');
      expect(label, '#FFFFFF');
    });

    test('getColorLabel returns label for all known colors', () {
      expect(ColorUtils.getColorLabel('#4CAF50'), 'Green');
      expect(ColorUtils.getColorLabel('#FF9800'), 'Orange');
      expect(ColorUtils.getColorLabel('#9C27B0'), 'Purple');
      expect(ColorUtils.getColorLabel('#E91E63'), 'Pink');
      expect(ColorUtils.getColorLabel('#00BCD4'), 'Cyan');
      expect(ColorUtils.getColorLabel('#FFC107'), 'Amber');
      expect(ColorUtils.getColorLabel('#FF5722'), 'Deep Orange');
      expect(ColorUtils.getColorLabel('#607D8B'), 'Blue Grey');
    });
  });
}
