/// 备份与恢复页
/// 阶段 6：导出 JSON 备份、从 JSON 恢复、管理本地备份文件、数据清理
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/database/database.dart';
import '../../../core/settings/settings_providers.dart';
import '../domain/backup_providers.dart';
import '../../gedcom/domain/gedcom_providers.dart';
import '../../family/domain/family_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 备份与恢复页
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _isExporting = false;
  bool _isImporting = false;
  List<File> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  /// 加载本地备份列表
  Future<void> _loadBackups() async {
    final service = ref.read(backupServiceProvider);
    final files = await service.listBackups();
    if (mounted) {
      setState(() => _backups = files);
    }
  }

  /// 导出备份
  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final service = ref.read(backupServiceProvider);
      final path = await service.exportToFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份已保存：$path'.tr)),
      );
      await _loadBackups();
      if (!mounted) return;
      // 询问是否分享
      final share = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('备份成功'.tr),
          content: Text('是否分享备份文件？'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('仅保存'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('分享'.tr),
            ),
          ],
        ),
      );
      if (share == true) {
        await Share.shareXFiles([XFile(path)], text: '寻渊族谱备份'.tr);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份失败：$e'.tr), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// 从文件导入恢复
  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      if (!mounted) return;

      // 确认恢复方式
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.restore, color: AppColors.inkGreen),
          title: Text('恢复备份'.tr),
          content: Text(
            '将从「$fileName」恢复数据。\n\n'.tr +
            '「覆盖恢复」会清空现有数据后导入；\n'.tr +
            '「合并恢复」会保留现有数据并追加导入。'.tr,
            style: const TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('合并恢复'.tr),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.cinnabar),
              onPressed: () => Navigator.pop(context, false),
              child: Text('覆盖恢复'.tr),
            ),
          ],
        ),
      );
      if (merge == null) return;

      setState(() => _isImporting = true);
      final service = ref.read(backupServiceProvider);
      final stats = await service.importFromFile(filePath, merge: merge);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '恢复成功：${stats.families}个家族、${stats.persons}位成员、${stats.events}条事件，共${stats.total}条记录'.tr),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败：$e'.tr), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// 恢复指定备份文件
  Future<void> _restoreBackup(File file) async {
    final merge = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restore, color: AppColors.inkGreen),
        title: Text('恢复备份'.tr),
        content: Text(
          '将从「${file.uri.pathSegments.last}」恢复数据。\n\n'.tr +
          '选择恢复方式：'.tr,
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('合并恢复'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.cinnabar),
            onPressed: () => Navigator.pop(context, false),
            child: Text('覆盖恢复'.tr),
          ),
        ],
      ),
    );
    if (merge == null) return;

    setState(() => _isImporting = true);
    try {
      final service = ref.read(backupServiceProvider);
      final stats = await service.importFromFile(file.path, merge: merge);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复成功，共${stats.total}条记录'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败：$e'.tr), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// 删除备份文件
  Future<void> _deleteBackup(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.cinnabar),
        title: Text('删除备份'.tr),
        content: Text('确定要删除备份文件「${file.uri.pathSegments.last}」吗？'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.cinnabar),
            onPressed: () => Navigator.pop(context, true),
            child: Text('确认删除'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(backupServiceProvider);
      await service.deleteBackup(file.path);
      await _loadBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份已删除'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e'.tr)),
      );
    }
  }

  /// 导出 GEDCOM
  Future<void> _exportGedcom() async {
    // 选择要导出的家族
    final families = await ref.read(watchFamiliesProvider.future);
    if (!mounted) return;
    if (families.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('暂无家族可导出'.tr)),
      );
      return;
    }

    final selectedFamily = await showDialog<FamilyTree>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择家族'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: families.length,
            itemBuilder: (context, index) {
              final f = families[index];
              return ListTile(
                title: Text(f.name),
                subtitle: Text('${f.surname}氏'.tr),
                onTap: () => Navigator.pop(context, f),
              );
            },
          ),
        ),
      ),
    );
    if (selectedFamily == null) return;

    setState(() => _isExporting = true);
    try {
      final service = ref.read(gedcomServiceProvider);
      final gedcom = await service.exportToGedcom(selectedFamily.id);

      // 保存到文件
      final docsDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${docsDir.path}/exports');
      if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
      final fileName = '${selectedFamily.name}_族谱.ged'.tr;
      final file = File('${exportsDir.path}/$fileName');
      await file.writeAsString(gedcom, encoding: utf8);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GEDCOM 已保存：${file.path}'.tr)),
      );

      // 询问是否分享
      final share = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('导出成功'.tr),
          content: Text('是否分享 GEDCOM 文件？'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('仅保存'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('分享'.tr),
            ),
          ],
        ),
      );
      if (share == true) {
        await Share.shareXFiles([XFile(file.path)], text: '寻渊族谱 GEDCOM'.tr);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e'.tr), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// 导入 GEDCOM（带预览确认）
  Future<void> _importGedcom() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ged', 'GED'],
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final gedcomContent = await File(filePath).readAsString(encoding: utf8);

      // 第一步：预览解析结果
      final service = ref.read(gedcomServiceProvider);
      final preview = service.previewGedcom(gedcomContent);

      if (preview.individuals == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('未在文件中找到有效成员记录'.tr)),
        );
        return;
      }

      if (!mounted) return;
      // 显示预览确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('GEDCOM 导入预览'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('文件：${filePath.split('.tr/').last.split('\\').last}'),
              const SizedBox(height: 12),
              _previewRow('成员数量'.tr, '${preview.individuals} 人'.tr),
              _previewRow('家庭关系'.tr, '${preview.families} 个'.tr),
              _previewRow('事件记录'.tr, '${preview.events} 条'.tr),
              const SizedBox(height: 12),
              Text(
                '确认导入以上数据？将创建新家族并导入所有记录。'.tr,
                style: const TextStyle(fontSize: 13, color: AppColors.inkGray),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('确认导入'.tr),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;

      // 第二步：输入新家族名称
      final familyName = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController(text: '导入族谱'.tr);
          return AlertDialog(
            title: Text('创建家族'.tr),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '家族名称'.tr,
                hintText: '为导入的族谱创建一个家族'.tr,
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('开始导入'.tr),
              ),
            ],
          );
        },
      );
      if (familyName == null || familyName.isEmpty) return;

      setState(() => _isImporting = true);

      // 创建家族
      final familyRepo = ref.read(familyRepositoryProvider);
      final treeId = await familyRepo.insert(name: familyName, surname: '');

      // 导入 GEDCOM
      final stats = await service.importFromGedcom(gedcomContent, treeId: treeId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '导入成功：${stats.individuals}位成员、${stats.families}个家庭、${stats.events}条事件'.tr),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e'.tr), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// 预览行
  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.inkGray)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 数据清理
  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.cinnabar, size: 36),
        title: Text('清空所有数据'.tr),
        content: Text(
          '此操作将删除所有家族、成员、关系、事件、媒体和资料数据，且不可恢复！\n\n'.tr +
          '建议先导出备份。'.tr,
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.cinnabar),
            onPressed: () => Navigator.pop(context, true),
            child: Text('确认清空'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(backupServiceProvider);
      await service.clearAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('所有数据已清空'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清理失败：$e'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('备份与恢复'.tr)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 导出备份
              _SectionCard(
                icon: Icons.backup_outlined,
                title: '导出备份'.tr,
                subtitle: '将所有数据导出为备份包（含事件配图与头像）'.tr,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportBackup,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.file_download),
                  label: Text('导出备份包'.tr),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 自动备份开关
              _SectionCard(
                icon: Icons.autorenew,
                title: '自动备份'.tr,
                subtitle: '每天启动时自动备份，保留最近 5 份'.tr,
                child: SwitchListTile(
                  value: ref.watch(autoBackupProvider),
                  onChanged: (v) =>
                      ref.read(autoBackupProvider.notifier).setEnabled(v),
                  contentPadding: EdgeInsets.zero,
                  title: Text('启用自动备份'.tr,
                      style: const TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),

              // 导入恢复
              _SectionCard(
                icon: Icons.restore_page,
                title: '恢复备份'.tr,
                subtitle: '从备份包或旧版 JSON 文件恢复数据'.tr,
                child: OutlinedButton.icon(
                  onPressed: _isImporting ? null : _importFromFile,
                  icon: const Icon(Icons.folder_open),
                  label: Text('选择备份文件'.tr),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // GEDCOM 互操作
              _SectionCard(
                icon: Icons.swap_horiz,
                title: 'GEDCOM 互操作'.tr,
                subtitle: '与其他族谱软件交换数据（.ged 格式）'.tr,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportGedcom,
                      icon: const Icon(Icons.ios_share),
                      label: Text('导出 GEDCOM'.tr),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isImporting ? null : _importGedcom,
                      icon: const Icon(Icons.download_for_offline),
                      label: Text('导入 GEDCOM'.tr),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 本地备份列表
              _SectionCard(
                icon: Icons.folder_special,
                title: '本地备份'.tr,
                subtitle: '${_backups.length} 个备份文件'.tr,
                child: _backups.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '暂无本地备份'.tr,
                          style:
                              const TextStyle(color: AppColors.inkGray, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: _backups.map((file) {
                          final stat = file.statSync();
                          final sizeKB = (stat.size / 1024).toStringAsFixed(1);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.insert_drive_file,
                                color: AppColors.inkGreen),
                            title: Text(
                              file.uri.pathSegments.last,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${_formatDateTime(stat.modified)} · $sizeKB KB',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.inkGray),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore, size: 18),
                                  tooltip: '恢复'.tr,
                                  onPressed: () => _restoreBackup(file),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 18),
                                  tooltip: '分享'.tr,
                                  onPressed: () => Share.shareXFiles(
                                      [XFile(file.path)],
                                      text: '寻渊族谱备份'.tr),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: AppColors.cinnabar),
                                  tooltip: '删除'.tr,
                                  onPressed: () => _deleteBackup(file),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),

              // 数据清理
              _SectionCard(
                icon: Icons.delete_sweep_outlined,
                title: '数据清理'.tr,
                subtitle: '清空应用内所有数据'.tr,
                child: OutlinedButton.icon(
                  onPressed: _clearAllData,
                  icon: const Icon(Icons.delete_forever,
                      color: AppColors.cinnabar),
                  label: Text('清空所有数据'.tr,
                      style: const TextStyle(color: AppColors.cinnabar)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.cinnabar),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inkGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.inkGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '备份文件保存在应用文档目录，卸载应用会同时删除备份。建议定期将备份文件分享到云盘或其他位置。'.tr,
                        style:
                            const TextStyle(fontSize: 12, color: AppColors.inkGray),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 导入中遮罩
          if (_isImporting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('正在恢复数据…'.tr),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 分区卡片
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.inkGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkGray)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
