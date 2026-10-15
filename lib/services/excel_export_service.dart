import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/church_settings_model.dart';

class ExcelExportService {
  static Future<File?> exportMonthlyReport({
    required ChurchSettings settings,
    required List<Student> students,
    required List<AttendanceRecord> allRecords,
    required int year,
    required int month,
    String? filterGrade,
  }) async {
    final excel = Excel.createExcel();
    final String sheetName = 'تقرير شهر $month-$year';
    final Sheet sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // Filter students by grade if requested
    final targetStudents =
        (filterGrade != null && filterGrade.isNotEmpty && filterGrade != 'الكل')
        ? students.where((s) => s.grade == filterGrade).toList()
        : students;

    targetStudents.sort((a, b) => a.name.compareTo(b.name));

    // Calculate number of weeks in the month (assuming up to 5 weeks)
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Header Title Rows
    sheet.appendRow([TextCellValue(settings.churchName)]);
    sheet.appendRow([
      TextCellValue('${settings.schoolTitle} - كشف حضور شهر $month / $year'),
    ]);
    if (filterGrade != null && filterGrade != 'الكل') {
      sheet.appendRow([TextCellValue('المرحلة: $filterGrade')]);
    }
    sheet.appendRow([TextCellValue('')]); // Blank line

    // Table Headers
    final List<CellValue> headers = [
      TextCellValue('م'),
      TextCellValue('اسم المخدوم'),
      TextCellValue('السنة الدراسية'),
      TextCellValue('الأسبوع 1 (1-7)'),
      TextCellValue('الأسبوع 2 (8-14)'),
      TextCellValue('الأسبوع 3 (15-21)'),
      TextCellValue('الأسبوع 4 (22-28)'),
      TextCellValue('الأسبوع 5 (29-$daysInMonth)'),
      TextCellValue('إجمالي الحضور'),
      TextCellValue('إجمالي الغياب'),
      TextCellValue('نسبة الحضور'),
    ];
    sheet.appendRow(headers);

    // Data Rows
    int index = 1;
    for (var student in targetStudents) {
      // Get attendance records for this student in the target month & year
      final monthRecords = allRecords
          .where(
            (r) =>
                r.studentId == student.id &&
                r.date.year == year &&
                r.date.month == month,
          )
          .toList();

      // Check week attendance (Week 1: days 1-7, Week 2: 8-14, Week 3: 15-21, Week 4: 22-28, Week 5: 29-end)
      bool week1 = monthRecords.any(
        (r) =>
            r.date.day >= 1 &&
            r.date.day <= 7 &&
            r.status == AttendanceStatus.present,
      );
      bool week2 = monthRecords.any(
        (r) =>
            r.date.day >= 8 &&
            r.date.day <= 14 &&
            r.status == AttendanceStatus.present,
      );
      bool week3 = monthRecords.any(
        (r) =>
            r.date.day >= 15 &&
            r.date.day <= 21 &&
            r.status == AttendanceStatus.present,
      );
      bool week4 = monthRecords.any(
        (r) =>
            r.date.day >= 22 &&
            r.date.day <= 28 &&
            r.status == AttendanceStatus.present,
      );
      bool week5 = monthRecords.any(
        (r) => r.date.day >= 29 && r.status == AttendanceStatus.present,
      );

      int totalPresent = [
        week1,
        week2,
        week3,
        week4,
        week5,
      ].where((w) => w).length;
      int totalPossibleWeeks = (daysInMonth >= 29) ? 5 : 4;
      int totalAbsent = totalPossibleWeeks - totalPresent;
      if (totalAbsent < 0) totalAbsent = 0;

      double attendanceRate = (totalPossibleWeeks > 0)
          ? ((totalPresent / totalPossibleWeeks) * 100)
          : 0.0;

      sheet.appendRow([
        IntCellValue(index++),
        TextCellValue(student.name),
        TextCellValue(student.grade),
        TextCellValue(week1 ? 'حاضر ✓' : 'غائب ✗'),
        TextCellValue(week2 ? 'حاضر ✓' : 'غائب ✗'),
        TextCellValue(week3 ? 'حاضر ✓' : 'غائب ✗'),
        TextCellValue(week4 ? 'حاضر ✓' : 'غائب ✗'),
        TextCellValue(
          (daysInMonth >= 29) ? (week5 ? 'حاضر ✓' : 'غائب ✗') : '-',
        ),
        IntCellValue(totalPresent),
        IntCellValue(totalAbsent),
        TextCellValue('${attendanceRate.toStringAsFixed(1)}%'),
      ]);
    }

    // Save File
    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final outputDir = await getApplicationDocumentsDirectory();
    final fileName = 'تقرير_حضور_شماسة_${month}_$year.xlsx';
    final filePath = '${outputDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    return file;
  }

  static Future<void> shareExcelFile(File file) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles([
      xFile,
    ], text: 'تقرير كشف الحضور والغياب لخدمة مدرسة الشمامسة');
  }
}
