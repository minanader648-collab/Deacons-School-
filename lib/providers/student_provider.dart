import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';

class StudentProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Student> _students = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedGradeFilter = 'الكل';

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedGradeFilter => _selectedGradeFilter;

  /// Filtered student list based on search term and selected grade
  List<Student> get filteredStudents {
    return _students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.phone.contains(_searchQuery);
      final matchesGrade = _selectedGradeFilter == 'الكل' || s.grade == _selectedGradeFilter;
      return matchesSearch && matchesGrade;
    }).toList();
  }

  StudentProvider() {
    loadStudents();
  }

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _students = await _dbService.getStudents();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setGradeFilter(String grade) {
    _selectedGradeFilter = grade;
    notifyListeners();
  }

  Future<Student> addStudent(Student student) async {
    final newStudent = await _dbService.addStudent(student);
    _students.add(newStudent);
    notifyListeners();
    return newStudent;
  }

  Future<void> updateStudent(Student student) async {
    await _dbService.updateStudent(student);
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String id) async {
    await _dbService.deleteStudent(id);
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Student? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
