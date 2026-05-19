import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/responsive.dart';

class PracticeSheetTemplate extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const PracticeSheetTemplate({
    super.key,
    required this.title,
    required this.children,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: AppTheme.bottomSheetShape,
      builder: (_) => PracticeSheetTemplate(
        title: title,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenPad = ResponsiveUtils.screenPadding(context);
    return SafeArea(
      child: Container(
        padding: screenPad,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
  }
}
