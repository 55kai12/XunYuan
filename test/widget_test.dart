/// 应用基础测试
/// 验证寻渊应用可以正常构建且不抛出异常
/// 测试环境使用内存数据库，避免依赖系统文件目录
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:familytree/app.dart';
import 'package:familytree/core/database/database.dart';
import 'package:familytree/core/i18n/i18n.dart';
import 'package:familytree/core/settings/settings_providers.dart';
import 'package:familytree/features/family/domain/family_providers.dart';

/// 创建带内存数据库覆盖的测试应用
Widget _buildTestApp(SharedPreferences prefs) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  // 测试结束时关闭数据库，释放资源
  addTearDown(db.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const XunYuanApp(),
  );
}

/// 等待数据库数据流发射
/// 使用 runAsync 让真实事件循环执行异步查询，
/// 避免 FakeAsync 环境中 drift 的 stream 无法推进
Future<void> _pumpApp(WidgetTester tester) async {
  // 测试断言基于中文文案；mock 语言设置为简体中文，避免跟随宿主英文 locale
  I18n.useEnglish = false;
  // 使用 mock SharedPreferences，设置引导页已完成
  SharedPreferences.setMockInitialValues(
      {'onboarding_done': true, 'language_mode': 'zh'});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(_buildTestApp(prefs));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// 卸载应用并清空 drift 关闭 stream 时创建的清理 Timer
Future<void> _teardownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('寻渊应用可以正常启动并显示族谱页',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // 验证 AppBar 标题包含"寻渊"
    expect(find.textContaining('寻渊'), findsWidgets);

    // 验证底部导航存在
    expect(find.byType(NavigationBar), findsOneWidget);

    // 验证四个底部导航项
    expect(find.text('族谱'), findsOneWidget);
    expect(find.text('成员'), findsOneWidget);
    expect(find.text('时间线'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await _teardownApp(tester);
  });

  testWidgets('底部导航可以切换到成员页', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('成员'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 验证成员页标题
    expect(find.text('家族成员'), findsOneWidget);

    await _teardownApp(tester);
  });

  testWidgets('底部导航可以切换到时间线页', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('时间线'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 验证时间线页标题
    expect(find.text('事件时间线'), findsOneWidget);

    await _teardownApp(tester);
  });

  testWidgets('底部导航可以切换到我的页', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('我的'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 验证我的页内容
    expect(find.text('数据管理'), findsOneWidget);

    await _teardownApp(tester);
  });
}
