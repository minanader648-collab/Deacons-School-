import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_of_deacons/models/attendance_model.dart';
import 'package:school_of_deacons/models/servant_user_model.dart';
import 'package:school_of_deacons/models/student_model.dart';
import 'package:school_of_deacons/providers/attendance_provider.dart';
import 'package:school_of_deacons/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('خدمة مدرسة الشمامسة'))),
    );
    expect(find.text('خدمة مدرسة الشمامسة'), findsOneWidget);
  });

  test(
    'AttendanceProvider can delete a recorded absence for a specific student and date',
    () async {
      final provider = AttendanceProvider();
      final date = DateTime(2026, 10, 6);
      final student = Student(
        id: 'student-1',
        name: 'أحمد محمد',
        grade: 'الثالثة',
        phone: '01000000000',
      );

      await provider.recordAttendance(
        student: student,
        recordedBy: 'الخادم',
        date: date,
        status: AttendanceStatus.absent,
      );

      expect(
        provider.records.any(
          (r) => r.studentId == student.id && r.date.day == date.day,
        ),
        isTrue,
      );

      final deleted = await provider.deleteAttendanceForStudent(
        studentId: student.id,
        date: date,
      );

      expect(deleted, isTrue);
      expect(
        provider.records.any(
          (r) => r.studentId == student.id && r.date.day == date.day,
        ),
        isFalse,
      );
    },
  );

  test('AuthService excludes the admin from servant lists', () async {
    final admin = ServantUser(
      uid: 'admin-1',
      email: 'admin@example.com',
      fullName: 'أمين الخدمة',
      role: 'admin',
      approvalStatus: 'approved',
    );

    final servant = ServantUser(
      uid: 'servant-1',
      email: 'servant@example.com',
      fullName: 'خادم',
      role: 'servant',
      approvalStatus: 'approved',
    );

    final pending = ServantUser(
      uid: 'servant-pending',
      email: 'pending@example.com',
      fullName: 'خادم جديد',
      role: 'servant',
      approvalStatus: 'pending',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'local_servants_v1',
      jsonEncode({
        admin.email: {'user': admin.toMap(), 'passwordHash': 'hash'},
        servant.email: {'user': servant.toMap(), 'passwordHash': 'hash'},
        pending.email: {'user': pending.toMap(), 'passwordHash': 'hash'},
      }),
    );

    final authService = AuthService();
    final allServants = await authService.getAllServants();
    final pendingServants = await authService.getPendingServants();

    expect(allServants.any((user) => user.email == admin.email), isFalse);
    expect(allServants.any((user) => user.email == servant.email), isTrue);
    expect(pendingServants.any((user) => user.email == pending.email), isTrue);
    expect(pendingServants.any((user) => user.email == admin.email), isFalse);
  });

  test('AuthService safely ignores corrupted saved user data', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_servants_v1', '{not-valid-json');

    final authService = AuthService();

    expect(await authService.hasAnyUsers(), isFalse);
    expect(await authService.getAllServants(), isEmpty);
    expect(await authService.getPendingServants(), isEmpty);
  });
}
