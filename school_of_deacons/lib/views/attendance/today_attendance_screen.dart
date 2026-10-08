import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';

/// شاشة تعرض كل الحاضرين في اليوم الحالي مع إمكانية مسح أي مخدوم
class TodayAttendanceScreen extends StatelessWidget {
  const TodayAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);

    final today = DateTime.now();
    final todayRecords = attendanceProvider.records.where((r) {
      return r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day &&
          r.status == AttendanceStatus.present;
    }).toList();

    todayRecords.sort((a, b) => a.studentName.compareTo(b.studentName));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حضور اليوم',
              style: GoogleFonts.cairo(color: AppTheme.copticGold, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${today.day}/${today.month}/${today.year}',
              style: GoogleFonts.cairo(color: AppTheme.copticAccentGold, fontSize: 12),
            ),
          ],
        ),
      ),
      body: todayRecords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: AppTheme.primaryBurgundy.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد حضور مسجل اليوم',
                    style: GoogleFonts.cairo(fontSize: 18, color: AppTheme.primaryBurgundy),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // --- شريط الإحصاء ---
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryDarkBurgundy, AppTheme.primaryBurgundy],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.how_to_reg, color: AppTheme.copticGold, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'إجمالي الحاضرين: ${todayRecords.length}',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- قائمة الحاضرين ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todayRecords.length,
                    itemBuilder: (context, index) {
                      final record = todayRecords[index];
                      final student = studentProvider.getStudentById(record.studentId);
                      final photoBase64 = student?.photoBase64;
                      final hasPhoto = photoBase64 != null && photoBase64.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.green.shade200, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              // --- صورة المخدوم ---
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.green.shade100,
                                backgroundImage: hasPhoto
                                    ? MemoryImage(base64Decode(photoBase64))
                                    : null,
                                child: !hasPhoto
                                    ? Icon(Icons.person, color: Colors.green.shade700, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // --- اسم ومرحلة ---
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.studentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      'المرحلة: ${record.grade}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // --- علامة الحضور ---
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 4),

                              // --- زر المسح ---
                              IconButton(
                                tooltip: 'مسح من حضور اليوم',
                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text('تأكيد المسح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                      content: Text(
                                        'هل تريد مسح حضور "${record.studentName}" من اليوم؟',
                                        style: GoogleFonts.cairo(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('إلغاء', style: GoogleFonts.cairo()),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text('مسح', style: GoogleFonts.cairo(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    await Provider.of<AttendanceProvider>(context, listen: false)
                                        .deleteAttendanceForStudent(
                                      studentId: record.studentId,
                                      date: today,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
