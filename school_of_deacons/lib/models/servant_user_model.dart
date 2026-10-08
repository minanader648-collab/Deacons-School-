import 'dart:convert';

class ServantUser {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'admin' | 'servant'
  final String approvalStatus; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;

  ServantUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.role = 'servant',
    this.approvalStatus = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';
  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';

  ServantUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? role,
    String? approvalStatus,
    DateTime? createdAt,
  }) {
    return ServantUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'approvalStatus': approvalStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServantUser.fromMap(Map<String, dynamic> map, String docId) {
    // Legacy users without approvalStatus are treated as approved
    final legacyStatus = map['approvalStatus'] as String?;
    final role = map['role'] ?? 'servant';
    return ServantUser(
      uid: docId.isNotEmpty ? docId : (map['uid'] ?? ''),
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: role,
      approvalStatus: legacyStatus ??
          (role == 'admin' ? 'approved' : 'approved'),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ServantUser.fromJson(String source, String docId) =>
      ServantUser.fromMap(json.decode(source), docId);
}
