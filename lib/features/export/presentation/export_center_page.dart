/// 导出中心页
/// 把散落在各处的导出入口收进一处：族谱树图片、家族名册 PDF、数据备份包、GEDCOM
/// 各行的具体导出仍复用 ExportService / BackupService / GedcomService
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../backup/domain/backup_providers.dart';
import '../../family/domain/family_providers.dart';
import '../../gedcom/domain/gedcom_providers.dart';
import '../../person/domain/person_providers.dart';
import '../domain/export_providers.dart';
import 'export_options_sheet.dart';

/// 导出中心页
class ExportCenterPage extends ConsumerStatefulWidget {
  const ExportCenterPage({super.key});

  @override
  ConsumerState<ExportCenterPage> createState() => _ExportCenterPageState();
}

class _ExportCenterPageState extends ConsumerState<ExportCenterPage> {
  /// 正在执行导出的行标识；非空时该行显示加载圈、并阻止并发触发
  String? _busy;

  /// 统一执行一次导出：负责 loading 态、错误提示与异常兜底
  Future<void> _run(String key, Future<void> Function() job) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await job();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// 选择家族；只有一个家族时直接返回，没有家族时提示并返回 null
  Future<FamilyTree?> _pickFamily() async {
    final families = await ref.read(watchFamiliesProvider.future);
    if (!mounted) return null;
    if (families.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('暂无家族可导出'.tr)),
      );
      return null;
    }
    if (families.length == 1) return families.first;

    return showDialog<FamilyTree>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择家族'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: families.length,
            itemBuilder: (context, i) {
              final f = families[i];
              return ListTile(
                title: Text(f.name),
                subtitle: Text('${f.surname}氏'.tr),
                onTap: () => Navigator.pop(context, f),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'.tr),
          ),
        ],
      ),
    );
  }

  /// 选择族谱树的中心人物
  Future<Person?> _pickPerson(FamilyTree family) async {
    final persons = await ref
        .read(personRepositoryProvider)
        .watchAll(treeId: family.id)
        .first;
    if (!mounted) return null;
    if (persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('该家族暂无成员，请先添加成员'.tr)),
      );
      return null;
    }
    if (persons.length == 1) return persons.first;

    final sorted = [...persons]
      ..sort((a, b) => (a.generation ?? 0).compareTo(b.generation ?? 0));

    return showDialog<Person>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择中心人物'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final p = sorted[i];
              return ListTile(
                title: Text('${p.surname}${p.givenName}'),
                subtitle: Text(
                  p.generation != null ? '第 ${p.generation} 世'.tr : '未分世代'.tr,
                ),
                onTap: () => Navigator.pop(context, p),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'.tr),
          ),
        ],
      ),
    );
  }

  /// 导出族谱树图片：选定家族与中心人物后，跳转族谱树页并直接弹出导出选项
  Future<void> _exportTree() async {
    final family = await _pickFamily();
    if (family == null) return;
    final person = await _pickPerson(family);
    if (person == null || !mounted) return;
    context.push('/person/${person.id}/tree?export=1');
  }

  /// 导出家族名册 PDF
  Future<void> _exportRoster() async {
    final family = await _pickFamily();
    if (family == null) return;
    await _run('roster', () async {
      final path =
          await ref.read(exportServiceProvider).exportFamilyPdf(family.id);
      if (!mounted) return;
      showSavedSnack(context, 'PDF 已保存：$path'.tr);
      await askShare(
        context,
        paths: [path],
        question: '是否分享家族名册 PDF？'.tr,
        shareText: '寻渊 · 家族名册'.tr,
      );
    });
  }

  /// 导出数据备份包（含配图与头像）
  Future<void> _exportBackup() async {
    await _run('backup', () async {
      final path = await ref.read(backupServiceProvider).exportToFile();
      if (!mounted) return;
      showSavedSnack(context, '备份已保存：$path'.tr);
      await askShare(
        context,
        paths: [path],
        question: '是否分享备份文件？'.tr,
        shareText: '寻渊族谱备份'.tr,
      );
    });
  }

  /// 导出 GEDCOM 文件
  Future<void> _exportGedcom() async {
    final family = await _pickFamily();
    if (family == null) return;
    await _run('gedcom', () async {
      final gedcom = await ref
          .read(gedcomServiceProvider)
          .exportToGedcom(family.id);
      final docsDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${docsDir.path}/exports');
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }
      final file = File('${exportsDir.path}/${family.name}_族谱.ged'.tr);
      await file.writeAsString(gedcom, encoding: utf8);
      if (!mounted) return;
      showSavedSnack(context, 'GEDCOM 已保存：${file.path}'.tr);
      await askShare(
        context,
        paths: [file.path],
        question: '是否分享 GEDCOM 文件？'.tr,
        shareText: '寻渊族谱 GEDCOM'.tr,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('导出中心'.tr)),
      body: ListView(
        children: [
          _sectionTitle('图片与文档'.tr),
          _row(
            key: 'tree',
            icon: Icons.account_tree_outlined,
            title: '族谱树图片'.tr,
            subtitle: '选定中心人物，导出 PNG / PDF'.tr,
            onTap: _exportTree,
          ),
          _row(
            key: 'roster',
            icon: Icons.menu_book_outlined,
            title: '家族名册 PDF'.tr,
            subtitle: '封面 + 家族信息 + 按世代分列的成员名册'.tr,
            onTap: _exportRoster,
          ),
          _sectionTitle('数据文件'.tr),
          _row(
            key: 'backup',
            icon: Icons.backup_outlined,
            title: '数据备份包'.tr,
            subtitle: '导出全部数据（含事件配图与头像）'.tr,
            onTap: _exportBackup,
          ),
          _row(
            key: 'gedcom',
            icon: Icons.swap_horiz,
            title: 'GEDCOM 文件'.tr,
            subtitle: '导出可被其他族谱软件识别的 .ged 文件'.tr,
            onTap: _exportGedcom,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
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

  Widget _row({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final busy = _busy == key;
    return ListTile(
      leading: Icon(icon, color: AppColors.inkGreen, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.inkGray)),
      trailing: busy
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chevron_right, size: 20),
      enabled: _busy == null,
      onTap: busy ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
