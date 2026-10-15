import 'dart:convert';

class Student {
  final String id;
  final String name;
  final String grade; // السنة الدراسية / المرحلة (مثال: أولى إبتدائي، ثانية إبتدائي)
  final String phone; // رقم التليفون / ولي الأمر
  final String notes; // ملاحظات خاصة (مثال: رتبة الشماس، حفظ ألحان)
  final String? photoBase64; // الصورة الشخصية بصيغة Base64 لتخزينها محلياً وبدون مشاكل شبكة
  final DateTime createdAt;
  final bool isActive;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.phone,
    this.notes = '',
    this.photoBase64,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'phone': phone,
      'notes': notes,
      'photoBase64': photoBase64,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, String docId) {
    return Student(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      grade: map['grade'] ?? '',
      phone: map['phone'] ?? '',
      notes: map['notes'] ?? '',
      photoBase64: map['photoBase64'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory Student.fromJson(String source, String docId) =>
      Student.fromMap(json.decode(source), docId);

  Student copyWith({
    String? id,
    String? name,
    String? grade,
    String? phone,
    String? notes,
    String? photoBase64,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
