import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/attendance_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ManualAttendanceScreen extends StatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'كشف الحضور والغياب اليدوي',
          style: GoogleFonts.cairo(color: AppTheme.copticGold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Selector Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'التاريخ: ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
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
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text('تغيير', style: GoogleFonts.cairo(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: studentProvider.students.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد مخدومين مسجلين',
                        style: GoogleFonts.cairo(),
                      ),
                    )
                  : ListView.builder(
                      itemCount: studentProvider.students.length,
                      itemBuilder: (context, index) {
                        final student = studentProvider.students[index];
                        final record = attendanceProvider.records.isNotEmpty
                            ? attendanceProvider.records.firstWhere(
                                (r) =>
                                    r.studentId == student.id &&
                                    r.date.year == _selectedDate.year &&
                                    r.date.month == _selectedDate.month &&
                                    r.date.day == _selectedDate.day,
                                orElse: () => AttendanceRecord(
                                  id: '',
                                  studentId: '',
                                  studentName: '',
                                  grade: '',
                                  date: _selectedDate,
                                  recordedBy: '',
                                ),
                              )
                            : null;
                        final isPresent =
                            record != null &&
                            record.studentId.isNotEmpty &&
                            record.status == AttendanceStatus.present;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'المرحلة: ${student.grade}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          color: AppTheme.primaryDarkBurgundy
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: isPresent,
                                      activeThumbColor: Colors.green,
                                      onChanged: (val) async {
                                        final servantName =
                                            authProvider
                                                .currentUser
                                                ?.fullName ??
                                            'الخادم';
                                        await attendanceProvider
                                            .recordAttendance(
                                              student: student,
                                              recordedBy: servantName,
                                              date: _selectedDate,
                                              status: val
                                                  ? AttendanceStatus.present
                                                  : AttendanceStatus.absent,
                                            );
                                      },
                                    ),
                                    if (record != null)
                                      IconButton(
                                        tooltip: 'مسح هذا اليوم',
                                        icon: const Icon(
                                          Icons.delete_forever_rounded,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await attendanceProvider
                                              .deleteAttendanceForStudent(
                                                studentId: student.id,
                                                date: _selectedDate,
                                              );
                                        },
                                      ),
                                  ],
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
      ),
    );
  }
}
