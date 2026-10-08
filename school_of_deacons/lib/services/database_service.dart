import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/church_settings_model.dart';

class DatabaseService {
  FirebaseFirestore? _firestore;
  static const Duration _firestoreTimeout = Duration(seconds: 4);

  FirebaseFirestore? get _safeFirestore {
    try {
      return _firestore ??= FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore unavailable: $e');
      return null;
    }
  }

  static const String _studentsLocalKey = 'deacons_students_list_v1';
  static const String _attendanceLocalKey = 'deacons_attendance_list_v1';
  static const String _settingsLocalKey = 'deacons_church_settings_v1';
  final _uuid = const Uuid();

  Future<T?> _withTimeout<T>(Future<T> future) async {
    try {
      return await future.timeout(_firestoreTimeout);
    } catch (e) {
      debugPrint('Firestore timeout/error: $e');
      return null;
    }
  }

  // --- Church Settings ---
  Future<ChurchSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsLocalKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return ChurchSettings.fromJson(jsonStr);
      } catch (_) {}
    }
    return ChurchSettings();
  }

  Future<void> saveSettings(ChurchSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsLocalKey, settings.toJson());

    final db = _safeFirestore;
    if (db == null) return;
    await _withTimeout(
      db.collection('settings').doc('church').set(settings.toMap()),
    );
  }

  // --- Students Management ---
  Future<List<Student>> _loadStudentsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_studentsLocalKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => Student.fromMap(e, e['id'] ?? '')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Student>> getStudents() async {
    var students = await _loadStudentsLocal();
    final db = _safeFirestore;
    if (db == null) return students;

    // If we already have local data, don't block the UI on Firestore.
    if (students.isNotEmpty) {
      _syncStudentsFromRemote(db);
      return students;
    }

    final snapshot = await _withTimeout(db.collection('students').get());
    if (snapshot != null && snapshot.docs.isNotEmpty) {
      students = snapshot.docs
          .map((doc) => Student.fromMap(doc.data(), doc.id))
          .toList();
      await _saveStudentsLocally(students);
    }

    return students;
  }

  Future<void> _syncStudentsFromRemote(FirebaseFirestore db) async {
    final snapshot = await _withTimeout(db.collection('students').get());
    if (snapshot != null && snapshot.docs.isNotEmpty) {
      final students = snapshot.docs
          .map((doc) => Student.fromMap(doc.data(), doc.id))
          .toList();
      await _saveStudentsLocally(students);
    }
  }

  Future<Student> addStudent(Student student) async {
    final id = student.id.isEmpty ? _uuid.v4() : student.id;
    final newStudent = student.copyWith(id: id);

    final students = await _loadStudentsLocal();
    students.add(newStudent);
    await _saveStudentsLocally(students);

    final db = _safeFirestore;
    if (db != null) {
      await _withTimeout(db.collection('students').doc(id).set(newStudent.toMap()));
    }

    return newStudent;
  }

  Future<void> updateStudent(Student student) async {
    final students = await _loadStudentsLocal();
    final index = students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      students[index] = student;
      await _saveStudentsLocally(students);
    }

    final db = _safeFirestore;
    if (db != null) {
      await _withTimeout(
        db.collection('students').doc(student.id).update(student.toMap()),
      );
    }
  }

  Future<void> deleteStudent(String studentId) async {
    final students = await _loadStudentsLocal();
    students.removeWhere((s) => s.id == studentId);
    await _saveStudentsLocally(students);

    final db = _safeFirestore;
    if (db != null) {
      await _withTimeout(db.collection('students').doc(studentId).delete());
    }
  }

  Future<void> _saveStudentsLocally(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final list = students.map((s) => s.toMap()).toList();
    await prefs.setString(_studentsLocalKey, json.encode(list));
  }

  // --- Attendance Management ---
  Future<List<AttendanceRecord>> _loadAttendanceLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_attendanceLocalKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List list = json.decode(jsonStr);
      return list
          .map((e) => AttendanceRecord.fromMap(e, e['id'] ?? ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    var records = await _loadAttendanceLocal();
    final db = _safeFirestore;
    if (db == null) return records;

    if (records.isNotEmpty) {
      _syncAttendanceFromRemote(db);
      return records;
    }

    final snapshot = await _withTimeout(db.collection('attendance').get());
    if (snapshot != null && snapshot.docs.isNotEmpty) {
      records = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
      await _saveAttendanceLocally(records);
    }

    return records;
  }

  Future<void> _syncAttendanceFromRemote(FirebaseFirestore db) async {
    final snapshot = await _withTimeout(db.collection('attendance').get());
    if (snapshot != null && snapshot.docs.isNotEmpty) {
      final records = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
      await _saveAttendanceLocally(records);
    }
  }

  Future<AttendanceRecord> recordAttendance({
    required Student student,
    required String recordedBy,
    AttendanceStatus status = AttendanceStatus.present,
    String? note,
    DateTime? date,
  }) async {
    final recordDate = date ?? DateTime.now();
    final recordId =
        '${student.id}_${recordDate.year}_${recordDate.month}_${recordDate.day}';

    final records = await _loadAttendanceLocal();

    final existingIndex = records.indexWhere(
      (r) =>
          r.studentId == student.id &&
          r.date.year == recordDate.year &&
          r.date.month == recordDate.month &&
          r.date.day == recordDate.day,
    );

    final record = AttendanceRecord(
      id: recordId,
      studentId: student.id,
      studentName: student.name,
      grade: student.grade,
      date: recordDate,
      status: status,
      recordedBy: recordedBy,
      note: note,
    );

    if (existingIndex != -1) {
      records[existingIndex] = record;
    } else {
      records.add(record);
    }

    await _saveAttendanceLocally(records);

    final db = _safeFirestore;
    if (db != null) {
      await _withTimeout(
        db.collection('attendance').doc(recordId).set(record.toMap()),
      );
    }

    return record;
  }

  Future<bool> deleteAttendanceRecord({
    required String studentId,
    required DateTime date,
  }) async {
    final records = await _loadAttendanceLocal();
    final targetIndex = records.indexWhere(
      (r) =>
          r.studentId == studentId &&
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day,
    );

    if (targetIndex == -1) {
      return false;
    }

    final recordId = records[targetIndex].id;
    records.removeAt(targetIndex);
    await _saveAttendanceLocally(records);

    final db = _safeFirestore;
    if (db != null) {
      await _withTimeout(db.collection('attendance').doc(recordId).delete());
    }

    return true;
  }

  Future<void> _saveAttendanceLocally(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final list = records.map((r) => r.toMap()).toList();
    await prefs.setString(_attendanceLocalKey, json.encode(list));
  }
}
