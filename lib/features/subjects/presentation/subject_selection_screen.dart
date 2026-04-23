import 'package:flutter/material.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import '../../../../main.dart' show database;

/// Subject Selection Screen
/// Allows users to select or create a new subject
class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _teacherController = TextEditingController();
  final _syllabusController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _teacherController.dispose();
    _syllabusController.dispose();
    super.dispose();
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final subject = Subject(
        id: 'subject_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty 
            ? null 
            : _codeController.text.trim().toUpperCase(),
        teacher: _teacherController.text.trim().isEmpty 
            ? null 
            : _teacherController.text.trim(),
        syllabus: _syllabusController.text.trim().isEmpty 
            ? null 
            : _syllabusController.text.trim(),
        color: _selectedColor!,
      );

      await database.subjectRepository.save(subject);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving subject: $e')),
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
        title: const Text('Add Subject'),
        actions: [
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: _saveSubject,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Subject Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Physics',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subject Code
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Subject Code (Optional)',
                hintText: 'e.g., IB-PHYS',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Teacher
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: 'Teacher (Optional)',
                hintText: 'Enter teacher name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Syllabus
            TextFormField(
              controller: _syllabusController,
              decoration: const InputDecoration(
                labelText: 'Syllabus (Optional)',
                hintText: 'Enter syllabus description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Color Selection
            const Text(
              'Subject Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorChip(
                  color: const Color(0xFF2196F3),
                  colorString: '#2196F3',
                  label: 'Blue',
                  isSelected: _selectedColor == '#2196F3',
                  onTap: () => setState(() => _selectedColor = '#2196F3'),
                ),
                _buildColorChip(
                  color: const Color(0xFF4CAF50),
                  colorString: '#4CAF50',
                  label: 'Green',
                  isSelected: _selectedColor == '#4CAF50',
                  onTap: () => setState(() => _selectedColor = '#4CAF50'),
                ),
                _buildColorChip(
                  color: const Color(0xFFFFC107),
                  colorString: '#FFC107',
                  label: 'Amber',
                  isSelected: _selectedColor == '#FFC107',
                  onTap: () => setState(() => _selectedColor = '#FFC107'),
                ),
                _buildColorChip(
                  color: const Color(0xFF9C27B0),
                  colorString: '#9C27B0',
                  label: 'Purple',
                  isSelected: _selectedColor == '#9C27B0',
                  onTap: () => setState(() => _selectedColor = '#9C27B0'),
                ),
                _buildColorChip(
                  color: const Color(0xFFFF5722),
                  colorString: '#FF5722',
                  label: 'Orange',
                  isSelected: _selectedColor == '#FF5722',
                  onTap: () => setState(() => _selectedColor = '#FF5722'),
                ),
                _buildColorChip(
                  color: const Color(0xFF607D8B),
                  colorString: '#607D8B',
                  label: 'Blue Grey',
                  isSelected: _selectedColor == '#607D8B',
                  onTap: () => setState(() => _selectedColor = '#607D8B'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip({
    required Color color,
    required String colorString,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
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
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
