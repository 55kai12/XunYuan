/// 设置相关 Provider
/// 管理主题模式、隐私锁等用户偏好状态
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_service.dart';

import '../../core/i18n/i18n.dart';
/// SharedPreferences 实例（在 main.dart 中初始化并 override）
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider 未在 main.dart 中初始化'.tr);
});

/// 设置服务
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

/// 主题模式状态
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._service) : super(_service.getThemeMode());

  final SettingsService _service;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _service.setThemeMode(mode);
  }
}

/// 主题模式 Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return ThemeModeNotifier(service);
});

/// 隐私锁状态
class PrivacyLockNotifier extends StateNotifier<bool> {
  PrivacyLockNotifier(this._service) : super(_service.isPrivacyLockEnabled());

  final SettingsService _service;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _service.setPrivacyLockEnabled(enabled);
  }
}

/// 隐私锁 Provider
final privacyLockProvider =
    StateNotifierProvider<PrivacyLockNotifier, bool>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return PrivacyLockNotifier(service);
});

/// 语言模式状态
class LanguageModeNotifier extends StateNotifier<LanguageMode> {
  LanguageModeNotifier(this._service) : super(_service.getLanguageMode());

  final SettingsService _service;

  Future<void> setLanguageMode(LanguageMode mode) async {
    state = mode;
    await _service.setLanguageMode(mode);
  }
}

/// 语言模式 Provider
final languageModeProvider =
    StateNotifierProvider<LanguageModeNotifier, LanguageMode>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return LanguageModeNotifier(service);
});

/// 引导页完成状态
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._service) : super(_service.isOnboardingDone());

  final SettingsService _service;

  Future<void> complete() async {
    state = true;
    await _service.setOnboardingDone();
  }
}

/// 引导页 Provider
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return OnboardingNotifier(service);
});

/// 自动备份开关状态
class AutoBackupNotifier extends StateNotifier<bool> {
  AutoBackupNotifier(this._service) : super(_service.isAutoBackupEnabled());

  final SettingsService _service;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _service.setAutoBackupEnabled(enabled);
  }
}

/// 自动备份 Provider
final autoBackupProvider =
    StateNotifierProvider<AutoBackupNotifier, bool>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return AutoBackupNotifier(service);
});
