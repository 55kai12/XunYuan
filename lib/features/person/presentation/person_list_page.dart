/// 成员列表页
/// 阶段 3：展示家族成员列表，支持搜索、家族筛选、按世代分组
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../family/domain/family_providers.dart';
import '../domain/person_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 成员列表页（替换原空状态页）
class PersonListPage extends ConsumerStatefulWidget {
  const PersonListPage({super.key});

  @override
  ConsumerState<PersonListPage> createState() => _PersonListPageState();
}

class _PersonListPageState extends ConsumerState<PersonListPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(watchPersonsProvider);
    final familiesAsync = ref.watch(watchFamiliesProvider);
    final filter = ref.watch(personFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('家族成员'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索成员'.tr,
            onPressed: () {
              setState(() => _isSearching = true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 底层：原页面内容（不受搜索影响）
          Column(
            children: [
              // 家族筛选条
              familiesAsync.when(
                data: (families) {
                  if (families.length <= 1) return const SizedBox.shrink();
                  return _FamilyFilterBar(
                    families: families,
                    selectedTreeId: filter.treeId,
                    onSelected: (id) {
                      ref.read(personFilterProvider.notifier).state =
                          filter.copyWith(treeId: id);
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // 筛选条件标签
              if (filter.generation != null ||
                  filter.branch != null ||
                  filter.generationWord != null)
                _ActiveFilterChips(
                  filter: filter,
                  onClear: () {
                    ref.read(personFilterProvider.notifier).state =
                        const PersonFilter();
                    _searchController.clear();
                  },
                ),
              // 成员列表
              Expanded(
                child: personsAsync.when(
                  data: (persons) {
                    if (persons.isEmpty) {
                      return _EmptyState(
                        isDark: isDark,
                        hasFilter: filter.treeId != null ||
                            filter.generation != null,
                        onCreate: () => context.push('/person/new'),
                      );
                    }
                    return _PersonList(persons: persons);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _ErrorState(error: error),
                ),
              ),
            ],
          ),
          // 顶层：弹出式搜索面板
          _PersonSearchPanel(
            isVisible: _isSearching,
            keyword: _searchKeyword,
            searchController: _searchController,
            allPersons: personsAsync.valueOrNull ?? [],
            onClose: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchKeyword = '';
              });
            },
            onChanged: (value) {
              setState(() => _searchKeyword = value.trim());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/person/new'),
        tooltip: '添加成员'.tr,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

/// 家族筛选条
class _FamilyFilterBar extends StatelessWidget {
  const _FamilyFilterBar({
    required this.families,
    required this.selectedTreeId,
    required this.onSelected,
  });

  final List<FamilyTree> families;
  final int? selectedTreeId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: families.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = selectedTreeId == null;
            return _FilterChip(
              label: '全部'.tr,
              selected: selected,
              onTap: () => onSelected(null),
            );
          }
          final family = families[index - 1];
          final selected = selectedTreeId == family.id;
          return _FilterChip(
            label: family.name,
            selected: selected,
            onTap: () => onSelected(family.id),
          );
        },
      ),
    );
  }
}

/// 筛选标签
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.inkGreen.withOpacity(0.15),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? AppColors.inkGreen : AppColors.inkLightGray,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.inkGreen : AppColors.inkGray,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

/// 已激活筛选条件标签
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filter, required this.onClear});

  final PersonFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              children: [
                if (filter.generation != null)
                  _ActiveChip(label: '第${filter.generation}世'.tr),
                if (filter.branch != null)
                  _ActiveChip(label: filter.branch!),
                if (filter.generationWord != null)
                  _ActiveChip(label: '字辈·${filter.generationWord}'.tr),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text('清除筛选'.tr, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cinnabar.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11, color: AppColors.cinnabar),
      ),
    );
  }
}

/// 成员列表（按世代分组，支持下拉刷新）
class _PersonList extends ConsumerWidget {
  const _PersonList({required this.persons});

  final List<Person> persons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 按世代分组
    final grouped = <int?, List<Person>>{};
    for (final p in persons) {
      grouped.putIfAbsent(p.generation, () => []).add(p);
    }
    final generations = grouped.keys.toList()
      ..sort((a, b) => (a ?? 0).compareTo(b ?? 0));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(watchPersonsProvider);
        await ref.read(watchPersonsProvider.future);
      },
      child: ListView.builder(
        padding: EdgeInsets.only(
          bottom: 80 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: generations.length,
        itemBuilder: (context, index) {
          final gen = generations[index];
          final list = grouped[gen]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 世代标题
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.inkGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gen != null ? '第 $gen 世'.tr : '未分世代'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${list.length} 人'.tr,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkGray),
                    ),
                  ],
                ),
              ),
              // 成员卡片（带淡入动画）
              ...list.asMap().entries.map((e) => _PersonCard(person: e.value, index: e.key)),
            ],
          );
        },
      ),
    );
  }
}

/// 成员卡片（带淡入动画）
class _PersonCard extends ConsumerWidget {
  const _PersonCard({required this.person, required this.index});

  final Person person;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index % 10) * 30),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: PressableCard(
        onTap: () => context.push('/person/${person.id}'),
        onLongPress: () => _showPersonMenu(context, ref, person),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 头像
              _Avatar(person: person, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${person.surname}${person.givenName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.inkBlack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (person.courtesyName != null &&
                            person.courtesyName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '字 ${person.courtesyName}'.tr,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.inkGray),
                          ),
                        ],
                        // 性别图标
                        const SizedBox(width: 6),
                        Icon(
                          person.gender == Gender.female
                              ? Icons.female
                              : Icons.male,
                          size: 16,
                          color: person.gender == Gender.female
                              ? AppColors.cinnabar
                              : AppColors.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 标签行
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (person.generationWord != null &&
                            person.generationWord!.isNotEmpty)
                          _MiniTag(text: person.generationWord!),
                        if (person.branch != null &&
                            person.branch!.isNotEmpty)
                          _MiniTag(text: person.branch!),
                        if (person.isAlive)
                          _MiniTag(text: '在世'.tr, color: AppColors.success),
                        if (!person.isAlive)
                          _MiniTag(text: '已故'.tr, color: AppColors.inkGray),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 生卒信息
                    Text(
                      _buildLifeSpan(person),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkGray),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkLightGray),
            ],
          ),
        ),
    );
  }

  String _buildLifeSpan(Person p) {
    final parts = <String>[];
    if (p.birthDate != null) {
      parts.add('生于 ${p.birthDate!.year}'.tr);
    }
    if (!p.isAlive && p.deathDate != null) {
      parts.add('卒于 ${p.deathDate!.year}'.tr);
    }
    if (p.birthPlace != null && p.birthPlace!.isNotEmpty) {
      parts.add(p.birthPlace!);
    }
    return parts.isEmpty ? '暂无生卒信息'.tr : parts.join(' · ');
  }

  /// 长按成员卡片弹出操作菜单
  void _showPersonMenu(BuildContext context, WidgetRef ref, Person person) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: (person.gender == Gender.female
                            ? AppColors.cinnabar
                            : AppColors.inkGreen)
                        .withOpacity(0.12),
                    child: Text(
                      person.surname.isNotEmpty
                          ? person.surname.characters.first
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: person.gender == Gender.female
                            ? AppColors.cinnabar
                            : AppColors.inkGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${person.surname}${person.givenName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (person.generation != null)
                          Text(
                            '第 ${person.generation} 世'.tr,
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
            // 操作项
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text('查看详情'.tr),
              onTap: () {
                Navigator.pop(context);
                context.push('/person/${person.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('编辑成员'.tr),
              onTap: () {
                Navigator.pop(context);
                context.push('/person/${person.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text('查看族谱树'.tr),
              onTap: () {
                Navigator.pop(context);
                context.push('/person/${person.id}/tree');
              },
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: Text('管理关系'.tr),
              onTap: () {
                Navigator.pop(context);
                context.push('/person/${person.id}/relationships');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.cinnabar),
              title: Text('删除成员'.tr,
                  style: const TextStyle(color: AppColors.cinnabar)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, person);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 确认删除成员
  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.cinnabar, size: 36),
        title: Text('删除成员'.tr),
        content: Text(
          '确定要删除「${person.surname}${person.givenName}」吗？\n\n'.tr +
          '该操作将同时删除与该成员相关的所有关系记录，且不可恢复。'.tr,
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
      await ref.read(personRepositoryProvider).delete(person.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${person.surname}${person.givenName}」已删除'.tr)),
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

/// 头像（优先显示图片，否则显示姓氏首字）
class _Avatar extends ConsumerWidget {
  const _Avatar({required this.person, required this.size});

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaId = person.avatarMediaId;
    if (mediaId == null) {
      return _InitialAvatar(person: person, size: size);
    }
    // 异步加载媒体路径
    return FutureBuilder<MediaTableData?>(
      future: ref.read(personRepositoryProvider).getMediaById(mediaId),
      builder: (context, snapshot) {
        final media = snapshot.data;
        if (media != null && File(media.path).existsSync()) {
          return ClipOval(
            child: Image.file(
              File(media.path),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
        return _InitialAvatar(person: person, size: size);
      },
    );
  }
}

/// 姓氏首字头像
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.person, required this.size});

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final char = person.surname.isNotEmpty
        ? person.surname.characters.first
        : '?';
    final isFemale = person.gender == Gender.female;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isFemale
                ? AppColors.cinnabar
                : AppColors.inkGreen)
            .withOpacity(0.12),
        border: Border.all(
          color: (isFemale ? AppColors.cinnabar : AppColors.inkGreen)
              .withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: isFemale ? AppColors.cinnabar : AppColors.inkGreen,
          ),
        ),
      ),
    );
  }
}

/// 小标签
class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, this.color = AppColors.inkGreen});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isDark,
    required this.hasFilter,
    required this.onCreate,
  });

  final bool isDark;
  final bool hasFilter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.inkGreenLight.withOpacity(0.15)
                    : AppColors.inkGreen.withOpacity(0.08),
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.people,
                size: 44,
                color:
                    isDark ? AppColors.inkGreenLight : AppColors.inkGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? '没有匹配的成员'.tr : '暂无成员'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.inkBlack,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? '尝试调整搜索关键词或筛选条件'.tr
                  : '点击右下角「+」添加第一位家族成员'.tr,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey : AppColors.inkGray,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.person_add),
                label: Text('添加成员'.tr),
              ),
            ],
          ],
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
            Text('成员加载失败'.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('$error',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.inkGray),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// 弹出式成员搜索面板
class _PersonSearchPanel extends StatelessWidget {
  const _PersonSearchPanel({
    required this.isVisible,
    required this.keyword,
    required this.searchController,
    required this.allPersons,
    required this.onClose,
    required this.onChanged,
  });

  final bool isVisible;
  final String keyword;
  final TextEditingController searchController;
  final List<Person> allPersons;
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
                          hintText: '搜索姓名、字辈、世代…'.tr,
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
                          '输入关键词搜索成员'.tr,
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
    final results = allPersons
        .where((p) =>
            '${p.surname}${p.givenName}'.contains(keyword) ||
            (p.generationWord?.contains(keyword) ?? false) ||
            (p.generation?.toString().contains(keyword) ?? false) ||
            (p.branch?.contains(keyword) ?? false))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          '未找到相关成员'.tr,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final person = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: (person.gender == Gender.female
                    ? AppColors.cinnabar
                    : AppColors.inkGreen)
                .withOpacity(0.12),
            child: Text(
              person.surname.isNotEmpty
                  ? person.surname.characters.first
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: person.gender == Gender.female
                    ? AppColors.cinnabar
                    : AppColors.inkGreen,
              ),
            ),
          ),
          title: Text('${person.surname}${person.givenName}'),
          subtitle: Text(
            [
              if (person.generation != null) '第${person.generation}世'.tr,
              if (person.generationWord != null &&
                  person.generationWord!.isNotEmpty)
                person.generationWord,
              if (person.branch != null && person.branch!.isNotEmpty)
                person.branch,
            ].join(' · '),
          ),
          onTap: () {
            onClose();
            context.push('/person/${person.id}');
          },
        );
      },
    );
  }
}
