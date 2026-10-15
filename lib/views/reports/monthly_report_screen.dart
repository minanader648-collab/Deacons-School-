import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/excel_export_service.dart';
import '../../theme/app_theme.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedGrade = 'الكل';
  bool _isGenerating = false;
  File? _exportedFile;

  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _years = [2024, 2025, 2026, 2027, 2028];

  void _exportExcel() async {
    setState(() {
      _isGenerating = true;
      _exportedFile = null;
    });

    final settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).settings;
    final students = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).students;
    final records = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    ).records;

    final file = await ExcelExportService.exportMonthlyReport(
      settings: settings,
      students: students,
      allRecords: records,
      year: _selectedYear,
      month: _selectedMonth,
      filterGrade: _selectedGrade,
    );

    setState(() {
      _isGenerating = false;
      _exportedFile = file;
    });

    if (file != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم استخراج شيت الإكسيل بنجاح: ${file.path.split(Platform.pathSeparator).last}',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green.shade700,
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => ExcelExportService.shareExcelFile(file),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final students = Provider.of<StudentProvider>(context).students;
    final records = Provider.of<AttendanceProvider>(context).records;
    final gradesList = ['الكل', ...settings.grades];

    final filteredStudents = students
        .where((s) => _selectedGrade == 'الكل' || s.grade == _selectedGrade)
        .toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Configuration Card
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: AppTheme.copticGold,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.table_chart,
                              color: AppTheme.primaryBurgundy,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تخصيص شيت الإكسيل الشهري',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBurgundy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // استجابة للشاشات الصغيرة لتجنب الـ Overflow
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 460;

                            final monthWidget = DropdownButtonFormField<int>(
                              initialValue: _selectedMonth,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'الشهر',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.calendar_month,
                                  color: AppTheme.primaryBurgundy,
                                  size: 20,
                                ),
                              ),
                              items: _months.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    'شهر $m',
                                    style: GoogleFonts.cairo(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedMonth = val!),
                            );

                            final yearWidget = DropdownButtonFormField<int>(
                              initialValue: _selectedYear,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'السنة',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.event,
                                  color: AppTheme.primaryBurgundy,
                                  size: 20,
                                ),
                              ),
                              items: _years.map((y) {
                                return DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    '$y',
                                    style: GoogleFonts.cairo(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedYear = val!),
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  monthWidget,
                                  const SizedBox(height: 12),
                                  yearWidget,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: monthWidget),
                                const SizedBox(width: 12),
                                Expanded(child: yearWidget),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Grade Selection
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGrade,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'تصفية حسب المرحلة الدراسية',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.school,
                              color: AppTheme.primaryBurgundy,
                              size: 20,
                            ),
                          ),
                          items: gradesList.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(
                                g,
                                style: GoogleFonts.cairo(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedGrade = val!),
                        ),
                        const SizedBox(height: 18),

                        // Generate Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _exportExcel,
                            icon: const Icon(Icons.download, size: 22),
                            label: _isGenerating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'استخراج شيت الإكسيل الشهري',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBurgundy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),

                        if (_exportedFile != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  ExcelExportService.shareExcelFile(
                                    _exportedFile!,
                                  ),
                              icon: const Icon(
                                Icons.share,
                                color: AppTheme.primaryBurgundy,
                                size: 20,
                              ),
                              label: Text(
                                'مشاركة شيت الإكسيل المستخرج',
                                style: GoogleFonts.cairo(
                                  color: AppTheme.primaryBurgundy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppTheme.primaryBurgundy,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Live Monthly Preview Matrix Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'معاينة جدول الأسابيع (شهر $_selectedMonth - $_selectedYear)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBurgundy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBurgundy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filteredStudents.length} مخدوم',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBurgundy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                filteredStudents.isEmpty
                    ? Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'لا يوجد مخدومين مسجلين في هذه المرحلة',
                              style: GoogleFonts.cairo(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 14,
                            horizontalMargin: 12,
                            headingRowHeight: 44,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 46,
                            headingRowColor: WidgetStateProperty.all(
                              AppTheme.primaryBurgundy,
                            ),
                            columns: [
                              DataColumn(
                                label: Text(
                                  'م',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'اسم المخدوم',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'المرحلة',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'أسبوع 1',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'أسبوع 2',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'أسبوع 3',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'أسبوع 4',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'أسبوع 5',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rows: filteredStudents.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final student = entry.value;

                              final monthRecords = records
                                  .where(
                                    (r) =>
                                        r.studentId == student.id &&
                                        r.date.year == _selectedYear &&
                                        r.date.month == _selectedMonth,
                                  )
                                  .toList();

                              bool w1 = monthRecords.any(
                                (r) =>
                                    r.date.day >= 1 &&
                                    r.date.day <= 7 &&
                                    r.status.name == 'present',
                              );
                              bool w2 = monthRecords.any(
                                (r) =>
                                    r.date.day >= 8 &&
                                    r.date.day <= 14 &&
                                    r.status.name == 'present',
                              );
                              bool w3 = monthRecords.any(
                                (r) =>
                                    r.date.day >= 15 &&
                                    r.date.day <= 21 &&
                                    r.status.name == 'present',
                              );
                              bool w4 = monthRecords.any(
                                (r) =>
                                    r.date.day >= 22 &&
                                    r.date.day <= 28 &&
                                    r.status.name == 'present',
                              );
                              bool w5 = monthRecords.any(
                                (r) =>
                                    r.date.day >= 29 &&
                                    r.status.name == 'present',
                              );

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text('$idx', style: GoogleFonts.cairo()),
                                  ),
                                  DataCell(
                                    Text(
                                      student.name,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student.grade,
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ),
                                  DataCell(
                                    Icon(
                                      w1 ? Icons.check_circle : Icons.close,
                                      size: 18,
                                      color: w1
                                          ? Colors.green
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                  DataCell(
                                    Icon(
                                      w2 ? Icons.check_circle : Icons.close,
                                      size: 18,
                                      color: w2
                                          ? Colors.green
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                  DataCell(
                                    Icon(
                                      w3 ? Icons.check_circle : Icons.close,
                                      size: 18,
                                      color: w3
                                          ? Colors.green
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                  DataCell(
                                    Icon(
                                      w4 ? Icons.check_circle : Icons.close,
                                      size: 18,
                                      color: w4
                                          ? Colors.green
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                  DataCell(
                                    Icon(
                                      w5 ? Icons.check_circle : Icons.close,
                                      size: 18,
                                      color: w5
                                          ? Colors.green
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
