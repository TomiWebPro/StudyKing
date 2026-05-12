import 'package:flutter/material.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectColors {
  static const List<String> all = ColorUtils.availableColors;

  static String get defaultColor => ColorUtils.defaultColorHex;

  static Color stringToColor(String hexColor) => ColorUtils.stringToColor(hexColor);

  static String getColorLabel(String hexColor, {AppLocalizations? l10n}) =>
      ColorUtils.getColorLabel(hexColor, l10n: l10n);
}

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
          children: SubjectColors.all.map((colorString) {
            final isSelected = selectedColor == colorString;
            final color = SubjectColors.stringToColor(colorString);
            return InkWell(
              onTap: () => onColorSelected(colorString),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
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
                      SubjectColors.getColorLabel(colorString, l10n: l10n),
                      style: TextStyle(
                        color: isSelected ? color : Colors.black87,
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
        physics: const NeverScrollableScrollPhysics(),
        children: [
          TextFormField(
            controller: nameController,
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
          TextFormField(
            controller: syllabusController,
            decoration: InputDecoration(
              labelText: l10n.syllabusScopeOptional,
              hintText: l10n.syllabusDescriptionHint,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
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