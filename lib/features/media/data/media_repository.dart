/// 媒体数据仓库
/// 管理照片等媒体文件的查询和删除
library;

import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/database/database.dart';

/// 媒体类型
enum MediaType { image, document, other }

/// 媒体数据仓库
class MediaRepository {
  MediaRepository(this._db);

  final AppDatabase _db;

  /// 按家族查询所有媒体（按创建时间倒序）
  Stream<List<MediaTableData>> watchMediaByTree(int treeId) {
    final query = _db.select(_db.mediaTable)
      ..where((tbl) => tbl.treeId.equals(treeId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return query.watch();
  }

  /// 按成员查询媒体
  Stream<List<MediaTableData>> watchMediaByPerson(int personId) {
    final query = _db.select(_db.mediaTable)
      ..where((tbl) => tbl.personId.equals(personId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return query.watch();
  }

  /// 按 ID 获取媒体
  Future<MediaTableData?> getById(int id) {
    return (_db.select(_db.mediaTable)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 删除媒体（同时删除文件）
  Future<void> deleteMedia(int mediaId) async {
    final media = await getById(mediaId);
    if (media != null) {
      // 删除本地文件
      try {
        final file = File(media.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // 文件删除失败不影响数据库记录删除
      }
    }
    await (_db.delete(_db.mediaTable)
          ..where((tbl) => tbl.id.equals(mediaId)))
        .go();
  }

  /// 统计家族媒体数量
  Future<int> countByTree(int treeId) async {
    final result = await (_db.selectOnly(_db.mediaTable)
          ..addColumns([_db.mediaTable.id.count()])
          ..where(_db.mediaTable.treeId.equals(treeId)))
        .get();
    return result.first.read(_db.mediaTable.id.count()) ?? 0;
  }
}
