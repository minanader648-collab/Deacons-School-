import 'package:flutter/material.dart';
import '../models/church_settings_model.dart';
import '../services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  ChurchSettings _settings = ChurchSettings();
  bool _isLoading = true;

  ChurchSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _dbService.getSettings();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings({
    required String churchName,
    required String schoolTitle,
    required String deaconRankTitle,
    required List<String> grades,
    String? logoBase64,
  }) async {
    _settings = _settings.copyWith(
      churchName: churchName,
      schoolTitle: schoolTitle,
      deaconRankTitle: deaconRankTitle,
      grades: grades,
      logoBase64: logoBase64,
    );
    await _dbService.saveSettings(_settings);
    notifyListeners();
  }
}
