/// 家族首页
/// 阶段 2：展示家族详情、成员统计、功能入口
/// 支持编辑、删除（二次确认 + 级联删除提示）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/description_images.dart';
import '../../../shared/widgets/stagger_in.dart';
import '../domain/family_providers.dart';
import '../../person/domain/person_providers.dart';
import '../../export/domain/export_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 家族首页
class FamilyHomePage extends ConsumerWidget {
  const FamilyHomePage({super.key, required this.treeId});

  /// 家族 ID
  final int treeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(watchFamilyProvider(treeId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return familyAsync.when(
      data: (family) {
        if (family == null) {
          return _NotFound(isDark: isDark);
        }
        return _FamilyHomeContent(
          family: family,
          isDark: isDark,
          onDelete: () => _confirmDelete(context, ref, family),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('家族加载失败'.tr,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('$error',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkGray),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text('返回'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 删除二次确认弹窗
  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, FamilyTree family) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.cinnabar, size: 36),
        title: Text('删除家族'.tr),
        content: Text(
          '确定要删除「${family.name}」吗？\n\n'.tr +
          '该操作将同时删除家族下的全部成员、关系、事件、媒体和资料，'.tr +
          '且不可恢复。'.tr,
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cinnabar,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('确认删除'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(familyRepositoryProvider).delete(treeId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${family.name}」已删除'.tr)),
      );
      context.go('/');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// 家族首页内容
class _FamilyHomeContent extends ConsumerWidget {
  const _FamilyHomeContent({
    required this.family,
    required this.isDark,
    required this.onDelete,
  });

  final FamilyTree family;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(family.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑家族'.tr,
            onPressed: () => context.push('/family/${family.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除家族'.tr,
            onPressed: onDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // 家族头部：姓氏印章 + 基本信息
          StaggerIn(index: 0, child: _FamilyHeader(family: family, isDark: isDark)),
          const SizedBox(height: 8),

          // 成员统计
          StaggerIn(index: 1, child: _StatsSection(family: family, isDark: isDark)),
          const SizedBox(height: 8),

          // 字辈展示
          if (family.generationWords != null &&
              family.generationWords!.isNotEmpty) ...[
            StaggerIn(index: 2, child: _GenerationWordsSection(words: family.generationWords!)),
            const SizedBox(height: 8),
          ],

          // 家族简介
          if (family.description != null && family.description!.isNotEmpty) ...[
            StaggerIn(index: 3, child: _DescriptionSection(description: family.description!)),
            const SizedBox(height: 8),
          ],

          // 功能入口
          StaggerIn(index: 4, child: _buildSectionTitle('家族功能'.tr)),
          StaggerIn(
            index: 5,
            child: _FeatureEntry(
              icon: Icons.account_tree,
              title: '族谱树'.tr,
              subtitle: '查看世系图谱'.tr,
              onTap: () => _showTreePersonPicker(context, ref),
            ),
          ),
          StaggerIn(
            index: 6,
            child: _FeatureEntry(
              icon: Icons.people_outline,
              title: '成员列表'.tr,
              subtitle: '管理家族成员'.tr,
              onTap: () => context.go('/members'),
            ),
          ),
          StaggerIn(
            index: 7,
            child: _FeatureEntry(
              icon: Icons.timeline,
              title: '事件时间线'.tr,
              subtitle: '记录家族大事'.tr,
              onTap: () => context.push('/timeline?treeId=${family.id}'),
            ),
          ),
          StaggerIn(
            index: 8,
            child: _FeatureEntry(
              icon: Icons.ios_share,
              title: '导出族谱'.tr,
              subtitle: '导出 PDF 名册'.tr,
              onTap: () => _exportPdf(context, ref),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/person/new?treeId=${family.id}'),
        icon: const Icon(Icons.person_add),
        label: Text('添加成员'.tr),
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

  /// 导出家族 PDF
  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('正在生成 PDF…'.tr),
          ],
        ),
      ),
    );

    try {
      final service = ref.read(exportServiceProvider);
      final path = await service.exportFamilyPdf(family.id);
      if (!context.mounted) return;
      Navigator.pop(context); // 关闭 loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 已保存：$path'.tr)),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// 选择族谱树的中心人物
  Future<void> _showTreePersonPicker(
      BuildContext context, WidgetRef ref) async {
    final persons = await ref
        .read(personRepositoryProvider)
        .watchAll(treeId: family.id)
        .first;
    if (!context.mounted) return;

    if (persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('该家族暂无成员，请先添加成员'.tr)),
      );
      return;
    }

    final selected = await showDialog<Person>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择中心人物'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: persons.length,
            itemBuilder: (context, index) {
              final p = persons[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: (p.gender == Gender.female
                          ? AppColors.cinnabar
                          : AppColors.inkGreen)
                      .withOpacity(0.12),
                  child: Text(
                    p.surname.isNotEmpty
                        ? p.surname.characters.first
                        : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: p.gender == Gender.female
                          ? AppColors.cinnabar
                          : AppColors.inkGreen,
                    ),
                  ),
                ),
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

    if (selected != null && context.mounted) {
      context.push('/person/${selected.id}/tree');
    }
  }
}

/// 家族头部：大印章 + 名称 + 堂号/郡望
class _FamilyHeader extends StatelessWidget {
  const _FamilyHeader({required this.family, required this.isDark});

  final FamilyTree family;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          // 姓氏大印章
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.cinnabar.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cinnabar.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                family.surname.isNotEmpty
                    ? family.surname.characters.first
                    : '氏'.tr,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinnabar,
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
                  family.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color:
                            isDark ? AppColors.darkOnSurface : AppColors.inkBlack,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 6),
                // 堂号 / 郡望标签
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (family.hallName != null &&
                        family.hallName!.isNotEmpty)
                      _Tag(text: '堂号 · ${family.hallName}'.tr),
                    if (family.origin != null && family.origin!.isNotEmpty)
                      _Tag(text: '郡望 · ${family.origin}'.tr),
                    _Tag(text: '${family.surname}氏宗族'.tr),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 标签
class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.inkGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.inkGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 成员统计区
class _StatsSection extends ConsumerWidget {
  const _StatsSection({required this.family, required this.isDark});

  final FamilyTree family;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 订阅统计信息
    final statsAsync = ref.watch(familyStatsProvider(family.id));

    return statsAsync.when(
      data: (stats) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 第一行：核心指标
                Row(
                  children: [
                    _StatItem(value: '${stats.total}', label: '成员总数'.tr),
                    _StatDivider(),
                    _StatItem(value: '${stats.generationCount}', label: '世代'.tr),
                    _StatDivider(),
                    _StatItem(value: '${stats.alive}', label: '在世'.tr),
                    _StatDivider(),
                    _StatItem(value: '${stats.deceased}', label: '已故'.tr),
                  ],
                ),
                const SizedBox(height: 16),
                // 性别比例条
                if (stats.total > 0) ...[
                  Row(
                    children: [
                      Text('性别'.tr, style: const TextStyle(fontSize: 12, color: AppColors.inkGray)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stats.maleCount / stats.total,
                            backgroundColor: AppColors.cinnabar.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation(AppColors.inkGreen),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '男${stats.maleCount} · 女${stats.femaleCount}'.tr,
                        style: const TextStyle(fontSize: 11, color: AppColors.inkGray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 在世/已故比例条
                  Row(
                    children: [
                      Text('状态'.tr, style: const TextStyle(fontSize: 12, color: AppColors.inkGray)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stats.alive / stats.total,
                            backgroundColor: AppColors.inkGray.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation(AppColors.success),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '在世${stats.alive} · 已故${stats.deceased}'.tr,
                        style: const TextStyle(fontSize: 11, color: AppColors.inkGray),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '统计数据加载失败：$error'.tr,
            style: const TextStyle(fontSize: 13, color: AppColors.inkGray),
          ),
        ),
      ),
    );
  }
}

/// 统计单项
class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.inkGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkGray),
          ),
        ],
      ),
    );
  }
}

/// 统计分隔线
class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.inkLightGray.withOpacity(0.4),
    );
  }
}

/// 字辈展示区
class _GenerationWordsSection extends StatelessWidget {
  const _GenerationWordsSection({required this.words});

  final String words;

  @override
  Widget build(BuildContext context) {
    // 按顿号、空格、逗号拆分字辈
    final wordList = words
        .split(RegExp(r'[、，,\s]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_list_numbered,
                    size: 18, color: AppColors.inkGreen),
                const SizedBox(width: 8),
                Text(
                  '字辈排行'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wordList.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final word = entry.value;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.ricePaperDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.inkGreen.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkGray,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        word,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 家族简介区
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

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
                const Icon(Icons.article_outlined,
                    size: 18, color: AppColors.inkGreen),
                const SizedBox(width: 8),
                Text(
                  '家族简介'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DescriptionRichText(
              text: description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: AppColors.inkBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 功能入口项
class _FeatureEntry extends StatelessWidget {
  const _FeatureEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.inkGreen, size: 24),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.inkGray),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// 家族不存在页面
class _NotFound extends StatelessWidget {
  const _NotFound({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('家族'.tr)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined,
                size: 48, color: AppColors.inkGray),
            const SizedBox(height: 16),
            Text(
              '家族不存在或已被删除'.tr,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkOnSurface : AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: Text('返回家族列表'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
