import 'dart:convert';

enum AttendanceStatus { present, absent, excused }

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String grade;
  final DateTime date;
  final AttendanceStatus status;
  final String recordedBy; // اسم أو معرف الخادم الذي سجل الحضور
  final String? note;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.date,
    this.status = AttendanceStatus.present,
    required this.recordedBy,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'grade': grade,
      'date': date.toIso8601String(),
      'status': status.name,
      'recordedBy': recordedBy,
      'note': note,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceRecord(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      grade: map['grade'] ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] != null
          ? AttendanceStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => AttendanceStatus.present,
            )
          : AttendanceStatus.present,
      recordedBy: map['recordedBy'] ?? 'خادم مجهول',
      note: map['note'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceRecord.fromJson(String source, String docId) =>
      AttendanceRecord.fromMap(json.decode(source), docId);
}
