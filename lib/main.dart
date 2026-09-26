/// 应用入口
/// 寻渊 - 本地优先的中文族谱工具
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/settings/settings_providers.dart';

/// 应用入口函数
Future<void> main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 SharedPreferences，用于持久化用户偏好
  final prefs = await SharedPreferences.getInstance();

  // 全局异常捕获
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // 启动 Riverpod 状态管理容器，注入 SharedPreferences
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const XunYuanApp(),
    ),
  );
}
