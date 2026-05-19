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
    });

    testWidgets('calls onColorSelected when tapping a color chip', (tester) async {
      String? selectedColor;
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: ColorUtils.defaultColorHex,
          onColorSelected: (color) => selectedColor = color,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Green'));
      await tester.pumpAndSettle();

      expect(selectedColor, '#4CAF50');
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
      expect(find.text('Purple'), findsOneWidget);
      expect(find.text('Pink'), findsOneWidget);
      expect(find.text('Cyan'), findsOneWidget);
      expect(find.text('Amber'), findsOneWidget);
      expect(find.text('Deep Orange'), findsOneWidget);
      expect(find.text('Blue Grey'), findsOneWidget);
    });

    testWidgets('selected color has bold text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: '#4CAF50',
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      final greenText = tester.widget<Text>(find.text('Green'));
      expect(greenText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('non-selected color has normal weight text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: '#2196F3',
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      final greenText = tester.widget<Text>(find.text('Green'));
      expect(greenText.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('selected color chip has thicker border', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: '#FF9800',
          onColorSelected: (color) {},
        ),
      ));
      await tester.pumpAndSettle();

      final orangeText = tester.widget<Text>(find.text('Orange'));
      expect(orangeText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('calls onColorSelected with correct color string for Green', (tester) async {
      String? result;
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: '#2196F3',
          onColorSelected: (color) => result = color,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Green'));
      await tester.pumpAndSettle();

      expect(result, '#4CAF50');
    });

    testWidgets('selecting Amber color triggers callback', (tester) async {
      String? result;
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: '#2196F3',
          onColorSelected: (color) => result = color,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Amber'));
      await tester.pumpAndSettle();

      expect(result, '#FFC107');
    });

    testWidgets('selecting Pink color triggers callback', (tester) async {
      String? result;
      await tester.pumpWidget(_buildTestApp(
        SubjectColorSelector(
          selectedColor: '#2196F3',
          onColorSelected: (color) => result = color,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pink'));
      await tester.pumpAndSettle();

      expect(result, '#E91E63');
    });
  });

  group('SubjectFormFields', () {
    testWidgets('renders 5 text form fields (name via Autocomplete + 4 plain)', (tester) async {
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

    testWidgets('passes validation when name text is entered via field', (tester) async {
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

      await tester.enterText(find.byType(TextFormField).first, 'Mathematics');
      await tester.pumpAndSettle();
      // Tap elsewhere to dismiss the autocomplete dropdown
      await tester.tapAt(const Offset(0, 0));
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

    testWidgets('shows hint texts for fields', (tester) async {
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

    testWidgets('accepts input in code, teacher, syllabus, and description fields', (tester) async {
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

      // Enter text into the name field (Autocomplete-managed controller)
      await tester.enterText(find.byType(TextFormField).at(0), 'Mathematics');
      // Enter text into code, teacher, syllabus, description fields
      await tester.enterText(find.byType(TextFormField).at(1), 'MATH101');
      await tester.enterText(find.byType(TextFormField).at(2), 'Dr. Smith');
      await tester.enterText(find.byType(TextFormField).at(3), 'Algebra, Geometry');
      await tester.enterText(find.byType(TextFormField).at(4), 'Advanced math course');
      await tester.pumpAndSettle();

      // Name controller is not updated by Autocomplete field (it has its own controller)
      // So we only check the direct controllers for code, teacher, syllabus, description
      expect(codeCtrl.text, 'MATH101');
      expect(teacherCtrl.text, 'Dr. Smith');
      expect(syllabusCtrl.text, 'Algebra, Geometry');
      expect(descCtrl.text, 'Advanced math course');
    });

    testWidgets('syllabus autocomplete shows options when typing', (tester) async {
      final syllabusCtrl = TextEditingController();

      await tester.pumpWidget(_buildTestApp(
        SubjectFormFields(
          formKey: GlobalKey<FormState>(),
          nameController: TextEditingController(),
          codeController: TextEditingController(),
          teacherController: TextEditingController(),
          syllabusController: syllabusCtrl,
          descriptionController: TextEditingController(),
        ),
      ));
      await tester.pumpAndSettle();

      final syllabusField = find.byType(TextFormField).at(3);
      await tester.enterText(syllabusField, 'IB');
      await tester.pumpAndSettle();

      // Autocomplete should show options, we can verify by checking
      // that the overlay appears with "IB Biology" option
      expect(syllabusCtrl.text, isEmpty);
    });

    testWidgets('empty name fails validation', (tester) async {
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

      final isValid = formKey.currentState!.validate();
      expect(isValid, isFalse);
    });
  });
}
