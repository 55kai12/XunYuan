/// 族谱页（家族列表）
/// 阶段 2：展示家族列表，空状态引导创建家族
/// 点击家族卡片进入家族首页
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../family/domain/family_providers.dart';
import '../../person/domain/person_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 族谱树主页（家族列表）
class TreePage extends ConsumerStatefulWidget {
  const TreePage({super.key});

  @override
  ConsumerState<TreePage> createState() => _TreePageState();
}

class _TreePageState extends ConsumerState<TreePage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(watchFamiliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('寻渊 · 族谱'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索家族'.tr,
            onPressed: () {
              setState(() => _isSearching = true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 底层：原页面内容（不受搜索影响）
          familiesAsync.when(
            data: (families) {
              if (families.isEmpty) {
                return _EmptyState(onCreate: () => context.push('/family/new'));
              }
              return _FamilyList(families: families);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _ErrorState(error: error),
          ),
          // 顶层：弹出式搜索面板
          _SearchPanel(
            isVisible: _isSearching,
            keyword: _keyword,
            searchController: _searchController,
            families: familiesAsync.valueOrNull ?? [],
            onClose: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _keyword = '';
              });
            },
            onChanged: (value) {
              setState(() => _keyword = value.trim());
            },
          ),
        ],
      ),
    );
  }
}

/// 弹出式搜索面板
/// 从顶部滑入，悬浮在页面内容上方，不影响底层页面
class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.isVisible,
    required this.keyword,
    required this.searchController,
    required this.families,
    required this.onClose,
    required this.onChanged,
  });

  final bool isVisible;
  final String keyword;
  final TextEditingController searchController;
  final List<FamilyTree> families;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: isVisible ? 0 : -MediaQuery.of(context).size.height * 0.6,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索输入栏
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '搜索家族名称、姓氏、堂号…'.tr,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: keyword.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    onChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                    TextButton(
                      onPressed: onClose,
                      child: Text('取消'.tr),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 搜索结果
              Expanded(
                child: keyword.isEmpty
                    ? Center(
                        child: Text(
                          '输入关键词搜索家族'.tr,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : _buildSearchResults(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = families
        .where((f) =>
            f.name.contains(keyword) ||
            f.surname.contains(keyword) ||
            (f.hallName?.contains(keyword) ?? false) ||
            (f.origin?.contains(keyword) ?? false))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          '未找到相关家族'.tr,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final family = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.cinnabar.withOpacity(0.1),
            child: Text(
              family.surname.isNotEmpty
                  ? family.surname.characters.first
                  : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.cinnabar,
              ),
            ),
          ),
          title: Text(family.name),
          subtitle: Text(
            [
              family.surname,
              if (family.hallName != null && family.hallName!.isNotEmpty)
                family.hallName,
            ].join(' · '),
          ),
          onTap: () {
            onClose();
            context.push('/family/${family.id}');
          },
        );
      },
    );
  }
}

/// 家族列表
class _FamilyList extends ConsumerWidget {
  const _FamilyList({required this.families});

  final List<FamilyTree> families;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: families.length,
      itemBuilder: (context, index) {
        final family = families[index];
        return _FamilyCard(
          family: family,
          isDark: isDark,
          onTap: () => context.push('/family/${family.id}'),
          onLongPress: () => _showFamilyMenu(context, ref, family),
        );
      },
    );
  }

  /// 长按家族卡片弹出操作菜单
  void _showFamilyMenu(
      BuildContext context, WidgetRef ref, FamilyTree family) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.cinnabar.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cinnabar.withOpacity(0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        family.surname.isNotEmpty
                            ? family.surname.characters.first
                            : '氏'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cinnabar,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${family.surname}姓${family.hallName != null && family.hallName!.isNotEmpty ? " · ${family.hallName}" : ""}'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text('进入家族'.tr),
              onTap: () {
                Navigator.pop(context);
                context.push('/family/${family.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('编辑家族'.tr),
              onTap: () {
                Navigator.pop(context);
                context.push('/family/${family.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text('查看族谱树'.tr),
              onTap: () {
                Navigator.pop(context);
                // 找到第一位成员作为族谱树中心
                _openFamilyTree(context, ref, family);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.cinnabar),
              title: Text('删除家族'.tr,
                  style: const TextStyle(color: AppColors.cinnabar)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteFamily(context, ref, family);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 打开家族族谱树（找到第一位成员作为中心）
  Future<void> _openFamilyTree(
      BuildContext context, WidgetRef ref, FamilyTree family) async {
    try {
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
      context.push('/person/${persons.first.id}/tree');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e'.tr)),
      );
    }
  }

  /// 确认删除家族
  Future<void> _confirmDeleteFamily(
      BuildContext context, WidgetRef ref, FamilyTree family) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.cinnabar, size: 36),
        title: Text('删除家族'.tr),
        content: Text(
          '确定要删除「${family.name}」吗？\n\n'.tr +
          '该操作将同时删除家族下所有成员、关系、事件和媒体数据，且不可恢复。'.tr,
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
            child: Text('确认删除'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(familyRepositoryProvider).delete(family.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${family.name}」已删除'.tr)),
      );
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

/// 家族卡片
class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.family,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  final FamilyTree family;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    // 家族详情统计（使用 StreamBuilder 订阅成员数）
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 姓氏印章
              _SurnameSeal(surname: family.surname),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            family.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.inkBlack,
                                  letterSpacing: 0.5,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (family.hallName != null &&
                            family.hallName!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cinnabar.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    AppColors.cinnabar.withOpacity(0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '堂号 · ${family.hallName}'.tr,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.cinnabar,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      family.description?.isNotEmpty == true
                          ? family.description!
                          : '暂无简介'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? Colors.grey : AppColors.inkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 家族信息标签
                    Row(
                      children: [
                        _InfoTag(
                          icon: Icons.family_restroom,
                          text:
                              '${family.surname}姓'.tr,
                        ),
                        if (family.origin != null &&
                            family.origin!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _InfoTag(
                            icon: Icons.place_outlined,
                            text: family.origin!,
                          ),
                        ],
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.inkLightGray,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 姓氏印章（朱砂色圆形底 + 姓氏）
class _SurnameSeal extends StatelessWidget {
  const _SurnameSeal({required this.surname});

  final String surname;

  @override
  Widget build(BuildContext context) {
    final char = surname.isNotEmpty ? surname.characters.first : '氏'.tr;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cinnabar.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.cinnabar.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.cinnabar,
          ),
        ),
      ),
    );
  }
}

/// 信息标签
class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.inkGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.inkGray),
        ),
      ],
    );
  }
}

/// 空状态：没有家族时的引导
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.inkGreenLight.withOpacity(0.15)
                      : AppColors.inkGreen.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.account_tree,
                  size: 48,
                  color:
                      isDark ? AppColors.inkGreenLight : AppColors.inkGreen,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '寻根问祖，渊远流长'.tr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.inkBlack,
                      letterSpacing: 2,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '还没有家族族谱\n点击下方「创建家族」开始记录您的家族世系'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey : AppColors.inkGray,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // 创建按钮（空状态内嵌，便于引导）
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: Text('创建家族'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 错误状态
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              '家族加载失败'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: const TextStyle(fontSize: 13, color: AppColors.inkGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
