/// 成员详情页
/// 阶段 3：展示成员完整信息，支持编辑和删除
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/description_images.dart';
import '../domain/person_providers.dart';
import '../../event/domain/event_providers.dart';
import '../../relationship/domain/relationship_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 成员详情页
class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(watchPersonProvider(personId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return personAsync.when(
      data: (person) {
        if (person == null) {
          return _NotFound(isDark: isDark);
        }
        return _DetailContent(person: person, isDark: isDark);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('加载失败：$error'.tr),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: Text('返回'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 详情内容
class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.person, required this.isDark});

  final Person person;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${person.surname}${person.givenName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: '族谱树'.tr,
            onPressed: () => context.push('/person/${person.id}/tree'),
          ),
          IconButton(
            icon: const Icon(Icons.family_restroom),
            tooltip: '关系管理'.tr,
            onPressed: () =>
                context.push('/person/${person.id}/relationships'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑成员'.tr,
            onPressed: () => context.push('/person/${person.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除成员'.tr,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // 头部：头像 + 姓名 + 字/号
          _Header(person: person, isDark: isDark),
          const SizedBox(height: 8),

          // 基本信息
          _Section(
            title: '基本信息'.tr,
            icon: Icons.person_outline,
            children: [
              _InfoRow(label: '性别'.tr, value: _genderLabel(person.gender)),
              if (person.generation != null)
                _InfoRow(label: '世代'.tr, value: '第 ${person.generation} 世'.tr),
              if (person.generationWord != null &&
                  person.generationWord!.isNotEmpty)
                _InfoRow(label: '字辈'.tr, value: person.generationWord!),
              if (person.branch != null && person.branch!.isNotEmpty)
                _InfoRow(label: '房支'.tr, value: person.branch!),
              if (person.rank != null)
                _InfoRow(label: '排行'.tr, value: '第 ${person.rank}'.tr),
              if (person.courtesyName != null &&
                  person.courtesyName!.isNotEmpty)
                _InfoRow(label: '字'.tr, value: person.courtesyName!),
              if (person.artName != null && person.artName!.isNotEmpty)
                _InfoRow(label: '号'.tr, value: person.artName!),
            ],
          ),
          const SizedBox(height: 8),

          // 家族关系（父母/配偶/子女/兄弟姐妹）
          _RelationsSection(personId: person.id),
          const SizedBox(height: 8),

          // 生卒信息
          _Section(
            title: '生卒婚葬'.tr,
            icon: Icons.event_available,
            children: [
              _InfoRow(
                label: '状态'.tr,
                value: person.isAlive ? '在世'.tr : '已故'.tr,
                valueColor:
                    person.isAlive ? AppColors.success : AppColors.inkGray,
              ),
              if (person.birthDate != null)
                _InfoRow(
                    label: '生日'.tr,
                    value: _formatDate(person.birthDate!)),
              if (person.deathDate != null)
                _InfoRow(
                    label: '忌日'.tr,
                    value: _formatDate(person.deathDate!)),
              if (person.birthPlace != null &&
                  person.birthPlace!.isNotEmpty)
                _InfoRow(label: '出生地'.tr, value: person.birthPlace!),
              if (person.deathPlace != null &&
                  person.deathPlace!.isNotEmpty)
                _InfoRow(label: '去世地'.tr, value: person.deathPlace!),
              if (person.burialPlace != null &&
                  person.burialPlace!.isNotEmpty)
                _InfoRow(label: '葬地'.tr, value: person.burialPlace!),
            ],
          ),
          const SizedBox(height: 8),

          // 职业功名
          if ((person.occupation != null &&
                  person.occupation!.isNotEmpty) ||
              (person.title != null && person.title!.isNotEmpty))
            _Section(
              title: '职业功名'.tr,
              icon: Icons.work_outline,
              children: [
                if (person.occupation != null &&
                    person.occupation!.isNotEmpty)
                  _InfoRow(label: '职业'.tr, value: person.occupation!),
                if (person.title != null && person.title!.isNotEmpty)
                  _InfoRow(label: '功名'.tr, value: person.title!),
              ],
            ),
          const SizedBox(height: 8),

          // 简介
          if (person.biography != null && person.biography!.isNotEmpty)
            _Section(
              title: '人物简介'.tr,
              icon: Icons.article_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: DescriptionRichText(
                    text: person.biography!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.inkBlack,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),

          // 事件
          _PersonEventsSection(personId: person.id),
        ],
      ),
    );
  }

  String _genderLabel(Gender g) {
    switch (g) {
      case Gender.male:
        return '男'.tr;
      case Gender.female:
        return '女'.tr;
      case Gender.other:
        return '其他'.tr;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}年${d.month}月${d.day}日'.tr;
  }

  /// 删除确认
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cinnabar,
            ),
            onPressed: () => Navigator.of(context).pop(true),
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
      context.pop();
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

/// 头部区域
class _Header extends ConsumerWidget {
  const _Header({required this.person, required this.isDark});

  final Person person;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          // 大头像
          _LargeAvatar(person: person),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${person.surname}${person.givenName}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.inkBlack,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 6),
                // 字/号
                Wrap(
                  spacing: 12,
                  children: [
                    if (person.courtesyName != null &&
                        person.courtesyName!.isNotEmpty)
                      Text('字 · ${person.courtesyName}'.tr,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.inkGray)),
                    if (person.artName != null &&
                        person.artName!.isNotEmpty)
                      Text('号 · ${person.artName}'.tr,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.inkGray)),
                  ],
                ),
                const SizedBox(height: 8),
                // 状态标签
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (person.isAlive
                                ? AppColors.success
                                : AppColors.inkGray)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        person.isAlive ? '在世'.tr : '已故'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: person.isAlive
                              ? AppColors.success
                              : AppColors.inkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      person.gender == Gender.female
                          ? Icons.female
                          : Icons.male,
                      size: 18,
                      color: person.gender == Gender.female
                          ? AppColors.cinnabar
                          : AppColors.info,
                    ),
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

/// 大头像
class _LargeAvatar extends ConsumerWidget {
  const _LargeAvatar({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaId = person.avatarMediaId;
    if (mediaId == null) {
      return _InitialAvatar(person: person);
    }
    return FutureBuilder<MediaTableData?>(
      future: ref.read(personRepositoryProvider).getMediaById(mediaId),
      builder: (context, snapshot) {
        final media = snapshot.data;
        if (media != null && File(media.path).existsSync()) {
          return ClipOval(
            child: Image.file(
              File(media.path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          );
        }
        return _InitialAvatar(person: person);
      },
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final char = person.surname.isNotEmpty
        ? person.surname.characters.first
        : '?';
    final isFemale = person.gender == Gender.female;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isFemale ? AppColors.cinnabar : AppColors.inkGreen)
            .withOpacity(0.12),
        border: Border.all(
          color: (isFemale ? AppColors.cinnabar : AppColors.inkGreen)
              .withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isFemale ? AppColors.cinnabar : AppColors.inkGreen,
          ),
        ),
      ),
    );
  }
}

/// 成员事件列表分区
class _PersonEventsSection extends ConsumerWidget {
  const _PersonEventsSection({required this.personId});

  final int personId;

  // 事件类型图标和颜色
  static final Map<EventType, (IconData, Color)> _typeConfig = {
    EventType.birth: (Icons.child_care, AppColors.info),
    EventType.marriage: (Icons.favorite, AppColors.cinnabar),
    EventType.death: (Icons.airline_seat_flat, AppColors.inkGray),
    EventType.migration: (Icons.move_down, AppColors.warning),
    EventType.honor: (Icons.emoji_events, AppColors.inkGreen),
    EventType.other: (Icons.event_note, AppColors.inkLightGray),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(watchEventsByPersonProvider(personId));

    return eventsAsync.when(
      data: (events) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline,
                        size: 18, color: AppColors.inkGreen),
                    const SizedBox(width: 8),
                    Text(
                      '人生事件'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkBlack,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      // 用 push 而非 go：go 会替换整个导航栈，保存后返回就退出了
                      // 详情页（本文件其它入口也都是 push）
                      onPressed: () => context
                          .push('/event/new?personId=$personId'),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('添加'.tr),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '暂无事件记录'.tr,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.inkGray),
                    ),
                  )
                else
                  ...events.map((event) {
                    final config = _typeConfig[event.type] ??
                        _typeConfig[EventType.other]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: config.$2.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(config.$1,
                                size: 14, color: config.$2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                                if (event.date != null)
                                  Text(
                                    '${'${event.date!.year}年${event.date!.month}月${event.date!.day}日'.tr}${event.place != null && event.place!.isNotEmpty ? ' · ${event.place}' : ''}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkGray),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 16),
                            tooltip: '编辑事件'.tr,
                            onPressed: () =>
                                context.push('/event/${event.id}/edit'),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('事件加载失败：$e'.tr),
        ),
      ),
    );
  }
}

/// 信息分区
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.inkGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.inkGray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? AppColors.inkBlack,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 成员不存在
class _NotFound extends StatelessWidget {
  const _NotFound({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('成员详情'.tr)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined,
                size: 48, color: AppColors.inkGray),
            const SizedBox(height: 16),
            Text(
              '成员不存在或已被删除'.tr,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkOnSurface : AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text('返回'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

/// 家族关系区域：展示父母、配偶、子女、兄弟姐妹，可点击跳转
class _RelationsSection extends ConsumerWidget {
  const _RelationsSection({required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(parentsProvider(personId));
    final spousesAsync = ref.watch(spousesProvider(personId));
    final childrenAsync = ref.watch(childrenProvider(personId));
    final siblingsAsync = ref.watch(siblingsProvider(personId));

    // 查询出错时不能静默显示「暂无关系记录」——那会让用户以为数据丢了。
    // valueOrNull 在 error 时返回 null，所以必须先查 hasError。
    final firstError = [parentsAsync, spousesAsync, childrenAsync, siblingsAsync]
        .where((a) => a.hasError)
        .map((a) => a.error)
        .firstOrNull;
    if (firstError != null) {
      return _Section(
        title: '家族关系'.tr,
        icon: Icons.family_restroom,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '关系记录加载失败：$firstError'.tr,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // 还在加载时不显示「暂无」结论，避免先闪一下空态
    final stillLoading = [parentsAsync, spousesAsync, childrenAsync, siblingsAsync]
        .any((a) => a.isLoading);
    if (stillLoading) {
      return _Section(
        title: '家族关系'.tr,
        icon: Icons.family_restroom,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      );
    }

    // 所有关系都为空时不显示
    final hasAny = (parentsAsync.valueOrNull?.isNotEmpty ?? false) ||
        (spousesAsync.valueOrNull?.isNotEmpty ?? false) ||
        (childrenAsync.valueOrNull?.isNotEmpty ?? false) ||
        (siblingsAsync.valueOrNull?.isNotEmpty ?? false);

    if (!hasAny) {
      return _Section(
        title: '家族关系'.tr,
        icon: Icons.family_restroom,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '暂无关系记录，点击右上角「关系管理」添加'.tr,
              style: const TextStyle(color: AppColors.inkGray, fontSize: 13),
            ),
          ),
        ],
      );
    }

    return _Section(
      title: '家族关系'.tr,
      icon: Icons.family_restroom,
      children: [
        // 父母
        if (parentsAsync.valueOrNull?.isNotEmpty ?? false)
          _RelationGroup(
            label: '父母'.tr,
            persons: parentsAsync.value!,
          ),
        // 配偶
        if (spousesAsync.valueOrNull?.isNotEmpty ?? false)
          _RelationGroup(
            label: '配偶'.tr,
            persons: spousesAsync.value!.map((e) => e.person).toList(),
          ),
        // 子女
        if (childrenAsync.valueOrNull?.isNotEmpty ?? false)
          _RelationGroup(
            label: '子女'.tr,
            persons: childrenAsync.value!,
          ),
        // 兄弟姐妹
        if (siblingsAsync.valueOrNull?.isNotEmpty ?? false)
          _RelationGroup(
            label: '兄弟姐妹'.tr,
            persons: siblingsAsync.value!,
          ),
      ],
    );
  }
}

/// 一组关系（如父母、子女）
class _RelationGroup extends StatelessWidget {
  const _RelationGroup({required this.label, required this.persons});

  final String label;
  final List<Person> persons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.inkGray, fontSize: 13),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: persons.map((p) {
                final isFemale = p.gender == Gender.female;
                return GestureDetector(
                  onTap: () => context.push('/person/${p.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFemale
                          ? AppColors.cinnabar.withOpacity(0.08)
                          : AppColors.inkGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isFemale
                            ? AppColors.cinnabar.withOpacity(0.3)
                            : AppColors.inkGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${p.surname}${p.givenName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isFemale
                            ? AppColors.cinnabar
                            : AppColors.inkGreen,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
