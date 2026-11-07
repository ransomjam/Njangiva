import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight preferences and local cache service backed by SharedPreferences.
class LocalCacheService {
  LocalCacheService([this._prefs]);

  SharedPreferences? _prefs;

  static const String _onboardingCompletedKey = 'njangisave.onboarding_done';
  static const String _hideBalancesKey = 'njangisave.hide_balances';
  static const String _demoModeKey = 'njangisave.demo_mode';
  static const String _notificationsEnabledKey = 'njangisave.notifications_on';
  static const String _biometricLockKey = 'njangisave.biometric_lock';
  static const String _cachedGoalsKey = 'njangisave.cached_goals';
  static const String _cachedTransactionsKey = 'njangisave.cached_transactions';

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  Future<bool> getHideBalances() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_hideBalancesKey) ?? false;
  }

  Future<void> setHideBalances(bool hide) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_hideBalancesKey, hide);
  }

  Future<bool> getDemoMode() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_demoModeKey) ?? true;
  }

  Future<void> setDemoMode(bool isDemo) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_demoModeKey, isDemo);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> getBiometricLockEnabled() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_biometricLockKey) ?? false;
  }

  Future<void> setBiometricLockEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_biometricLockKey, enabled);
  }

  Future<void> cacheJsonList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>?> readCachedJsonList(String key) async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  String get cachedGoalsKey => _cachedGoalsKey;
  String get cachedTransactionsKey => _cachedTransactionsKey;
}

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});
