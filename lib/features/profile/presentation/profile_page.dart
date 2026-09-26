/// 我的页（设置与个人中心）
/// 深色模式切换、语言切换、隐私锁、备份恢复、关于寻渊
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/settings/settings_service.dart';

/// 我的页
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final privacyLockEnabled = ref.watch(privacyLockProvider);
    final languageMode = ref.watch(languageModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('我的'.tr),
      ),
      body: ListView(
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 8),
          _buildSectionTitle('数据管理'.tr),
          _buildMenuItem(
            icon: Icons.photo_library_outlined,
            title: '家族相册'.tr,
            subtitle: '浏览所有家族成员照片'.tr,
            onTap: () => context.push('/gallery'),
          ),
          _buildMenuItem(
            icon: Icons.backup_outlined,
            title: '备份与恢复'.tr,
            subtitle: '导出 JSON 备份，从备份恢复'.tr,
            onTap: () => context.push('/backup'),
          ),
          _buildMenuItem(
            icon: Icons.delete_outline,
            title: '数据清理'.tr,
            subtitle: '清除所有数据（不可恢复）'.tr,
            onTap: () => context.push('/backup'),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle('偏好设置'.tr),
          _buildMenuItem(
            icon: Icons.dark_mode_outlined,
            title: '深色模式'.tr,
            subtitle: _themeModeText(themeMode),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showThemeModeDialog(context, ref),
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: '隐私锁'.tr,
            subtitle: '应用启动时需要指纹或密码验证'.tr,
            trailing: Switch(
              value: privacyLockEnabled,
              activeColor: AppColors.inkGreen,
              onChanged: (value) => _togglePrivacyLock(ref, value),
            ),
            onTap: () => _togglePrivacyLock(ref, !privacyLockEnabled),
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: '语言'.tr,
            subtitle: _languageModeText(languageMode),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showLanguageDialog(context, ref),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle('关于'.tr),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: '关于寻渊'.tr,
            subtitle: '版本 ${AppConstants.version} · ${AppConstants.slogan}'.tr,
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.version}\n'
              '${AppConstants.appNameEn} · ${AppConstants.packageName}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey : AppColors.inkGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _themeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统'.tr;
      case ThemeMode.light:
        return '浅色'.tr;
      case ThemeMode.dark:
        return '深色'.tr;
    }
  }

  String _languageModeText(LanguageMode mode) {
    switch (mode) {
      case LanguageMode.system:
        return '跟随系统'.tr;
      case LanguageMode.zh:
        return '简体中文'.tr;
      case LanguageMode.en:
        return 'English';
    }
  }

  /// 显示语言选择对话框
  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('语言'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              ref,
              icon: Icons.language,
              title: '跟随系统'.tr,
              mode: LanguageMode.system,
            ),
            _buildLanguageOption(
              context,
              ref,
              icon: Icons.translate,
              title: '简体中文'.tr,
              mode: LanguageMode.zh,
            ),
            _buildLanguageOption(
              context,
              ref,
              icon: Icons.abc,
              title: 'English',
              mode: LanguageMode.en,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required LanguageMode mode,
  }) {
    final currentMode = ref.watch(languageModeProvider);
    final isSelected = currentMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.inkGreen : null),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.inkGreen)
          : null,
      onTap: () {
        ref.read(languageModeProvider.notifier).setLanguageMode(mode);
        Navigator.pop(context);
      },
    );
  }

  /// 显示主题模式选择对话框
  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('深色模式'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ref,
              icon: Icons.brightness_auto,
              title: '跟随系统'.tr,
              mode: ThemeMode.system,
            ),
            _buildThemeOption(
              context,
              ref,
              icon: Icons.light_mode,
              title: '浅色'.tr,
              mode: ThemeMode.light,
            ),
            _buildThemeOption(
              context,
              ref,
              icon: Icons.dark_mode,
              title: '深色'.tr,
              mode: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required ThemeMode mode,
  }) {
    final currentMode = ref.watch(themeModeProvider);
    final isSelected = currentMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.inkGreen : null),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.inkGreen)
          : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  /// 切换隐私锁
  Future<void> _togglePrivacyLock(WidgetRef ref, bool value) async {
    if (value) {
      // 启用前先验证一次身份，确保设备支持生物识别
      // 这里直接启用，实际验证在锁屏时进行
      ref.read(privacyLockProvider.notifier).setEnabled(true);
    } else {
      ref.read(privacyLockProvider.notifier).setEnabled(false);
    }
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.inkGreen,
                  AppColors.inkGreenDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.inkGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '渊'.tr,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.inkBlack,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.slogan,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey : AppColors.inkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.inkGray,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.inkGreen, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.inkGray))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
