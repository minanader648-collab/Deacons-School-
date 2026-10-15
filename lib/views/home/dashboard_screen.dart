import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    final totalStudents = studentProvider.students.length;
    final today = DateTime.now();

    final todayPresentCount = attendanceProvider.records.where((r) =>
        r.date.year == today.year &&
        r.date.month == today.month &&
        r.date.day == today.day &&
        r.status.name == 'present').length;

    final todayAbsentCount = totalStudents > todayPresentCount ? totalStudents - todayPresentCount : 0;
    final todayAttendanceRate = totalStudents > 0
        ? ((todayPresentCount / totalStudents) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coptic Welcome Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDarkBurgundy, AppTheme.primaryBurgundy],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBurgundy.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.churchName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppTheme.copticAccentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.schoolTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'مرحباً بك في نظام إدارة غياب المخدومين وإصدار الكارنيهات الذكية',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.copticGold,
                    child: Icon(Icons.church_rounded, size: 32, color: AppTheme.primaryDarkBurgundy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'ملخص إحصائيات اليوم',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBurgundy,
              ),
            ),
            const SizedBox(height: 14),

            // Metric Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.5 : 1.15,
                  children: [
                    _buildStatCard(
                      title: 'إجمالي المخدومين',
                      value: '$totalStudents',
                      subtitle: 'شمامسة مسجلين',
                      icon: Icons.people_alt,
                      color: AppTheme.primaryBurgundy,
                    ),
                    _buildStatCard(
                      title: 'حضور اليوم',
                      value: '$todayPresentCount',
                      subtitle: 'مخدوم حاضر',
                      icon: Icons.check_circle,
                      color: Colors.green.shade700,
                    ),
                    _buildStatCard(
                      title: 'غياب اليوم',
                      value: '$todayAbsentCount',
                      subtitle: 'مخدوم غائب',
                      icon: Icons.cancel,
                      color: Colors.red.shade700,
                    ),
                    _buildStatCard(
                      title: 'نسبة الحضور',
                      value: '$todayAttendanceRate%',
                      subtitle: 'إجمالي اليوم',
                      icon: Icons.pie_chart,
                      color: AppTheme.copticGold,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Recent Scanned Attendance List
            Row(
              children: [
                Expanded(
                  child: Text(
                    'سجل الحضور الأخير',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBurgundy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${today.day}/${today.month}/${today.year}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.copticGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            attendanceProvider.records.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_scanner, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'لم يتم تسجيل غياب أو حضور اليوم حتى الآن',
                              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendanceProvider.records.length > 5
                        ? 5
                        : attendanceProvider.records.length,
                    itemBuilder: (context, index) {
                      final record = attendanceProvider.records.reversed.toList()[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: record.status.name == 'present'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              record.status.name == 'present' ? Icons.check : Icons.close,
                              color: record.status.name == 'present'
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          title: Text(
                            record.studentName,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'المرحلة: ${record.grade} • بواسطة الخادم: ${record.recordedBy}',
                            style: GoogleFonts.cairo(fontSize: 13),
                          ),
                          trailing: Text(
                            '${record.date.hour}:${record.date.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBurgundy,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
