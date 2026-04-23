import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import 'package:studyking/main.dart' show database;

class SubjectManagementScreen extends ConsumerStatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  ConsumerState<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState
    extends ConsumerState<SubjectManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _syllabusController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedColor;
  DateTime? _examDate;

  final List<String> _availableColors = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#E91E63', // Pink
    '#00BCD4', // Cyan
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _teacherController.dispose();
    _syllabusController.dispose();
    super.dispose();
  }

  Future<void> _createSubject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final subject = Subject(
        id: 'subject_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty 
            ? _codeController.text.trim().toUpperCase() 
            : null,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        teacher: _teacherController.text.trim().isNotEmpty 
            ? _teacherController.text.trim() 
            : null,
        syllabus: _syllabusController.text.trim().isNotEmpty 
            ? _syllabusController.text.trim() 
            : null,
        color: _selectedColor ?? '#2196F3',
        examDate: _examDate,
      );

      await database.subjectRepository.save(subject);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating subject: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Subject'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name *',
                hintText: 'e.g., Physics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Subject Code (Optional)',
                hintText: 'e.g., IB-PHYS',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Color selection
            const Text('Theme Color',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors
                  .map((color) => InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _colorToMaterialColor(color),
                            shape: BoxShape.circle,
                            border: _selectedColor == color
                                ? Border.all(
                                    color: Colors.white,
                                    width: 3,
                                    style: BorderStyle.solid,
                                  )
                                : null,
                            boxShadow: _selectedColor == color
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the subject',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: 'Teacher (Optional)',
                hintText: 'e.g., Dr. John Smith',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _syllabusController,
              decoration: const InputDecoration(
                labelText: 'Syllabus/Scope (Optional)',
                hintText: 'Brief overview of the syllabus',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text('Exam Date (Optional): '),
                TextButton.icon(
                  onPressed: _selectExamDate,
                  icon: Icon(
                    _examDate != null
                        ? Icons.calendar_today
                        : Icons.calendar_today_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _examDate != null
                        ? '${_examDate!.month}/${_examDate!.day}/${_examDate!.year}'
                        : 'Select date',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createSubject,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Subject'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExamDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _examDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null) {
      setState(() => _examDate = date);
    }
  }

  Color _colorToMaterialColor(String hexColor) {
    // Convert hex string like '#2196F3' to Color
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }
}
