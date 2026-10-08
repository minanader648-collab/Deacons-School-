import 'package:flutter/material.dart';
import '../models/servant_user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  ServantUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  List<ServantUser> _pendingServants = [];
  List<ServantUser> _allServants = [];
  bool _needsAdminSetup = false;

  ServantUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isApproved;
  bool get isAdmin => _currentUser?.isAdmin == true;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ServantUser> get pendingServants => _pendingServants;
  List<ServantUser> get allServants => _allServants;
  int get pendingCount => _pendingServants.length;
  bool get needsAdminSetup => _needsAdminSetup;

  AuthProvider() {
    initSession();
  }

  Future<void> initSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _needsAdminSetup = !(await _authService.hasAnyUsers());
      _currentUser = await _authService.getCurrentUser();
      if (isAdmin) {
        await refreshServantsList();
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.loginServant(
        email: email,
        password: password,
      );
      _needsAdminSetup = false;
      if (isAdmin) {
        await refreshServantsList();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// يرجع true عند النجاح. لو أول حساب = أمين خدمة ويدخل تلقائياً.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerServant(
        email: email,
        password: password,
        fullName: fullName,
      );
      _needsAdminSetup = false;
      if (user.isApproved && user.isAdmin) {
        _currentUser = user;
        await refreshServantsList();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshServantsList() async {
    try {
      _pendingServants = await _authService.getPendingServants();
      _allServants = await _authService.getAllServants();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> approveServant(String email) async {
    try {
      await _authService.setApprovalStatus(email: email, status: 'approved');
      await refreshServantsList();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectServant(String email) async {
    try {
      await _authService.setApprovalStatus(email: email, status: 'rejected');
      await refreshServantsList();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _pendingServants = [];
    _allServants = [];
    _needsAdminSetup = !(await _authService.hasAnyUsers());
    notifyListeners();
  }
}
