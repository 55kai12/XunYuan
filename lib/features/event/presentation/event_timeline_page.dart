/// 事件时间线页
/// 阶段 5：按时间倒序展示家族事件，支持家族筛选、类型筛选
/// 替换原空状态时间线页
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/event_image_store.dart';
import '../../family/domain/family_providers.dart';
import '../../person/domain/person_providers.dart';
import '../domain/event_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 事件类型配置（与编辑页一致）
class _TimelineEventTypeConfig {
  const _TimelineEventTypeConfig(this.type, this.label, this.icon, this.color);

  final EventType type;
  final String label;
  final IconData icon;
  final Color color;
}

List<_TimelineEventTypeConfig> _timelineEventTypes = [
  _TimelineEventTypeConfig(
      EventType.birth, '出生'.tr, Icons.child_care, AppColors.info),
  _TimelineEventTypeConfig(
      EventType.marriage, '结婚'.tr, Icons.favorite, AppColors.cinnabar),
  _TimelineEventTypeConfig(
      EventType.death, '去世'.tr, Icons.airline_seat_flat, AppColors.inkGray),
  _TimelineEventTypeConfig(
      EventType.migration, '迁徙'.tr, Icons.move_down, AppColors.warning),
  _TimelineEventTypeConfig(EventType.honor, '功名'.tr,
      Icons.emoji_events, AppColors.inkGreen),
  _TimelineEventTypeConfig(
      EventType.other, '其他'.tr, Icons.event_note, AppColors.inkLightGray),
];

_TimelineEventTypeConfig _configFor(EventType type) {
  return _timelineEventTypes.firstWhere(
    (c) => c.type == type,
    orElse: () => _timelineEventTypes.last,
  );
}

/// 时间线页
class EventTimelinePage extends ConsumerStatefulWidget {
  const EventTimelinePage({super.key, this.initialTreeId});

  /// 初始家族筛选（从家族首页「事件时间线」入口进入时传入）
  final int? initialTreeId;

  @override
  ConsumerState<EventTimelinePage> createState() =>
      _EventTimelinePageState();
}

class _EventTimelinePageState extends ConsumerState<EventTimelinePage> {
  int? _selectedTreeId;
  EventType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedTreeId = widget.initialTreeId;
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(watchFamiliesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 根据筛选条件获取事件
    final eventsAsync = _selectedTreeId != null
        ? ref.watch(watchEventsByTreeProvider(_selectedTreeId!))
        : _watchAllEvents(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text('事件时间线'.tr),
        actions: [
          // 类型筛选
          PopupMenuButton<EventType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: '按类型筛选'.tr,
            onSelected: (type) {
              setState(() => _selectedType = type);
            },
            itemBuilder: (context) => [
              PopupMenuItem<EventType?>(
                value: null,
                child: Text('全部类型'.tr),
              ),
              ..._timelineEventTypes.map((c) => PopupMenuItem<EventType?>(
                    value: c.type,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18, color: c.color),
                        const SizedBox(width: 8),
                        Text(c.label),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 家族筛选条
          familiesAsync.when(
            data: (families) {
              if (families.length <= 1) return const SizedBox.shrink();
              return Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: families.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _FilterChip(
                        label: '全部家族'.tr,
                        selected: _selectedTreeId == null,
                        onTap: () =>
                            setState(() => _selectedTreeId = null),
                      );
                    }
                    final family = families[index - 1];
                    return _FilterChip(
                      label: family.name,
                      selected: _selectedTreeId == family.id,
                      onTap: () =>
                          setState(() => _selectedTreeId = family.id),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 事件列表
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                // 应用类型筛选
                final filtered = _selectedType != null
                    ? events
                        .where((e) => e.type == _selectedType)
                        .toList()
                    : events;

                if (filtered.isEmpty) {
                  return _EmptyState(
                    isDark: isDark,
                    hasFilter: _selectedTreeId != null ||
                        _selectedType != null,
                    onCreate: () => context.push('/event/new'),
                  );
                }
                return _TimelineList(events: filtered);
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('加载失败：$error'.tr)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(_selectedTreeId != null
            ? '/event/new?treeId=$_selectedTreeId'
            : '/event/new'),
        tooltip: '添加事件'.tr,
        child: const Icon(Icons.event),
      ),
    );
  }

  /// 监听所有家族的事件（合并流）
  AsyncValue<List<Event>> _watchAllEvents(WidgetRef ref) {
    final familiesAsync = ref.watch(watchFamiliesProvider);
    return familiesAsync.when(
      data: (families) {
        if (families.isEmpty) {
          return const AsyncData(<Event>[]);
        }
        // 监听每个家族的事件并合并
        final streams = families
            .map((f) =>
                ref.watch(watchEventsByTreeProvider(f.id)))
            .toList();
        // 简化：取第一个有数据的，实际应合并
        // 由于 Riverpod 不支持简单的流合并，这里用第一个家族的事件
        // 多家族时建议用家族筛选
        if (streams.isNotEmpty) {
          return streams.first.whenData((events) {
            // 合并所有家族的事件
            final allEvents = <Event>[];
            for (final s in streams) {
              s.maybeWhen(
                data: (e) => allEvents.addAll(e),
                orElse: () {},
              );
            }
            allEvents.sort((a, b) {
              final dateCompare =
                  (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0));
              if (dateCompare != 0) return dateCompare;
              return b.id.compareTo(a.id);
            });
            return allEvents;
          });
        }
        return const AsyncData(<Event>[]);
      },
      loading: () => const AsyncLoading(),
      error: (e, s) => AsyncError(e, s),
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

/// 时间线列表
class _TimelineList extends ConsumerWidget {
  const _TimelineList({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 按年份分组
    final grouped = <int?, List<Event>>{};
    for (final e in events) {
      final year = e.date?.year;
      grouped.putIfAbsent(year, () => []).add(e);
    }
    final years = grouped.keys.toList()
      ..sort((a, b) => (b ?? 0).compareTo(a ?? 0));

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: 80 + MediaQuery.of(context).padding.bottom,
        top: 8,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final yearEvents = grouped[year]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 年份标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.inkGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      year != null ? '$year 年'.tr : '日期不详'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${yearEvents.length} 件事'.tr,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkGray),
                  ),
                ],
              ),
            ),
            // 事件卡片
            ...yearEvents.map((e) => _EventCard(event: e)),
          ],
        );
      },
    );
  }
}

/// 事件卡片
class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _configFor(event.type);
    final personAsync = event.personId != null
        ? ref.watch(watchPersonProvider(event.personId!))
        : const AsyncData<Person?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间线轴
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: config.color.withOpacity(0.4)),
                ),
                child: Icon(config.icon, size: 18, color: config.color),
              ),
              Container(
                width: 2,
                height: 40,
                color: AppColors.inkLightGray.withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 事件内容
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showEventDetail(context, ref, config),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.inkBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: config.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              config.label,
                              style: TextStyle(
                                  fontSize: 10, color: config.color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 关联成员
                      personAsync.maybeWhen(
                        data: (person) {
                          if (person == null) {
                            return Text('成员已删除'.tr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkGray));
                          }
                          return Text(
                            '${person.surname}${person.givenName}'
                            '${person.generation != null ? ' · 第${person.generation}世' : ''}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.inkGray),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      // 日期和地点
                      if (event.date != null ||
                          (event.place != null &&
                              event.place!.isNotEmpty)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (event.date != null)
                              Text(
                                '${event.date!.month}月${event.date!.day}日'.tr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkGray),
                              ),
                            if (event.date != null &&
                                event.place != null &&
                                event.place!.isNotEmpty)
                              const Text(' · ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkGray)),
                            if (event.place != null &&
                                event.place!.isNotEmpty)
                              Expanded(
                                child: Text(
                                  event.place!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkGray),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                      // 描述（卡片摘要：隐藏内联图片标记，有图则提示）
                      if (event.description != null &&
                          event.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        if (EventImageStore.strip(event.description)
                            .isNotEmpty)
                          Text(
                            EventImageStore.strip(event.description),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[300]
                                  : AppColors.inkBlack.withOpacity(0.7),
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (EventImageStore.hasImages(event.description))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined,
                                    size: 14, color: AppColors.inkGray),
                                const SizedBox(width: 4),
                                Text('包含配图'.tr,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkGray)),
                              ],
                            ),
                          ),
                      ],
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

  /// 显示事件详情底部弹窗
  void _showEventDetail(BuildContext context, WidgetRef ref,
      _TimelineEventTypeConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _EventDetailSheet(
          event: event,
          config: config,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// 事件详情底部弹窗
class _EventDetailSheet extends ConsumerWidget {
  const _EventDetailSheet({
    required this.event,
    required this.config,
    required this.scrollController,
  });

  final Event event;
  final _TimelineEventTypeConfig config;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = event.personId != null
        ? ref.watch(watchPersonProvider(event.personId!))
        : const AsyncData<Person?>(null);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '编辑事件'.tr,
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/event/${event.id}/edit');
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.cinnabar),
                tooltip: '删除事件'.tr,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 类型标签
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(config.label,
                style: TextStyle(
                    fontSize: 12,
                    color: config.color,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          // 关联成员
          personAsync.maybeWhen(
            data: (person) {
              if (person == null) {
                return _DetailRow(label: '关联成员'.tr, value: '已删除'.tr);
              }
              return _DetailRow(
                label: '关联成员'.tr,
                value: '${person.surname}${person.givenName}',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/person/${person.id}');
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          if (event.date != null)
            _DetailRow(
                label: '日期'.tr,
                value:
                    '${event.date!.year}年${event.date!.month}月${event.date!.day}日'.tr),
          if (event.place != null && event.place!.isNotEmpty)
            _DetailRow(label: '地点'.tr, value: event.place!),
          if (event.description != null &&
              event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('详细描述'.tr,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkGray,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // 图文混排：文本原样展示，[img:xxx] 标记渲染为内联图片
            ...EventImageStore.parse(event.description).map(
              (s) => s.isImage
                  ? _DescriptionImage(fileName: s.imageFile!)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        s.text!,
                        style: const TextStyle(fontSize: 14, height: 1.7),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.cinnabar),
        title: Text('删除事件'.tr),
        content: Text('确定要删除「${event.title}」吗？此操作不可恢复。'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'.tr),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.cinnabar),
            onPressed: () => Navigator.pop(context, true),
            child: Text('确认删除'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(eventRepositoryProvider).delete(event.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('事件已删除'.tr)),
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

/// 描述中的内联配图（点击全屏查看）
class _DescriptionImage extends StatelessWidget {
  const _DescriptionImage({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: EventImageStore.filePath(fileName),
      builder: (context, snapshot) {
        final path = snapshot.data;
        final file = path != null ? File(path) : null;
        final exists = file != null && file.existsSync();
        if (!exists) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined,
                      size: 18, color: AppColors.inkGray),
                  const SizedBox(width: 6),
                  Text('图片已丢失'.tr,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkGray)),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _showFullScreen(context, file),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Image.file(file, fit: BoxFit.cover,
                    width: double.infinity),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullScreen(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.file(file),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 详情行
class _DetailRow extends StatelessWidget {  const _DetailRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.inkGray)),
          ),
          Expanded(
            child: onTap != null
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.inkGreen,
                          decoration: TextDecoration.underline),
                    ),
                  )
                : Text(value,
                    style: const TextStyle(fontSize: 14)),
          ),
        ],
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
                color: AppColors.inkGreen.withOpacity(0.08),
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.event_note,
                size: 44,
                color: AppColors.inkGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? '没有匹配的事件'.tr : '暂无事件'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? '尝试调整筛选条件'.tr
                  : '记录出生、结婚、迁徙、功名等家族大事'.tr,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkGray,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.event),
                label: Text('添加事件'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
