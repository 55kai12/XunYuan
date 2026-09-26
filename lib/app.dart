/// 应用根组件
/// 配置 ProviderScope、主题、路由、隐私锁
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/i18n/i18n.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_providers.dart';
import 'core/settings/settings_service.dart';
import 'features/backup/data/auto_backup_runner.dart';
import 'features/security/data/secure_window.dart';
import 'features/security/presentation/lock_screen.dart';

/// 寻渊应用根组件
class XunYuanApp extends ConsumerWidget {
  const XunYuanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final privacyLockEnabled = ref.watch(privacyLockProvider);
    final onboardingDone = ref.watch(onboardingProvider);
    final languageMode = ref.watch(languageModeProvider);

    // 首帧后检查是否需要自动备份（引导未完成的新用户跳过）
    if (onboardingDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        maybeRunAutoBackup(ref);
      });
    }

    // FLAG_SECURE 跟随隐私锁开关（任务切换器预览不泄露族谱内容）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SecureWindow.setSecure(privacyLockEnabled);
    });
    ref.listen(privacyLockProvider, (_, next) {
      SecureWindow.setSecure(next);
    });

    // 计算生效 locale，并同步给 .tr（先于子树构建执行）
    Locale? locale;
    switch (languageMode) {
      case LanguageMode.zh:
        locale = const Locale('zh', 'CN');
        I18n.useEnglish = false;
      case LanguageMode.en:
        locale = const Locale('en', 'US');
        I18n.useEnglish = true;
      case LanguageMode.system:
        final sys = WidgetsBinding.instance.platformDispatcher.locale;
        locale = null; // 由 MaterialApp 在 supportedLocales 中解析
        I18n.useEnglish = sys.languageCode != 'zh';
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // 主题配置（跟随用户偏好）
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // 路由配置（根据引导页状态决定初始路由）
      routerConfig: createRouter(onboardingDone),

      // 本地化配置（locale 为 null 时跟随系统）
      locale: locale,
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 隐私锁：启用时在应用外层包裹锁屏
      builder: (context, child) {
        if (privacyLockEnabled) {
          return LockScreen(child: child!);
        }
        return child!;
      },
    );
  }
}
