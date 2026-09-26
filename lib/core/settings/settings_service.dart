/// 设置服务
/// 使用 SharedPreferences 持久化用户偏好：主题模式、隐私锁开关
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言模式：跟随系统 / 简体中文 / English
enum LanguageMode { system, zh, en }

/// 设置服务
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyPrivacyLock = 'privacy_lock_enabled';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyLanguage = 'language_mode';
  static const String _keyAutoBackup = 'auto_backup_enabled';
  static const String _keyLastAutoBackup = 'last_auto_backup_at';

  // ==================== 主题模式 ====================

  /// 获取当前主题模式，默认跟随系统
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// 设置主题模式并持久化
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  // ==================== 语言 ====================

  /// 获取语言模式，默认跟随系统
  LanguageMode getLanguageMode() {
    switch (_prefs.getString(_keyLanguage)) {
      case 'zh':
        return LanguageMode.zh;
      case 'en':
        return LanguageMode.en;
      default:
        return LanguageMode.system;
    }
  }

  /// 设置语言模式并持久化
  Future<void> setLanguageMode(LanguageMode mode) async {
    await _prefs.setString(_keyLanguage, mode.name);
  }

  // ==================== 隐私锁 ====================

  /// 隐私锁是否启用，默认关闭
  bool isPrivacyLockEnabled() {
    return _prefs.getBool(_keyPrivacyLock) ?? false;
  }

  /// 设置隐私锁开关并持久化
  Future<void> setPrivacyLockEnabled(bool enabled) async {
    await _prefs.setBool(_keyPrivacyLock, enabled);
  }

  // ==================== 自动备份 ====================

  /// 自动备份是否启用，默认开启（族谱数据宝贵，丢失不可逆）
  bool isAutoBackupEnabled() {
    return _prefs.getBool(_keyAutoBackup) ?? true;
  }

  /// 设置自动备份开关并持久化
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _prefs.setBool(_keyAutoBackup, enabled);
  }

  /// 上次自动备份时间，未备份过返回 null
  DateTime? get lastAutoBackupAt {
    final ms = _prefs.getInt(_keyLastAutoBackup);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 记录自动备份时间
  Future<void> setLastAutoBackupAt(DateTime time) async {
    await _prefs.setInt(_keyLastAutoBackup, time.millisecondsSinceEpoch);
  }

  // ==================== 引导页 ====================

  /// 是否已完成引导页，默认未完成
  bool isOnboardingDone() {
    return _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  /// 标记引导页已完成
  Future<void> setOnboardingDone() async {
    await _prefs.setBool(_keyOnboardingDone, true);
  }
}
