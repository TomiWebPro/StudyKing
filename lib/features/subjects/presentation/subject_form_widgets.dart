import 'package:flutter/material.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

const _commonSyllabi = [
  // Advanced Placement (AP)
  'AP Biology',
  'AP Chemistry',
  'AP Physics 1',
  'AP Physics 2',
  'AP Physics C: Mechanics',
  'AP Physics C: E&M',
  'AP Calculus AB',
  'AP Calculus BC',
  'AP Statistics',
  'AP English Language',
  'AP English Literature',
  'AP US History',
  'AP World History',
  'AP European History',
  'AP Economics (Macro)',
  'AP Economics (Micro)',
  'AP Psychology',
  'AP Computer Science A',
  'AP Computer Science Principles',
  'AP Environmental Science',
  'AP Human Geography',
  'AP Spanish Language',
  'AP French Language',
  'AP Art History',
  'AP Music Theory',
  // A-Levels (UK)
  'A-Level Biology',
  'A-Level Chemistry',
  'A-Level Physics',
  'A-Level Mathematics',
  'A-Level Further Mathematics',
  'A-Level English Literature',
  'A-Level History',
  'A-Level Economics',
  'A-Level Geography',
  'A-Level Psychology',
  'A-Level Computer Science',
  'A-Level French',
  'A-Level Spanish',
  'A-Level German',
  'A-Level Business Studies',
  'A-Level Law',
  'A-Level Art & Design',
  // GCSE / IGCSE
  'GCSE Biology',
  'GCSE Chemistry',
  'GCSE Physics',
  'GCSE Mathematics',
  'GCSE English Language',
  'GCSE English Literature',
  'GCSE History',
  'GCSE Geography',
  'GCSE French',
  'GCSE Spanish',
  'GCSE Computer Science',
  'IGCSE Biology',
  'IGCSE Chemistry',
  'IGCSE Physics',
  'IGCSE Mathematics',
  'IGCSE English',
  'IGCSE Economics',
  'IGCSE Business Studies',
  // International Baccalaureate (IB)
  'IB Biology',
  'IB Chemistry',
  'IB Physics',
  'IB Mathematics: Analysis & Approaches',
  'IB Mathematics: Applications & Interpretation',
  'IB English A: Literature',
  'IB English A: Language & Literature',
  'IB History',
  'IB Economics',
  'IB Psychology',
  'IB Computer Science',
  'IB Environmental Systems & Societies',
  'IB French B',
  'IB Spanish B',
  'IB German B',
  'IB Chinese B',
  'IB Visual Arts',
  'IB Theory of Knowledge',
  // Standardized Tests
  'SAT Math',
  'SAT Reading & Writing',
  'ACT',
  'GRE',
  'GMAT',
  'MCAT',
  'LSAT',
  'DAT',
];

class SubjectColorSelector extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;

  const SubjectColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subjectColor,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ColorUtils.availableColors.map((colorString) {
            final isSelected = selectedColor == colorString;
            final color = ColorUtils.stringToColor(colorString);
            return InkWell(
              onTap: () => onColorSelected(colorString),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(
                    color: isSelected ? color : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ColorUtils.getColorLabel(colorString, l10n: l10n),
                      style: TextStyle(
                        color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SubjectFormFields extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController teacherController;
  final TextEditingController syllabusController;
  final TextEditingController descriptionController;

  const SubjectFormFields({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.codeController,
    required this.teacherController,
    required this.syllabusController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue value) {
              if (value.text.isEmpty) return [];
              final matches = _commonSyllabi.where((s) =>
                  s.normalized.contains(value.text.normalized));

              return matches.take(10);
            },
            onSelected: (selection) => nameController.text = selection,
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: l10n.subjectName,
                  hintText: l10n.subjectNameHint,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterSubjectName;
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: l10n.subjectCodeOptional,
              hintText: l10n.subjectCodeHint,
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: teacherController,
            decoration: InputDecoration(
              labelText: l10n.teacherOptional,
              hintText: l10n.teacherNameHint,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue value) {
              if (value.text.isEmpty) return [];
              return _commonSyllabi.where((s) =>
                  s.normalized.contains(value.text.normalized));
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250.0),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            child: Text(option),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (selection) => syllabusController.text = selection,
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: l10n.syllabusScopeOptional,
                  hintText: l10n.syllabusDescriptionHint,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => syllabusController.text = value,
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: l10n.descriptionOptional,
              hintText: l10n.descriptionHint,
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}