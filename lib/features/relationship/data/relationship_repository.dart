/// 关系数据仓库
/// 封装对 Relationships 表的读写，支持循环检测、关系网络查询、族谱树构建
library;

import 'package:drift/drift.dart';

import '../../../core/database/database.dart';

import '../../../core/i18n/i18n.dart';
/// 关系数据仓库
class RelationshipRepository {
  RelationshipRepository(this._db);

  final AppDatabase _db;

  // ==================== 增删改 ====================

  /// 新增关系
  /// [fromPersonId] 关系发起方，[toPersonId] 关系接收方
  /// 例如 type=father 时：from 是父亲，to 是子女
  Future<int> insert({
    required int treeId,
    required int fromPersonId,
    required int toPersonId,
    required RelationType type,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) async {
    // 循环检测
    final cycleError = await detectCycle(
      fromPersonId: fromPersonId,
      toPersonId: toPersonId,
      type: type,
    );
    if (cycleError != null) {
      throw RelationshipException(cycleError);
    }

    // 重复检测：同一对人同一类型不重复创建
    final existing = await (_db.select(_db.relationships)
          ..where((tbl) =>
              tbl.fromPersonId.equals(fromPersonId) &
              tbl.toPersonId.equals(toPersonId) &
              tbl.type.equals(type.name)))
        .getSingleOrNull();
    if (existing != null) {
      throw RelationshipException('该关系已存在'.tr);
    }

    // 唯一性检测：同一个人最多一位父亲 / 母亲 / 养父 / 养母
    // （否则 getFather/getMother 的单行查询会抛异常，详情页和族谱树崩溃）
    final parentLabels = {
      RelationType.father: '父亲'.tr,
      RelationType.mother: '母亲'.tr,
      RelationType.adoptiveFather: '养父'.tr,
      RelationType.adoptiveMother: '养母'.tr,
    };
    if (parentLabels.containsKey(type)) {
      final sameRole = await (_db.select(_db.relationships)
            ..where((tbl) =>
                tbl.toPersonId.equals(toPersonId) &
                tbl.type.equals(type.name)))
          .get();
      if (sameRole.isNotEmpty) {
        throw RelationshipException('已存在${parentLabels[type]}，'.tr +
            '请先删除原有关系再添加'.tr);
      }
    }

    return _db.into(_db.relationships).insert(
          RelationshipsCompanion.insert(
            treeId: treeId,
            fromPersonId: fromPersonId,
            toPersonId: toPersonId,
            type: type,
            startDate: Value(startDate),
            endDate: Value(endDate),
            note: Value(note),
          ),
        );
  }

  /// 更新关系备注/日期
  Future<bool> update({
    required int id,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) async {
    final updated = await (_db.update(_db.relationships)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      RelationshipsCompanion(
        startDate: Value(startDate),
        endDate: Value(endDate),
        note: Value(note),
      ),
    );
    return updated > 0;
  }

  /// 删除关系
  Future<void> delete(int relationshipId) async {
    await (_db.delete(_db.relationships)
          ..where((tbl) => tbl.id.equals(relationshipId)))
        .go();
  }

  // ==================== 查询 ====================

  /// 获取某人的所有关系
  Future<List<Relationship>> getRelationshipsForPerson(int personId) async {
    return (_db.select(_db.relationships)
          ..where((tbl) =>
              tbl.fromPersonId.equals(personId) |
              tbl.toPersonId.equals(personId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.type)]))
        .get();
  }

  /// 监听某人的所有关系
  Stream<List<Relationship>> watchRelationshipsForPerson(int personId) {
    return (_db.select(_db.relationships)
          ..where((tbl) =>
              tbl.fromPersonId.equals(personId) |
              tbl.toPersonId.equals(personId)))
        .watch();
  }

  /// 获取某人的父亲（from=father, to=person）
  Future<Person?> getFather(int personId) async {
    return _getRelative(personId, RelationType.father, asTo: true);
  }

  /// 获取某人的母亲
  Future<Person?> getMother(int personId) async {
    return _getRelative(personId, RelationType.mother, asTo: true);
  }

  /// 获取某人的子女（from=person as father/mother, to=child）
  Future<List<Person>> getChildren(int personId) async {
    final rows = await (_db.select(_db.relationships)
          ..where((tbl) =>
              tbl.fromPersonId.equals(personId) &
              (tbl.type.equals(RelationType.father.name) |
                  tbl.type.equals(RelationType.mother.name) |
                  tbl.type.equals(RelationType.adoptiveFather.name) |
                  tbl.type.equals(RelationType.adoptiveMother.name))))
        .get();
    final childIds = rows.map((r) => r.toPersonId).toSet();
    if (childIds.isEmpty) return [];
    return (_db.select(_db.persons)
          ..where((tbl) => tbl.id.isIn(childIds))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.rank)]))
        .get();
  }

  /// 获取某人的配偶
  Future<List<({Person person, Relationship rel})>> getSpouses(
      int personId) async {
    final rows = await (_db.select(_db.relationships)
          ..where((tbl) =>
              tbl.type.equals(RelationType.spouse.name) &
              (tbl.fromPersonId.equals(personId) |
                  tbl.toPersonId.equals(personId))))
        .get();
    final result = <({Person person, Relationship rel})>[];
    for (final r in rows) {
      final spouseId =
          r.fromPersonId == personId ? r.toPersonId : r.fromPersonId;
      final person = await (_db.select(_db.persons)
            ..where((tbl) => tbl.id.equals(spouseId)))
          .getSingleOrNull();
      if (person != null) {
        result.add((person: person, rel: r));
      }
    }
    return result;
  }

  /// 获取某人的兄弟姐妹（通过共同父母）
  Future<List<Person>> getSiblings(int personId) async {
    // 找到此人的父母
    final parentRels = await (_db.select(_db.relationships)
          ..where((tbl) =>
              tbl.toPersonId.equals(personId) &
              (tbl.type.equals(RelationType.father.name) |
                  tbl.type.equals(RelationType.mother.name))))
        .get();
    final parentIds = parentRels.map((r) => r.fromPersonId).toSet();
    if (parentIds.isEmpty) return [];

    // 找到这些父母的所有子女
    final siblingRels = await (_db.select(_db.relationships)
          ..where((tbl) =>
              tbl.fromPersonId.isIn(parentIds) &
              (tbl.type.equals(RelationType.father.name) |
                  tbl.type.equals(RelationType.mother.name))))
        .get();
    final siblingIds = siblingRels
        .map((r) => r.toPersonId)
        .where((id) => id != personId)
        .toSet();
    if (siblingIds.isEmpty) return [];

    return (_db.select(_db.persons)
          ..where((tbl) => tbl.id.isIn(siblingIds))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.rank)]))
        .get();
  }

  // ==================== 循环检测 ====================

  /// 检测是否会形成循环关系
  /// 返回错误信息，无循环返回 null
  Future<String?> detectCycle({
    required int fromPersonId,
    required int toPersonId,
    required RelationType type,
  }) async {
    // 自己和自己不能建立关系
    if (fromPersonId == toPersonId) {
      return '不能与自己建立关系'.tr;
    }

    // 父母关系：to 不能是 from 的祖先（防止孙辈成为祖辈）
    if (type == RelationType.father ||
        type == RelationType.mother ||
        type == RelationType.adoptiveFather ||
        type == RelationType.adoptiveMother) {
      if (await _isAncestor(
          ancestorId: toPersonId, descendantId: fromPersonId)) {
        return '循环关系：成员#$toPersonId 已经是成员#$fromPersonId 的后代'.tr;
      }
      if (await _isAncestor(
          ancestorId: fromPersonId, descendantId: toPersonId)) {
        return '循环关系：成员#$fromPersonId 已经是成员#$toPersonId 的祖先'.tr;
      }
    }

    // 子女关系（from 是父母，to 是子女）
    if (type == RelationType.child) {
      if (await _isAncestor(
          ancestorId: fromPersonId, descendantId: toPersonId)) {
        return '循环关系：成员#$fromPersonId 已经是成员#$toPersonId 的祖先'.tr;
      }
      if (await _isAncestor(
          ancestorId: toPersonId, descendantId: fromPersonId)) {
        return '循环关系：成员#$toPersonId 已经是成员#$fromPersonId 的后代'.tr;
      }
    }

    // 配偶关系：不能是直系亲属
    if (type == RelationType.spouse) {
      if (await _isAncestor(
              ancestorId: fromPersonId, descendantId: toPersonId) ||
          await _isAncestor(
              ancestorId: toPersonId, descendantId: fromPersonId)) {
        return '配偶不能是直系亲属'.tr;
      }
    }

    return null;
  }

  /// 判断 [ancestorId] 是否是 [descendantId] 的祖先（递归向上查找）
  Future<bool> _isAncestor({
    required int ancestorId,
    required int descendantId,
  }) async {
    final visited = <int>{};
    final queue = [descendantId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == ancestorId) return true;
      if (visited.contains(current)) continue;
      visited.add(current);

      // 找 current 的父母（child 类型方向相反：from=父母，to=子女，同样参与爬升）
      final parentRels = await (_db.select(_db.relationships)
            ..where((tbl) =>
                tbl.toPersonId.equals(current) &
                (tbl.type.equals(RelationType.father.name) |
                    tbl.type.equals(RelationType.mother.name) |
                    tbl.type.equals(RelationType.adoptiveFather.name) |
                    tbl.type.equals(RelationType.adoptiveMother.name) |
                    tbl.type.equals(RelationType.child.name))))
          .get();
      for (final r in parentRels) {
        if (!visited.contains(r.fromPersonId)) {
          queue.add(r.fromPersonId);
        }
      }
    }
    return false;
  }

  // ==================== 族谱树构建 ====================

  /// 以 [rootPersonId] 为根构建后代树（含配偶）
  /// 返回树的根节点，maxDepth 限制最大深度防止无限递归
  Future<TreeNode> buildDescendantTree({
    required int rootPersonId,
    int maxDepth = 20,
  }) async {
    final person = await _getPerson(rootPersonId);
    final spouses = await getSpouses(rootPersonId);
    final children = await getChildren(rootPersonId);

    final childNodes = <TreeNode>[];
    if (maxDepth > 0) {
      for (final child in children) {
        childNodes.add(await buildDescendantTree(
          rootPersonId: child.id,
          maxDepth: maxDepth - 1,
        ));
      }
    }

    return TreeNode(
      person: person!,
      spouses: spouses.map((s) => s.person).toList(),
      children: childNodes,
    );
  }

  /// 获取某人的父母（用于族谱树顶部展示）
  Future<List<Person>> getParents(int personId) async {
    final result = <Person>[];
    final father = await getFather(personId);
    final mother = await getMother(personId);
    if (father != null) result.add(father);
    if (mother != null) result.add(mother);
    return result;
  }

  // ==================== 内部工具 ====================

  Future<Person?> _getRelative(int personId, RelationType type,
      {required bool asTo}) async {
    final query = _db.select(_db.relationships);
    if (asTo) {
      query.where((tbl) =>
          tbl.toPersonId.equals(personId) & tbl.type.equals(type.name));
    } else {
      query.where((tbl) =>
          tbl.fromPersonId.equals(personId) & tbl.type.equals(type.name));
    }
    // 取第一条而不是 getSingleOrNull：历史数据中可能存在重复关系，
    // 单行断言会让详情页 / 族谱树直接抛异常
    final rows = await query.get();
    if (rows.isEmpty) return null;
    final rel = rows.first;
    final relativeId = asTo ? rel.fromPersonId : rel.toPersonId;
    return _getPerson(relativeId);
  }

  Future<Person?> _getPerson(int id) {
    return (_db.select(_db.persons)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }
}

/// 关系异常
class RelationshipException implements Exception {
  const RelationshipException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 族谱树节点
class TreeNode {
  TreeNode({
    required this.person,
    this.spouses = const [],
    this.children = const [],
  });

  final Person person;

  /// 全部配偶（旧式家族可能有多房，只显示第一位会丢人）
  final List<Person> spouses;
  final List<TreeNode> children;

  // 布局计算字段
  double x = 0;
  double y = 0;
  double subtreeWidth = 0;
}
