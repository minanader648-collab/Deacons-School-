import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/student_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/badge_pdf_service.dart';
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final gradesList = ['الكل', ...settings.grades];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search & Filter Card
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
            const SizedBox(height: 12),

            // Summary & Actions Bar (إضافة + طباعة كل الكارنيهات في PDF واحد)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final countText = Text(
                  'النتائج: ${studentProvider.filteredStudents.length} مخدوم',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBurgundy,
                  ),
                );

                final printAllBtn = ElevatedButton.icon(
                  onPressed: studentProvider.filteredStudents.isEmpty
                      ? null
                      : () {
                          BadgePdfService.printBatchBadges(
                            context: context,
                            students: studentProvider.filteredStudents,
                            settings: settings,
                            servantName: authProvider.currentUser?.fullName,
                            gradeFilter: studentProvider.selectedGradeFilter,
                          );
                        },
                  icon: const Icon(Icons.print, size: 16),
                  label: Text(
                    'طباعة الكارنيهات (A4)',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.copticNavy,
                    foregroundColor: AppTheme.copticGold,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                );

                final addBtn = ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditStudentScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'إضافة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBurgundy,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          countText,
                          addBtn,
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: printAllBtn,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: countText),
                    const SizedBox(width: 8),
                    printAllBtn,
                    const SizedBox(width: 6),
                    addBtn,
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // Students List
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
                          margin: const EdgeInsets.only(bottom: 10),
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
