/// 应用根组件
/// 配置 ProviderScope、主题、路由、隐私锁
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/i18n/i18n.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/text_scale.dart';
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
      // 字号上限：跟随系统但封顶 1.6x（见 limitTextScale）
      //
      // 顺序有讲究：字号上限必须包在**最外层**。锁屏是整棵子树的兄弟而非后代
      // —— 未解锁时它根本不渲染 child，只画自己那套 UI。若把上限包在内层，
      // 锁屏自己的文字就落在约束之外，2.0x 时 80×80 图标框里的「渊」会被撑破。
      builder: (context, child) {
        final content =
            privacyLockEnabled ? LockScreen(child: child!) : child!;
        return limitTextScale(context, content);
      },
    );
  }
}
