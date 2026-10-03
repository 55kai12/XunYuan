/// 导出中心与导出选项面板测试
/// 验证：① 导出中心列出四类入口；② 选项面板回传所选格式与清晰度
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:familytree/core/database/database.dart';
import 'package:familytree/core/i18n/i18n.dart';
import 'package:familytree/features/export/presentation/export_center_page.dart';
import 'package:familytree/features/export/presentation/export_options_sheet.dart';
import 'package:familytree/features/family/domain/family_providers.dart';

/// 用内存数据库包一层 ProviderScope
Widget _wrap(Widget child) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() => I18n.useEnglish = false);

  testWidgets('导出中心列出四类导出入口', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const ExportCenterPage()));
    await tester.pump();

    expect(find.text('导出中心'), findsOneWidget);
    expect(find.text('族谱树图片'), findsOneWidget);
    expect(find.text('家族名册 PDF'), findsOneWidget);
    expect(find.text('数据备份包'), findsOneWidget);
    expect(find.text('GEDCOM 文件'), findsOneWidget);
  });

  testWidgets('导出选项面板回传所选格式与清晰度', (WidgetTester tester) async {
    ExportOptions? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                picked = await showExportOptionsSheet(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('导出选项'), findsOneWidget);

    // 默认 PNG / 高清；改为「两者」+「超清」
    await tester.tap(find.text('两者'));
    await tester.pump();
    await tester.tap(find.text('超清'));
    await tester.pump();
    await tester.tap(find.text('导出'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.format, ExportFormat.both);
    expect(picked!.scale, 4.0);
  });
}
