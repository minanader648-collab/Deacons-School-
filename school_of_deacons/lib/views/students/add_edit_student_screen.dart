import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedGrade;
  String? _photoBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _phoneController.text = widget.student!.phone;
      _notesController.text = widget.student!.notes;
      _selectedGrade = widget.student!.grade;
      _photoBase64 = widget.student!.photoBase64;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء اختيار الصورة: $e')),
        );
      }
    }
  }

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGrade == null || _selectedGrade!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار السنة الدراسية / المرحلة')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final studentProvider = Provider.of<StudentProvider>(context, listen: false);

      final newStudent = Student(
        id: widget.student?.id ?? '',
        name: _nameController.text.trim(),
        grade: _selectedGrade!,
        phone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
        photoBase64: _photoBase64,
        createdAt: widget.student?.createdAt,
      );

      if (widget.student != null) {
        await studentProvider.updateStudent(newStudent);
      } else {
        await studentProvider.addStudent(newStudent);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.student != null ? 'تم تعديل بيانات المخدوم' : 'تم إضافة المخدوم بنجاح'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    if (_selectedGrade == null && settings.grades.isNotEmpty) {
      _selectedGrade = settings.grades.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student != null ? 'تعديل بيانات مخدوم' : 'إضافة مخدوم جديد',
          style: GoogleFonts.cairo(color: AppTheme.copticGold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Photo Avatar Selection
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: AppTheme.primaryBurgundy.withOpacity(0.15),
                          backgroundImage: (_photoBase64 != null && _photoBase64!.isNotEmpty)
                              ? MemoryImage(base64Decode(_photoBase64!))
                              : null,
                          child: (_photoBase64 == null || _photoBase64!.isEmpty)
                              ? const Icon(Icons.person, size: 64, color: AppTheme.primaryBurgundy)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: AppTheme.copticGold,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: AppTheme.primaryDarkBurgundy, size: 20),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: Text('التقاط من معرض الصور', style: GoogleFonts.cairo()),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.gallery);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.camera),
                                        title: Text('التقاط بالكاميرا', style: GoogleFonts.cairo()),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.camera);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المخدوم بالكامل',
                      prefixIcon: Icon(Icons.badge, color: AppTheme.primaryBurgundy),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم المخدوم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Grade Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'السنة الدراسية / المرحلة',
                      prefixIcon: Icon(Icons.school, color: AppTheme.primaryBurgundy),
                    ),
                    items: settings.grades.map((grade) {
                      return DropdownMenuItem(
                        value: grade,
                        child: Text(grade, style: GoogleFonts.cairo()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGrade = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم تليفون المخدوم / ولي الأمر',
                      prefixIcon: Icon(Icons.phone, color: AppTheme.primaryBurgundy),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes / Deacon Rank
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (مثل: رتبة الشماس، حفظ الألحان...)',
                      prefixIcon: Icon(Icons.note_alt_outlined, color: AppTheme.primaryBurgundy),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBurgundy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.student != null ? 'حفظ التعديلات' : 'إضافة الكارنيه والمخدوم',
                              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
