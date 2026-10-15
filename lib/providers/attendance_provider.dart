import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';

class StudentAttendanceStats {
  final int totalPresent;
  final int totalAbsent;
  final double attendanceRate; // 0..100
  final double absenceRate; // 0..100
  final List<AttendanceRecord> records;

  StudentAttendanceStats({
    required this.totalPresent,
    required this.totalAbsent,
    required this.attendanceRate,
    required this.absenceRate,
    required this.records,
  });
}

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<AttendanceRecord> _records = [];
  bool _isLoading = false;
  String? _lastScannedStudentName;

  List<AttendanceRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get lastScannedStudentName => _lastScannedStudentName;

  AttendanceProvider() {
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await _dbService.getAttendanceRecords();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if student is already marked present today
  bool isPresentToday(String studentId) {
    final now = DateTime.now();
    return _records.any(
      (r) =>
          r.studentId == studentId &&
          r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day &&
          r.status == AttendanceStatus.present,
    );
  }

  /// Records attendance for a student
  Future<bool> recordAttendance({
    required Student student,
    required String recordedBy,
    AttendanceStatus status = AttendanceStatus.present,
    String? note,
    DateTime? date,
  }) async {
    final newRecord = await _dbService.recordAttendance(
      student: student,
      recordedBy: recordedBy,
      status: status,
      note: note,
      date: date,
    );

    // Update local state list
    final index = _records.indexWhere((r) => r.id == newRecord.id);
    if (index != -1) {
      _records[index] = newRecord;
    } else {
      _records.add(newRecord);
    }

    _lastScannedStudentName = student.name;
    notifyListeners();
    return true;
  }

  Future<bool> deleteAttendanceForStudent({
    required String studentId,
    required DateTime date,
  }) async {
    final deleted = await _dbService.deleteAttendanceRecord(
      studentId: studentId,
      date: date,
    );

    if (deleted) {
      _records.removeWhere(
        (r) =>
            r.studentId == studentId &&
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day,
      );
      notifyListeners();
    }

    return deleted;
  }

  /// Calculates statistics for a single student
  StudentAttendanceStats getStatsForStudent(String studentId) {
    final studentRecords = _records
        .where((r) => r.studentId == studentId)
        .toList();
    studentRecords.sort((a, b) => b.date.compareTo(a.date));

    int present = studentRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    int absent = studentRecords
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    int total = present + absent;

    double presentRate = total > 0 ? (present / total) * 100 : 0.0;
    double absentRate = total > 0 ? (absent / total) * 100 : 0.0;

    return StudentAttendanceStats(
      totalPresent: present,
      totalAbsent: absent,
      attendanceRate: presentRate,
      absenceRate: absentRate,
      records: studentRecords,
    );
  }
}
