/// 应用配色方案 · S1（Apple Design Mind）
/// 语义色优先：label / secondaryLabel / systemBackground / separator
/// tint 只用于关键操作；功能色用 S1 系统色（red/orange/green/teal）
/// 兼容别名 API 保持不变（inkGreen / cinnabar / inkGray 等），页面零改动换肤
library;

import 'package:flutter/material.dart';

/// 寻渊 S1 色板
class AppColors {
  AppColors._();

  // ===== S1 系统色 =====
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemIndigo = Color(0xFF5856D6);

  // ===== Tint（强调色，只用于关键操作）=====
  static const Color primary = systemBlue;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDCEBFF);
  static const Color onPrimaryContainer = Color(0xFF00315C);

  // ===== Secondary / Tertiary =====
  static const Color secondary = Color(0xFF8E8E93); // systemGray
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE5E5EA);
  static const Color onSecondaryContainer = Color(0xFF1C1C1E);

  static const Color tertiary = Color(0xFF30B0C7);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFD8F3F9);
  static const Color onTertiaryContainer = Color(0xFF083B42);

  // ===== Surface（insetGrouped：背景 grouped 灰，卡片纯白）=====
  static const Color surface = Color(0xFFF2F2F7); // systemGroupedBackground
  static const Color surfaceContainerLow = Color(0xFFFFFFFF); // 卡片
  static const Color surfaceContainer = Color(0xFFF2F2F7); // 栏/导航
  static const Color surfaceContainerHigh = Color(0xFFFFFFFF); // 弹窗
  static const Color surfaceContainerHighest = Color(0xFFE5E5EA);
  static const Color onSurface = Color(0xFF000000); // label
  static const Color onSurfaceVariant = Color(0xFF6D6D72); // secondaryLabel

  // ===== Outline / Separator =====
  static const Color outline = Color(0xFFC6C6C8);
  static const Color outlineVariant = Color(0x4A3C3C43); // separator 29%

  // ===== Inverse =====
  static const Color inverseSurface = Color(0xFF1C1C1E);
  static const Color inverseOnSurface = Color(0xFFF2F2F7);
  static const Color inversePrimary = Color(0xFF409CFF);

  // ===== Error =====
  static const Color error = systemRed;
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // ===== 功能色（S1 系统色）=====
  static const Color success = systemGreen;
  static const Color warning = systemOrange;
  static const Color info = systemTeal;

  // ===== 兼容旧代码的别名（值已映射到 S1 语义）=====
  /// 主强调（原「墨绿」，现为 S1 tint 蓝）
  static const Color inkGreen = primary;
  static const Color inkGreenLight = Color(0xFF409CFF); // 深色模式 tint
  static const Color inkGreenDark = Color(0xFF0062CC); // 渐变深端

  /// 危险/女性色（朱砂 → systemRed）
  static const Color cinnabar = systemRed;

  /// 文字层级
  static const Color inkBlack = Color(0xFF000000); // label
  static const Color inkGray = Color(0x993C3C43); // secondaryLabel 60%
  static const Color inkLightGray = Color(0x4D3C3C43); // tertiaryLabel 30%

  /// 背景
  static const Color ricePaper = Color(0xFFF2F2F7); // systemGroupedBackground
  static const Color ricePaperDark = Color(0xFFFFFFFF); // 卡片填充

  // 深色模式（S1: #000000 / #1C1C1E / #2C2C2E）
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkOnSurface = Color(0xFFEBEBF5); // dark label
  static const Color darkBorder = Color(0xFF38383A);
  static const Color lightBorder = outlineVariant; // separator

  // ===== S1 形状 =====
  /// 卡片圆角（S1: 16–28）
  static const double cardRadius = 16.0;

  /// 对话框圆角（iOS Alert 风格）
  static const double dialogRadius = 14.0;

  /// FAB 圆角（S1 按钮 10–14）
  static const double fabRadius = 14.0;
  static const double fabLargeRadius = 24.0;
  static const double fabSmallRadius = 10.0;

  /// 底部导航高度
  static const double navBarHeight = 72.0;
  static const double navIndicatorWidth = 64.0;
  static const double navIndicatorHeight = 32.0;

  /// 屏幕边缘间距（S1: 16–20）
  static const double screenMargin = 16.0;
  static const double componentGap = 12.0;
}

/// S1 浅色 ColorScheme
const ColorScheme monoLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,
  tertiary: AppColors.tertiary,
  onTertiary: AppColors.onTertiary,
  tertiaryContainer: AppColors.tertiaryContainer,
  onTertiaryContainer: AppColors.onTertiaryContainer,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  onSurfaceVariant: AppColors.onSurfaceVariant,
  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
  inverseSurface: AppColors.inverseSurface,
  onInverseSurface: AppColors.inverseOnSurface,
  inversePrimary: AppColors.inversePrimary,
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Colors.transparent,
);

/// S1 深色 ColorScheme（背景 #000，卡片 #1C1C1E）
const ColorScheme s1DarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF0A84FF), // systemBlue dark
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF084176),
  onPrimaryContainer: Color(0xFFD2E5FF),
  secondary: Color(0xFF98989E),
  onSecondary: Color(0xFF1C1C1E),
  secondaryContainer: Color(0xFF2C2C2E),
  onSecondaryContainer: Color(0xFFE5E5EA),
  tertiary: Color(0xFF40C8E0),
  onTertiary: Color(0xFF00303A),
  tertiaryContainer: Color(0xFF0E4A55),
  onTertiaryContainer: Color(0xFFB8ECF6),
  error: Color(0xFFFF453A), // systemRed dark
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFF5C0D0D),
  onErrorContainer: Color(0xFFFFD9D6),
  surface: Color(0xFF000000),
  onSurface: Color(0xFFFFFFFF),
  onSurfaceVariant: Color(0xFF9E9EA3),
  outline: Color(0xFF48484A),
  outlineVariant: Color(0xFF38383A),
  inverseSurface: Color(0xFFF2F2F7),
  onInverseSurface: Color(0xFF1C1C1E),
  inversePrimary: Color(0xFF409CFF),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Colors.transparent,
);
