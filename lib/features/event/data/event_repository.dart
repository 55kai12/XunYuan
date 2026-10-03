/// 事件数据仓库
/// 封装对 Events 表的读写，支持按家族/成员/类型查询，按时间排序
library;

import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../../../core/utils/event_image_store.dart';

/// 事件数据仓库
class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;

  // ==================== 查询 ====================

  /// 监听某家族的所有事件（按日期倒序）
  Stream<List<Event>> watchByTree(int treeId) {
    return (_db.select(_db.events)
          ..where((tbl) => tbl.treeId.equals(treeId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.date),
            (tbl) => OrderingTerm.desc(tbl.id),
          ]))
        .watch();
  }

  /// 监听某成员的所有事件（按日期倒序）
  Stream<List<Event>> watchByPerson(int personId) {
    return (_db.select(_db.events)
          ..where((tbl) => tbl.personId.equals(personId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.date),
            (tbl) => OrderingTerm.desc(tbl.id),
          ]))
        .watch();
  }

  /// 监听某家族特定类型的事件
  Stream<List<Event>> watchByTreeAndType(int treeId, EventType type) {
    return (_db.select(_db.events)
          ..where((tbl) =>
              tbl.treeId.equals(treeId) & tbl.type.equals(type.name))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .watch();
  }

  /// 按 ID 获取事件
  Future<Event?> getById(int id) {
    return (_db.select(_db.events)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 监听单个事件
  Stream<Event?> watchById(int id) {
    return (_db.select(_db.events)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  // ==================== 增删改 ====================

  /// 新增事件
  Future<int> insert({
    required int treeId,
    required int personId,
    required EventType type,
    required String title,
    DateTime? date,
    String? place,
    String? description,
  }) {
    return _db.into(_db.events).insert(
          EventsCompanion.insert(
            treeId: treeId,
            personId: Value(personId),
            type: type,
            title: title,
            date: Value(date),
            place: Value(place),
            description: Value(description),
          ),
        );
  }

  /// 更新事件
  ///
  /// [personId] 为 null 表示「不改动关联成员」。编辑页的关联成员下拉在编辑态
  /// 是可改的，早先这里没有这个参数 ⇒ 用户改了成员、界面提示已保存，实际却没落库。
  Future<bool> update({
    required int id,
    int? personId,
    EventType? type,
    String? title,
    DateTime? date,
    String? place,
    String? description,
  }) async {
    final updated = await (_db.update(_db.events)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      EventsCompanion(
        personId: personId != null ? Value(personId) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        title: title != null ? Value(title) : const Value.absent(),
        date: Value(date),
        place: Value(place),
        description: Value(description),
      ),
    );
    return updated > 0;
  }

  /// 删除事件（同时清理描述中引用的配图文件）
  Future<void> delete(int eventId) async {
    final event = await getById(eventId);
    if (event != null) {
      await EventImageStore.deleteFiles(event.description);
    }
    await (_db.delete(_db.events)
          ..where((tbl) => tbl.id.equals(eventId)))
        .go();
  }

  /// 删除某成员的所有事件（同时清理引用的配图文件）
  Future<void> deleteByPerson(int personId) async {
    final rows = await (_db.select(_db.events)
          ..where((tbl) => tbl.personId.equals(personId)))
        .get();
    for (final e in rows) {
      await EventImageStore.deleteFiles(e.description);
    }
    await (_db.delete(_db.events)
          ..where((tbl) => tbl.personId.equals(personId)))
        .go();
  }
}
