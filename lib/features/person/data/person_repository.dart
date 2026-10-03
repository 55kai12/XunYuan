/// 成员数据仓库
/// 封装对 Persons 表的读写操作，支持搜索、筛选、级联删除
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database.dart';
import '../../../core/utils/event_image_store.dart';

/// 成员数据仓库
class PersonRepository {
  PersonRepository(this._db);

  final AppDatabase _db;

  // ==================== 查询 ====================

  /// 监听成员列表（支持筛选）
  /// [treeId] 按家族筛选；[keyword] 按姓名模糊搜索；
  /// [generationWord] 按字辈筛选；[generation] 按世代筛选；[branch] 按房支筛选
  Stream<List<Person>> watchAll({
    int? treeId,
    String? keyword,
    String? generationWord,
    int? generation,
    String? branch,
  }) {
    final query = _db.select(_db.persons);

    // 构建筛选条件
    query.where((tbl) {
      Expression<bool> condition = const Constant(true);

      if (treeId != null) {
        condition = condition & tbl.treeId.equals(treeId);
      }
      if (generationWord != null && generationWord.isNotEmpty) {
        condition =
            condition & tbl.generationWord.equals(generationWord);
      }
      if (generation != null) {
        condition = condition & tbl.generation.equals(generation);
      }
      if (branch != null && branch.isNotEmpty) {
        condition = condition & tbl.branch.equals(branch);
      }
      return condition;
    });

    // 姓名模糊搜索（姓 + 名 + 全名拼接）
    if (keyword != null && keyword.isNotEmpty) {
      final like = '%$keyword%';
      // ponytail: 硬编码列名， Persons 表结构变更时需同步
      const fullName = CustomExpression<String>('(surname || given_name)');
      query.where((tbl) =>
          tbl.surname.like(like) |
          tbl.givenName.like(like) |
          fullName.like(like));
    }

    // 排序：世代升序，排行升序
    query.orderBy([
      (tbl) => OrderingTerm.asc(tbl.generation),
      (tbl) => OrderingTerm.asc(tbl.rank),
      (tbl) => OrderingTerm.asc(tbl.givenName),
    ]);

    return query.watch();
  }

  /// 按 ID 获取成员
  Future<Person?> getById(int id) {
    return (_db.select(_db.persons)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// 监听单个成员
  Stream<Person?> watchById(int id) {
    return (_db.select(_db.persons)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// 获取某家族所有世代（去重）
  Future<List<int>> getGenerations(int treeId) async {
    final rows = await (_db.selectOnly(_db.persons)
          ..addColumns([_db.persons.generation])
          ..where(_db.persons.treeId.equals(treeId))
          ..groupBy([_db.persons.generation])
          ..orderBy([
            OrderingTerm(expression: _db.persons.generation, mode: OrderingMode.asc)
          ]))
        .get();
    return rows
        .map((r) => r.read(_db.persons.generation))
        .whereType<int>()
        .toList();
  }

  /// 获取某家族所有房支（去重）
  Future<List<String>> getBranches(int treeId) async {
    final rows = await (_db.selectOnly(_db.persons)
          ..addColumns([_db.persons.branch])
          ..where(_db.persons.treeId.equals(treeId))
          ..groupBy([_db.persons.branch]))
        .get();
    return rows
        .map((r) => r.read(_db.persons.branch))
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// 获取某家族所有字辈（去重）
  Future<List<String>> getGenerationWords(int treeId) async {
    final rows = await (_db.selectOnly(_db.persons)
          ..addColumns([_db.persons.generationWord])
          ..where(_db.persons.treeId.equals(treeId))
          ..groupBy([_db.persons.generationWord]))
        .get();
    return rows
        .map((r) => r.read(_db.persons.generationWord))
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ==================== 增删改 ====================

  /// 新增成员，返回新 ID
  Future<int> insert({
    required int treeId,
    required String surname,
    required String givenName,
    required Gender gender,
    String? courtesyName,
    String? artName,
    int? generation,
    String? generationWord,
    String? branch,
    int? rank,
    DateTime? birthDate,
    DateTime? deathDate,
    bool isAlive = true,
    String? birthPlace,
    String? deathPlace,
    String? burialPlace,
    String? occupation,
    String? title,
    String? biography,
    int? avatarMediaId,
  }) {
    return _db.into(_db.persons).insert(
          PersonsCompanion.insert(
            treeId: treeId,
            surname: surname,
            givenName: givenName,
            gender: gender,
            courtesyName: Value(courtesyName),
            artName: Value(artName),
            generation: Value(generation),
            generationWord: Value(generationWord),
            branch: Value(branch),
            rank: Value(rank),
            birthDate: Value(birthDate),
            deathDate: Value(deathDate),
            isAlive: Value(isAlive),
            birthPlace: Value(birthPlace),
            deathPlace: Value(deathPlace),
            burialPlace: Value(burialPlace),
            occupation: Value(occupation),
            title: Value(title),
            biography: Value(biography),
            avatarMediaId: Value(avatarMediaId),
          ),
        );
  }

  /// 更新成员信息
  Future<bool> update({
    required int id,
    int? treeId,
    String? surname,
    String? givenName,
    Gender? gender,
    String? courtesyName,
    String? artName,
    int? generation,
    String? generationWord,
    String? branch,
    int? rank,
    DateTime? birthDate,
    DateTime? deathDate,
    bool? isAlive,
    String? birthPlace,
    String? deathPlace,
    String? burialPlace,
    String? occupation,
    String? title,
    String? biography,
    int? avatarMediaId,
  }) async {
    // 换家族时，同步迁移该成员的关系和事件
    // （否则关系编辑页按 treeId 过滤的视图会残留脏数据）
    if (treeId != null) {
      final old = await getById(id);
      if (old != null && old.treeId != treeId) {
        await (_db.update(_db.relationships)
              ..where((tbl) =>
                  tbl.fromPersonId.equals(id) | tbl.toPersonId.equals(id)))
            .write(RelationshipsCompanion(treeId: Value(treeId)));
        await (_db.update(_db.events)
              ..where((tbl) => tbl.personId.equals(id)))
            .write(EventsCompanion(treeId: Value(treeId)));
      }
    }
    final updated = await (_db.update(_db.persons)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      PersonsCompanion(
        treeId: treeId != null ? Value(treeId) : const Value.absent(),
        surname: surname != null ? Value(surname) : const Value.absent(),
        givenName:
            givenName != null ? Value(givenName) : const Value.absent(),
        gender: gender != null ? Value(gender) : const Value.absent(),
        courtesyName: Value(courtesyName),
        artName: Value(artName),
        generation: Value(generation),
        generationWord: Value(generationWord),
        branch: Value(branch),
        rank: Value(rank),
        birthDate: Value(birthDate),
        deathDate: Value(deathDate),
        isAlive: isAlive != null ? Value(isAlive) : const Value.absent(),
        birthPlace: Value(birthPlace),
        deathPlace: Value(deathPlace),
        burialPlace: Value(burialPlace),
        occupation: Value(occupation),
        title: Value(title),
        biography: Value(biography),
        avatarMediaId: Value(avatarMediaId),
      ),
    );
    return updated > 0;
  }

  /// 删除成员（级联删除关联关系和事件）
  Future<void> delete(int personId) async {
    await _db.transaction(() async {
      // 清理该成员所有事件描述引用的配图文件
      final eventRows = await (_db.select(_db.events)
            ..where((tbl) => tbl.personId.equals(personId)))
          .get();
      for (final e in eventRows) {
        await EventImageStore.deleteFiles(e.description);
      }
      // 清理简介引用的配图文件
      final person = await (_db.select(_db.persons)
            ..where((tbl) => tbl.id.equals(personId)))
          .getSingleOrNull();
      if (person != null) {
        await EventImageStore.deleteFiles(person.biography);
      }
      // 清理该成员的媒体（头像等）：先删磁盘文件再删记录，避免相册里残留
      // 已删成员的头像。
      //
      // 顺序要点：persons.avatarMediaId 有外键指向 media（database.dart:143），
      // 所以要先把引用方（persons 行）的 avatarMediaId 置空，才能删 media 行。
      // 这一步必须在删 persons 之前做 —— 否则删 media 时会撞 FK 约束。
      final avatarMediaId = person?.avatarMediaId;
      if (person != null && avatarMediaId != null) {
        await (_db.update(_db.persons)
              ..where((tbl) => tbl.id.equals(personId)))
            .write(const PersonsCompanion(avatarMediaId: Value(null)));
      }
      // 头像归该成员所有；另把 personId 直接指向他的媒体一并清掉。
      final mediaRows = await (_db.select(_db.mediaTable)
            ..where((tbl) => avatarMediaId != null
                ? tbl.personId.equals(personId) | tbl.id.equals(avatarMediaId)
                : tbl.personId.equals(personId)))
          .get();
      for (final m in mediaRows) {
        try {
          final f = File(m.path);
          if (await f.exists()) await f.delete();
        } catch (_) {
          // 文件删除失败不阻塞数据库删除
        }
        await (_db.delete(_db.mediaTable)..where((tbl) => tbl.id.equals(m.id)))
            .go();
      }
      // 删除涉及该成员的所有关系
      await (_db.delete(_db.relationships)
            ..where((tbl) =>
                tbl.fromPersonId.equals(personId) |
                tbl.toPersonId.equals(personId)))
          .go();
      // 删除该成员的所有事件
      await (_db.delete(_db.events)
            ..where((tbl) => tbl.personId.equals(personId)))
          .go();
      // 删除成员
      await (_db.delete(_db.persons)
            ..where((tbl) => tbl.id.equals(personId)))
          .go();
    });
  }

  // ==================== 头像 / 媒体 ====================

  /// 保存头像图片到应用目录并插入 Media 记录，返回 Media ID
  /// [sourcePath] 为选择的图片源路径
  Future<int> saveAvatar({
    required int treeId,
    required String sourcePath,
    String? caption,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(docsDir.path, 'avatars'));
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }

    // 复制文件到应用目录，用时间戳命名避免冲突
    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destPath = p.join(avatarsDir.path, fileName);
    await File(sourcePath).copy(destPath);

    // 插入 Media 记录
    return _db.into(_db.mediaTable).insert(
          MediaTableCompanion.insert(
            treeId: Value(treeId),
            personId: const Value.absent(),
            type: MediaKind.image,
            path: destPath,
            caption: Value(caption),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// 按 ID 获取媒体记录
  Future<MediaTableData?> getMediaById(int id) {
    return (_db.select(_db.mediaTable)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }
}
