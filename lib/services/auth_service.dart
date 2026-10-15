import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/servant_user_model.dart';

class AuthService {
  static const String _localUsersKey = 'local_servants_v1';
  static const String _currentUserKey = 'current_logged_in_servant_v1';

  fb.FirebaseAuth? get _firebaseAuth {
    try {
      return fb.FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth unavailable: $e');
      return null;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('$password:DEACON_AUTH_SALT_2026');
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> _loadUsersMap() async {
    final prefs = await SharedPreferences.getInstance();
    final localUsersRaw = prefs.getString(_localUsersKey) ?? '{}';
    return Map<String, dynamic>.from(json.decode(localUsersRaw));
  }

  Future<void> _saveUsersMap(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localUsersKey, json.encode(users));
  }

  Future<bool> hasAnyUsers() async {
    final users = await _loadUsersMap();
    return users.isNotEmpty;
  }

  Future<bool> hasApprovedAdmin() async {
    final users = await _loadUsersMap();
    return users.values.any((entry) {
      try {
        final userMap = Map<String, dynamic>.from(entry['user']);
        final user = ServantUser.fromMap(userMap, userMap['uid'] ?? '');
        return user.isAdmin && user.isApproved;
      } catch (_) {
        return false;
      }
    });
  }

  Future<ServantUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_currentUserKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final Map<String, dynamic> map = json.decode(jsonStr);
      final user = ServantUser.fromMap(map, map['uid'] ?? '');
      final users = await _loadUsersMap();
      final entry = users[user.email.toLowerCase()];
      if (entry == null) {
        await prefs.remove(_currentUserKey);
        return null;
      }
      final fresh = ServantUser.fromMap(
        Map<String, dynamic>.from(entry['user']),
        entry['user']['uid'] ?? user.uid,
      );
      if (!fresh.isApproved) {
        await prefs.remove(_currentUserKey);
        return null;
      }
      return fresh;
    } catch (_) {
      return null;
    }
  }

  /// أول حساب في النظام = أمين الخدمة (معتمد فوراً).
  /// أي حساب بعده = خادم بانتظار الموافقة.
  Future<ServantUser> registerServant({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _loadUsersMap();

    if (users.containsKey(cleanEmail)) {
      throw Exception('هذا البريد الإلكتروني مسجل بالفعل!');
    }

    final isFirstUser = users.isEmpty;
    final uid = 'srv_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = ServantUser(
      uid: uid,
      email: cleanEmail,
      fullName: fullName.trim(),
      role: isFirstUser ? 'admin' : 'servant',
      approvalStatus: isFirstUser ? 'approved' : 'pending',
    );

    users[cleanEmail] = {
      'user': newUser.toMap(),
      'passwordHash': _hashPassword(password),
    };
    await _saveUsersMap(users);

    final auth = _firebaseAuth;
    if (auth != null) {
      try {
        final creds = await auth
            .createUserWithEmailAndPassword(
              email: cleanEmail,
              password: password,
            )
            .timeout(const Duration(seconds: 8));
        await creds.user?.updateDisplayName(fullName);
        await auth.signOut();
      } catch (e) {
        debugPrint('Firebase register optional: $e');
      }
    }

    if (isFirstUser) {
      await _saveCurrentUserLocally(newUser);
    }

    return newUser;
  }

  Future<ServantUser> loginServant({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _loadUsersMap();

    if (!users.containsKey(cleanEmail)) {
      throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة!');
    }

    final userData = users[cleanEmail];
    final storedHash = userData['passwordHash'];
    if (storedHash != _hashPassword(password)) {
      throw Exception('كلمة المرور غير صحيحة!');
    }

    final user = ServantUser.fromMap(
      Map<String, dynamic>.from(userData['user']),
      userData['user']['uid'] ?? '',
    );

    if (user.isPending) {
      throw Exception(
        'حسابك بانتظار موافقة أمين الخدمة. لا يمكن الدخول حتى يتم القبول.',
      );
    }
    if (user.isRejected) {
      throw Exception('تم رفض طلب التسجيل. تواصل مع أمين الخدمة.');
    }

    await _saveCurrentUserLocally(user);
    return user;
  }

  Future<List<ServantUser>> getPendingServants() async {
    final users = await _loadUsersMap();
    final pending = <ServantUser>[];
    for (final entry in users.values) {
      try {
        final user = ServantUser.fromMap(
          Map<String, dynamic>.from(entry['user']),
          entry['user']['uid'] ?? '',
        );
        if (user.isPending) pending.add(user);
      } catch (_) {}
    }
    pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pending;
  }

  Future<List<ServantUser>> getAllServants() async {
    final users = await _loadUsersMap();
    final list = <ServantUser>[];
    for (final entry in users.values) {
      try {
        list.add(
          ServantUser.fromMap(
            Map<String, dynamic>.from(entry['user']),
            entry['user']['uid'] ?? '',
          ),
        );
      } catch (_) {}
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> setApprovalStatus({
    required String email,
    required String status,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _loadUsersMap();
    if (!users.containsKey(cleanEmail)) {
      throw Exception('الخادم غير موجود');
    }
    final userMap = Map<String, dynamic>.from(users[cleanEmail]['user']);
    userMap['approvalStatus'] = status;
    users[cleanEmail]['user'] = userMap;
    await _saveUsersMap(users);
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth?.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<void> _saveCurrentUserLocally(ServantUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toMap()));
  }
}
