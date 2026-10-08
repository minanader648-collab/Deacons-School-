import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/student_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'add_edit_student_screen.dart';
import 'student_detail_screen.dart';
import 'student_badge_screen.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    final gradesList = ['الكل', ...settings.grades];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search & Filter Row
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => studentProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم المخدوم أو رقم التليفون...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBurgundy),
                        suffixIcon: studentProvider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => studentProvider.setSearchQuery(''),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter by Grade Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: gradesList.map((grade) {
                          final isSelected = studentProvider.selectedGradeFilter == grade;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FilterChip(
                              label: Text(
                                grade,
                                style: GoogleFonts.cairo(
                                  color: isSelected ? Colors.white : AppTheme.primaryBurgundy,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryBurgundy,
                              checkmarkColor: AppTheme.copticGold,
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (_) => studentProvider.setGradeFilter(grade),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Student Count Summary
            Row(
              children: [
                Expanded(
                  child: Text(
                    'النتائج: ${studentProvider.filteredStudents.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBurgundy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEditStudentScreen()),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'إضافة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBurgundy,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Students List / Grid
            Expanded(
              child: studentProvider.filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_search_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'لم يتم العثور على مخدومين بهذه المعايير',
                            style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: studentProvider.filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = studentProvider.filteredStudents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryBurgundy.withValues(alpha: 0.1),
                              backgroundImage: (student.photoBase64 != null && student.photoBase64!.isNotEmpty)
                                  ? MemoryImage(base64Decode(student.photoBase64!))
                                  : null,
                              child: (student.photoBase64 == null || student.photoBase64!.isEmpty)
                                  ? const Icon(Icons.person, color: AppTheme.primaryBurgundy, size: 28)
                                  : null,
                            ),
                            title: Text(
                              student.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDarkBurgundy,
                              ),
                            ),
                            subtitle: Text(
                              'المرحلة: ${student.grade}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.badge, color: AppTheme.copticGold, size: 22),
                                  tooltip: 'استخراج الكارنيه',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentBadgeScreen(student: student),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.bar_chart, color: AppTheme.primaryBurgundy, size: 22),
                                  tooltip: 'نسبة الحضور والغياب',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentDetailScreen(student: student),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailScreen(student: student),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
