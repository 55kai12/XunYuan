/// 家族数据仓库
/// 封装对 FamilyTrees 表的读写操作
/// 数据层：直接操作 Drift 数据库
library;

import 'package:drift/drift.dart';

import '../../../core/database/database.dart';

/// 家族数据仓库
class FamilyRepository {
  FamilyRepository(this._db);

  final AppDatabase _db;

  /// 监听所有家族（按更新时间倒序）
  Stream<List<FamilyTree>> watchAll() {
    final query = _db.select(_db.familyTrees)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    return query.watch();
  }

  /// 按 ID 获取家族
  Future<FamilyTree?> getById(int id) {
    return (_db.select(_db.familyTrees)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 监听单个家族
  Stream<FamilyTree?> watchFamily(int id) {
    return (_db.select(_db.familyTrees)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// 新增家族，返回新 ID
  Future<int> insert({
    required String name,
    required String surname,
    String? hallName,
    String? origin,
    String? generationWords,
    String? description,
    int? coverMediaId,
  }) {
    final now = DateTime.now();
    return _db.into(_db.familyTrees).insert(
          FamilyTreesCompanion.insert(
            name: name,
            surname: surname,
            hallName: Value(hallName),
            origin: Value(origin),
            generationWords: Value(generationWords),
            description: Value(description),
            coverMediaId: Value(coverMediaId),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// 更新家族信息
  Future<bool> update({
    required int id,
    String? name,
    String? surname,
    String? hallName,
    String? origin,
    String? generationWords,
    String? description,
    int? coverMediaId,
  }) async {
    final updated = await (_db.update(_db.familyTrees)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      FamilyTreesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        surname: surname != null ? Value(surname) : const Value.absent(),
        hallName: Value(hallName),
        origin: Value(origin),
        generationWords: Value(generationWords),
        description: Value(description),
        // null = 不修改（absent 语义）。UI 暂无清空封面的入口，
        // 若将来支持清空，需传哨兵值而不是 null
        coverMediaId:
            coverMediaId != null ? Value(coverMediaId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return updated > 0;
  }

  /// 删除家族（级联删除成员、关系、事件、媒体、资料）
  Future<void> delete(int id) => _db.deleteFamilyCascade(id);

  /// 统计家族成员数
  Future<int> countMembers(int treeId) async {
    final row = await (_db.selectOnly(_db.persons)
          ..addColumns([_db.persons.id.count()])
          ..where(_db.persons.treeId.equals(treeId)))
        .getSingle();
    return row.read(_db.persons.id.count()) ?? 0;
  }

  /// 统计在世成员数
  Future<int> countAlive(int treeId) async {
    final row = await (_db.selectOnly(_db.persons)
          ..addColumns([_db.persons.id.count()])
          ..where(_db.persons.treeId.equals(treeId) &
              _db.persons.isAlive.equals(true)))
        .getSingle();
    return row.read(_db.persons.id.count()) ?? 0;
  }

  /// 统计成员性别分布
  Future<Map<Gender, int>> countByGender(int treeId) async {
    final rows = await (_db.selectOnly(_db.persons)
          ..addColumns([_db.persons.gender, _db.persons.id.count()])
          ..where(_db.persons.treeId.equals(treeId))
          ..groupBy([_db.persons.gender]))
        .get();
    final result = <Gender, int>{};
    for (final row in rows) {
      // intEnum 列读取返回存储的 int 值，转换为枚举
      final genderValue = row.read(_db.persons.gender);
      final count = row.read(_db.persons.id.count()) ?? 0;
      if (genderValue != null &&
          genderValue >= 0 &&
          genderValue < Gender.values.length) {
        result[Gender.values[genderValue]] = count;
      }
    }
    return result;
  }

  /// 统计家族事件数
  Future<int> countEvents(int treeId) async {
    final row = await (_db.selectOnly(_db.events)
          ..addColumns([_db.events.id.count()])
          ..where(_db.events.treeId.equals(treeId)))
        .getSingle();
    return row.read(_db.events.id.count()) ?? 0;
  }
}
