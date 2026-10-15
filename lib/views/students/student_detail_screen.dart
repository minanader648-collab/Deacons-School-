import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/student_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import 'add_edit_student_screen.dart';
import 'student_badge_screen.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final stats = attendanceProvider.getStatsForStudent(student.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ملف إحصائيات المخدوم',
          style: GoogleFonts.cairo(color: AppTheme.copticGold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined, color: AppTheme.copticGold),
            tooltip: 'معاينة الكارنيه',
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
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'تعديل البيانات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditStudentScreen(student: student),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'حذف المخدوم',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  content: Text('هل أنت تأكد أنك تريد حذف المخدوم "${student.name}"؟', style: GoogleFonts.cairo()),
                  actions: [
                    TextButton(
                      child: Text('إلغاء', style: GoogleFonts.cairo()),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
                      onPressed: () async {
                        await Provider.of<StudentProvider>(context, listen: false).deleteStudent(student.id);
                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Return to list
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppTheme.copticGold, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppTheme.primaryBurgundy.withValues(alpha: 0.15),
                          backgroundImage: (student.photoBase64 != null && student.photoBase64!.isNotEmpty)
                              ? MemoryImage(base64Decode(student.photoBase64!))
                              : null,
                          child: (student.photoBase64 == null || student.photoBase64!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: AppTheme.primaryBurgundy)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDarkBurgundy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'السنة الدراسية: ${student.grade}',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: AppTheme.primaryBurgundy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (student.phone.isNotEmpty)
                                Text(
                                  'رقم الهاتف: ${student.phone}',
                                  style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade700),
                                ),
                              if (student.notes.isNotEmpty)
                                Text(
                                  'ملاحظات: ${student.notes}',
                                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'إحصائيات الحضور والغياب (%)',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBurgundy,
                  ),
                ),
                const SizedBox(height: 14),

                // Statistics Grid (Requirement 3)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.4 : 1.15,
                  children: [
                    _buildStatBox(
                      title: 'مرات الحضور',
                      value: '${stats.totalPresent}',
                      unit: 'يوم',
                      color: Colors.green.shade700,
                      icon: Icons.check_circle_outline,
                    ),
                    _buildStatBox(
                      title: 'مرات الغياب',
                      value: '${stats.totalAbsent}',
                      unit: 'يوم',
                      color: Colors.red.shade700,
                      icon: Icons.highlight_off,
                    ),
                    _buildStatBox(
                      title: 'نسبة الحضور',
                      value: '${stats.attendanceRate.toStringAsFixed(1)}%',
                      unit: 'مئوية',
                      color: AppTheme.primaryBurgundy,
                      icon: Icons.pie_chart,
                    ),
                    _buildStatBox(
                      title: 'نسبة الغياب',
                      value: '${stats.absenceRate.toStringAsFixed(1)}%',
                      unit: 'مئوية',
                      color: Colors.orange.shade800,
                      icon: Icons.bar_chart,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Attendance Log History
                Text(
                  'كشف التواريخ المسجلة',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBurgundy,
                  ),
                ),
                const SizedBox(height: 12),

                stats.records.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'لا توجد سجلات حضور مسجلة لهذا المخدوم حتى الآن',
                              style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.records.length,
                        itemBuilder: (context, index) {
                          final record = stats.records[index];
                          final isPresent = record.status.name == 'present';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(
                                  isPresent ? Icons.check : Icons.close,
                                  color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                              title: Text(
                                '${record.date.year}/${record.date.month}/${record.date.day}',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'الوقت: ${record.date.hour}:${record.date.minute.toString().padLeft(2, '0')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                              trailing: Text(
                                isPresent ? 'حاضر' : 'غائب',
                                style: GoogleFonts.cairo(
                                  color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
