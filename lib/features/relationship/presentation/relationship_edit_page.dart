/// 关系编辑页
/// 阶段 4：管理某人的父母、配偶、子女、兄弟姐妹关系
/// 支持添加、删除、备注（继配/过继等），循环关系自动检测
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../person/domain/person_providers.dart';
import '../data/relationship_repository.dart';
import '../domain/relationship_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 关系编辑页
class RelationshipEditPage extends ConsumerStatefulWidget {
  const RelationshipEditPage({super.key, required this.personId});

  final int personId;

  @override
  ConsumerState<RelationshipEditPage> createState() =>
      _RelationshipEditPageState();
}

class _RelationshipEditPageState extends ConsumerState<RelationshipEditPage> {
  @override
  Widget build(BuildContext context) {
    final personAsync = ref.watch(watchPersonProvider(widget.personId));
    final relsAsync =
        ref.watch(watchRelationshipsProvider(widget.personId));

    return personAsync.when(
      data: (person) {
        if (person == null) {
          return Scaffold(body: Center(child: Text('成员不存在'.tr)));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${person.surname}${person.givenName} 的关系'.tr),
          ),
          body: relsAsync.when(
            data: (rels) => _buildContent(person, rels),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e'.tr)),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败：$e'.tr))),
    );
  }

  Widget _buildContent(Person person, List<Relationship> rels) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 父母
              _RelationSection(
                title: '父母'.tr,
                icon: Icons.family_restroom,
                persons: _extractRelatives(rels, person.id,
                    types: [
                      RelationType.father,
                      RelationType.mother,
                      RelationType.adoptiveFather,
                      RelationType.adoptiveMother,
                    ],
                    asTo: true),
                onAdd: () => _showAddParentDialog(person),
                onDelete: (relId) => _confirmDelete(relId, '父母关系'.tr),
                onDropPerson: (p) => _dropAsParent(person, p),
              ),
              const SizedBox(height: 8),

              // 配偶
              _RelationSection(
                title: '配偶'.tr,
                icon: Icons.favorite,
                persons: _extractRelatives(rels, person.id,
                    types: [RelationType.spouse], asTo: null),
                onAdd: () => _showAddSpouseDialog(person),
                onDelete: (relId) => _confirmDelete(relId, '配偶关系'.tr),
                onDropPerson: (p) => _dropAsSpouse(person, p),
              ),
              const SizedBox(height: 8),

              // 子女
              _RelationSection(
                title: '子女'.tr,
                icon: Icons.child_care,
                persons: _extractRelatives(rels, person.id,
                    types: [
                      RelationType.father,
                      RelationType.mother,
                      RelationType.adoptiveFather,
                      RelationType.adoptiveMother,
                    ],
                    asTo: false),
                onAdd: () => _showAddChildDialog(person),
                onDelete: (relId) => _confirmDelete(relId, '子女关系'.tr),
                onDropPerson: (p) => _dropAsChild(person, p),
              ),
              const SizedBox(height: 8),

              // 兄弟姐妹
              _RelationSection(
                title: '兄弟姐妹'.tr,
                icon: Icons.people,
                persons: _extractSiblings(rels, person.id),
                onAdd: () => _showAddSiblingDialog(person),
                onDelete: (relId) => _confirmDelete(relId, '兄弟姐妹关系'.tr),
                onDropPerson: (p) => _dropAsSibling(person, p),
              ),
              const SizedBox(height: 16),

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
                        '可从下方成员池长按拖拽成员到对应区域建立关系；也可点击「添加」按钮选择。'.tr,
                        style:
                            const TextStyle(fontSize: 12, color: AppColors.inkGray),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 可拖拽成员池
        _DraggablePersonPool(excludePersonId: person.id, treeId: person.treeId),
      ],
    );
  }

  /// 拖拽为父母
  Future<void> _dropAsParent(Person current, Person dropped) async {
    final type = dropped.gender == Gender.female
        ? RelationType.mother
        : RelationType.father;
    await _addRelation(
      treeId: current.treeId,
      fromId: dropped.id,
      toId: current.id,
      type: type,
    );
  }

  /// 拖拽为配偶
  Future<void> _dropAsSpouse(Person current, Person dropped) async {
    await _addRelation(
      treeId: current.treeId,
      fromId: current.id,
      toId: dropped.id,
      type: RelationType.spouse,
    );
  }

  /// 拖拽为子女
  Future<void> _dropAsChild(Person current, Person dropped) async {
    final type = current.gender == Gender.female
        ? RelationType.mother
        : RelationType.father;
    await _addRelation(
      treeId: current.treeId,
      fromId: current.id,
      toId: dropped.id,
      type: type,
    );
  }

  /// 拖拽为兄弟姐妹
  Future<void> _dropAsSibling(Person current, Person dropped) async {
    await _addRelation(
      treeId: current.treeId,
      fromId: current.id,
      toId: dropped.id,
      type: RelationType.sibling,
    );
  }

  /// 从关系列表中提取亲属
  /// 只带 relativeId，成员信息由 _RelationItem 通过 watchPersonProvider 自行加载
  List<({int personId, Relationship rel, String label})> _extractRelatives(
    List<Relationship> rels,
    int personId, {
    required List<RelationType> types,
    required bool? asTo, // true: person 是 to；false: person 是 from；null: 两种都算
  }) {
    final result = <({int personId, Relationship rel, String label})>[];
    for (final r in rels) {
      if (!types.contains(r.type)) continue;
      int? relativeId;
      if (asTo == true && r.toPersonId == personId) {
        relativeId = r.fromPersonId;
      } else if (asTo == false && r.fromPersonId == personId) {
        relativeId = r.toPersonId;
      } else if (asTo == null) {
        relativeId = r.fromPersonId == personId
            ? r.toPersonId
            : (r.toPersonId == personId ? r.fromPersonId : null);
      }
      if (relativeId == null) continue;
      result.add((
        personId: relativeId,
        rel: r,
        label: _relationLabel(r.type, r.fromPersonId == personId),
      ));
    }
    return result;
  }

  List<({int personId, Relationship rel, String label})> _extractSiblings(
      List<Relationship> rels, int personId) {
    // 兄弟姐妹通过 sibling 类型直接存储
    return _extractRelatives(rels, personId,
        types: [RelationType.sibling], asTo: null);
  }

  String _relationLabel(RelationType type, bool isFrom) {
    switch (type) {
      case RelationType.father:
        return isFrom ? '子女'.tr : '父亲'.tr;
      case RelationType.mother:
        return isFrom ? '子女'.tr : '母亲'.tr;
      case RelationType.adoptiveFather:
        return isFrom ? '养子女'.tr : '养父'.tr;
      case RelationType.adoptiveMother:
        return isFrom ? '养子女'.tr : '养母'.tr;
      case RelationType.spouse:
        return '配偶'.tr;
      case RelationType.child:
        return isFrom ? '子女'.tr : '父母'.tr;
      case RelationType.sibling:
        return '兄弟姐妹'.tr;
    }
  }

  // ==================== 添加关系对话框 ====================

  /// 添加父母
  Future<void> _showAddParentDialog(Person person) async {
    final selected = await _showPersonPicker(
      title: '选择父亲或母亲'.tr,
      excludeId: person.id,
    );
    if (selected == null) return;

    final type = await _showGenderTypeDialog(
      title: '选择关系类型'.tr,
      maleLabel: '父亲'.tr,
      femaleLabel: '母亲'.tr,
      adoptiveMaleLabel: '养父'.tr,
      adoptiveFemaleLabel: '养母'.tr,
      selectedGender: selected.gender,
    );
    if (type == null) return;

    await _addRelation(
      treeId: person.treeId,
      fromId: selected.id,
      toId: person.id,
      type: type,
    );
  }

  /// 添加配偶
  Future<void> _showAddSpouseDialog(Person person) async {
    final selected = await _showPersonPicker(
      title: '选择配偶'.tr,
      excludeId: person.id,
    );
    if (selected == null) return;
    if (!mounted) return;

    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('配偶备注'.tr),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: '备注（可选）'.tr,
            hintText: '例如：继配、元配'.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: Text('确认'.tr),
          ),
        ],
      ),
    );

    await _addRelation(
      treeId: person.treeId,
      fromId: person.id,
      toId: selected.id,
      type: RelationType.spouse,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
    );
  }

  /// 添加子女
  Future<void> _showAddChildDialog(Person person) async {
    final selected = await _showPersonPicker(
      title: '选择子女'.tr,
      excludeId: person.id,
    );
    if (selected == null) return;

    final type = person.gender == Gender.female
        ? RelationType.mother
        : RelationType.father;

    await _addRelation(
      treeId: person.treeId,
      fromId: person.id,
      toId: selected.id,
      type: type,
    );
  }

  /// 添加兄弟姐妹
  Future<void> _showAddSiblingDialog(Person person) async {
    final selected = await _showPersonPicker(
      title: '选择兄弟姐妹'.tr,
      excludeId: person.id,
    );
    if (selected == null) return;

    await _addRelation(
      treeId: person.treeId,
      fromId: person.id,
      toId: selected.id,
      type: RelationType.sibling,
    );
  }

  /// 人员选择器
  Future<Person?> _showPersonPicker({
    required String title,
    int? excludeId,
  }) async {
    final persons = await ref
        .read(personRepositoryProvider)
        .watchAll()
        .first;
    final filtered =
        persons.where((p) => p.id != excludeId).toList();

    if (!mounted) return null;

    return showDialog<Person>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('暂无可选成员，请先添加成员'.tr),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            (p.gender == Gender.female
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
                        p.generation != null
                            ? '第 ${p.generation} 世'.tr
                            : '未分世代'.tr,
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

  /// 性别类型选择对话框
  Future<RelationType?> _showGenderTypeDialog({
    required String title,
    required String maleLabel,
    required String femaleLabel,
    String? adoptiveMaleLabel,
    String? adoptiveFemaleLabel,
    required Gender selectedGender,
  }) async {
    return showDialog<RelationType>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedGender != Gender.female)
              ListTile(
                title: Text(maleLabel),
                onTap: () =>
                    Navigator.pop(context, RelationType.father),
              ),
            if (selectedGender != Gender.male)
              ListTile(
                title: Text(femaleLabel),
                onTap: () =>
                    Navigator.pop(context, RelationType.mother),
              ),
            if (adoptiveMaleLabel != null &&
                selectedGender != Gender.female)
              ListTile(
                title: Text(adoptiveMaleLabel),
                onTap: () => Navigator.pop(
                    context, RelationType.adoptiveFather),
              ),
            if (adoptiveFemaleLabel != null &&
                selectedGender != Gender.male)
              ListTile(
                title: Text(adoptiveFemaleLabel),
                onTap: () => Navigator.pop(
                    context, RelationType.adoptiveMother),
              ),
          ],
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

  // ==================== 通用操作 ====================

  /// 添加关系
  Future<void> _addRelation({
    required int treeId,
    required int fromId,
    required int toId,
    required RelationType type,
    String? note,
  }) async {
    try {
      await ref.read(relationshipRepositoryProvider).insert(
            treeId: treeId,
            fromPersonId: fromId,
            toPersonId: toId,
            type: type,
            note: note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('关系添加成功'.tr)),
      );
    } on RelationshipException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法添加：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// 确认删除关系
  Future<void> _confirmDelete(int relId, String relationName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.cinnabar),
        title: Text('删除$relationName'.tr),
        content: Text('确定要删除这条关系吗？此操作不可恢复。'.tr),
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
      await ref.read(relationshipRepositoryProvider).delete(relId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('关系已删除'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// 关系分区（支持拖拽成员到此处建立关系）
class _RelationSection extends StatelessWidget {
  const _RelationSection({
    required this.title,
    required this.icon,
    required this.persons,
    required this.onAdd,
    required this.onDelete,
    this.onDropPerson,
  });

  final String title;
  final IconData icon;
  final List<({int personId, Relationship rel, String label})> persons;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  final ValueChanged<Person>? onDropPerson;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Person>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onDropPerson?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;
        return Card(
          color: isDraggingOver
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDraggingOver
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: isDraggingOver ? 2 : 0,
            ),
          ),
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
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('添加'.tr),
                    ),
                  ],
                ),
                if (isDraggingOver)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '松开即可添加为$title'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                if (persons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '暂无记录，可从下方成员池拖拽到此'.tr,
                      style:
                          const TextStyle(fontSize: 13, color: AppColors.inkGray),
                    ),
                  )
                else
                  ...persons.map((item) => _RelationItem(
                        personId: item.personId,
                        label: item.label,
                        note: item.rel.note,
                        onDelete: () => onDelete(item.rel.id),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 关系条目（异步加载成员姓名）
class _RelationItem extends ConsumerWidget {
  const _RelationItem({
    required this.personId,
    required this.label,
    required this.note,
    required this.onDelete,
  });

  final int personId;
  final String label;
  final String? note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(watchPersonProvider(personId));
    return personAsync.when(
      data: (person) {
        if (person == null) {
          return ListTile(
            title: Text('成员已删除'.tr),
            dense: true,
          );
        }
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: (person.gender == Gender.female
                    ? AppColors.cinnabar
                    : AppColors.inkGreen)
                .withOpacity(0.12),
            child: Text(
              person.surname.isNotEmpty
                  ? person.surname.characters.first
                  : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: person.gender == Gender.female
                    ? AppColors.cinnabar
                    : AppColors.inkGreen,
              ),
            ),
          ),
          title: Text(
            '${person.surname}${person.givenName}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            [label, if (note != null && note!.isNotEmpty) '备注：$note'.tr]
                .join(' · '),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: '删除关系'.tr,
            onPressed: onDelete,
          ),
          onTap: () => context.push('/person/$personId'),
        );
      },
      loading: () => ListTile(
        title: Text('加载中…'.tr),
        dense: true,
      ),
      error: (e, _) => ListTile(
        title: Text('加载失败：$e'.tr),
        dense: true,
      ),
    );
  }
}

/// 可拖拽成员池：底部横向滚动的成员列表，可拖拽到关系区域
class _DraggablePersonPool extends ConsumerWidget {
  const _DraggablePersonPool({
    required this.excludePersonId,
    required this.treeId,
  });

  final int excludePersonId;
  final int treeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(watchPersonsByTreeProvider(treeId));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.people_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    '成员池（长按拖拽到上方区域）'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: personsAsync.when(
                data: (persons) {
                  final filtered = persons
                      .where((p) => p.id != excludePersonId)
                      .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无可拖拽成员'.tr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final person = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Draggable<Person>(
                          data: person,
                          feedback: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: (person.gender ==
                                                Gender.female
                                            ? AppColors.cinnabar
                                            : AppColors.inkGreen)
                                        .withOpacity(0.2),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    '${person.surname}${person.givenName}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _PoolPersonChip(person: person),
                          ),
                          child: _PoolPersonChip(person: person),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('加载失败：$e'.tr,
                      style: const TextStyle(fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 成员池中的成员卡片
class _PoolPersonChip extends StatelessWidget {
  const _PoolPersonChip({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (person.gender == Gender.female
                    ? AppColors.cinnabar
                    : AppColors.inkGreen)
                .withOpacity(0.15),
            child: Text(
              person.surname.isNotEmpty
                  ? person.surname.characters.first
                  : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: person.gender == Gender.female
                    ? AppColors.cinnabar
                    : AppColors.inkGreen,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${person.surname}${person.givenName}',
            style: const TextStyle(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
