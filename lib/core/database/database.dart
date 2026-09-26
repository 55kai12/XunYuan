/// 寻渊数据库定义
/// 使用 Drift + SQLite，包含 7 张核心表：
/// FamilyTrees / Persons / Relationships / Events / Places / MediaTable / Sources
/// 本地优先、离线可用，迁移机制可扩展
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../utils/event_image_store.dart';

part 'database.g.dart';

// ==================== 枚举定义 ====================

/// 性别
enum Gender { male, female, other }

/// 关系类型：父亲 / 母亲 / 配偶 / 子女 / 兄弟姐妹 / 继父 / 继母
enum RelationType {
  father,
  mother,
  spouse,
  child,
  sibling,
  adoptiveFather,
  adoptiveMother,
}

/// 事件类型：出生 / 结婚 / 去世 / 迁徙 / 功名 / 其他
enum EventType { birth, marriage, death, migration, honor, other }

/// 媒体类型：图片 / 视频 / 音频 / 文档
enum MediaKind { image, video, audio, document }

// ==================== 表定义 ====================

/// 家族表
class FamilyTrees extends Table {
  @override
  String get tableName => 'family_trees';

  IntColumn get id => integer().autoIncrement()();

  /// 家族名称
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// 姓氏
  TextColumn get surname => text().withLength(min: 1, max: 50)();

  /// 堂号
  TextColumn get hallName => text().withLength(max: 50).nullable()();

  /// 郡望
  TextColumn get origin => text().withLength(max: 100).nullable()();

  /// 字辈（多个字辈用顿号或空格分隔）
  TextColumn get generationWords => text().withLength(max: 500).nullable()();

  /// 家族简介
  TextColumn get description => text().withLength(max: 5000).nullable()();

  /// 封面媒体 ID（仅存储 ID，避免与外键循环引用）
  IntColumn get coverMediaId => integer().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();
}

/// 成员表
class Persons extends Table {
  @override
  String get tableName => 'persons';

  IntColumn get id => integer().autoIncrement()();

  /// 所属家族
  IntColumn get treeId => integer().references(FamilyTrees, #id)();

  /// 姓
  TextColumn get surname => text().withLength(max: 50)();

  /// 名
  TextColumn get givenName => text().withLength(max: 50)();

  /// 字
  TextColumn get courtesyName => text().withLength(max: 50).nullable()();

  /// 号
  TextColumn get artName => text().withLength(max: 50).nullable()();

  /// 性别
  IntColumn get gender => intEnum<Gender>()();

  /// 世代（第几世）
  IntColumn get generation => integer().nullable()();

  /// 字辈
  TextColumn get generationWord => text().withLength(max: 50).nullable()();

  /// 房支
  TextColumn get branch => text().withLength(max: 50).nullable()();

  /// 排行
  IntColumn get rank => integer().nullable()();

  /// 生日
  DateTimeColumn get birthDate => dateTime().nullable()();

  /// 忌日
  DateTimeColumn get deathDate => dateTime().nullable()();

  /// 是否在世（默认在世）
  BoolColumn get isAlive => boolean().withDefault(const Constant(true))();

  /// 出生地
  TextColumn get birthPlace => text().withLength(max: 200).nullable()();

  /// 去世地
  TextColumn get deathPlace => text().withLength(max: 200).nullable()();

  /// 葬地
  TextColumn get burialPlace => text().withLength(max: 200).nullable()();

  /// 职业
  TextColumn get occupation => text().withLength(max: 200).nullable()();

  /// 功名 / 头衔
  TextColumn get title => text().withLength(max: 200).nullable()();

  /// 简介 / 家族故事
  TextColumn get biography => text().withLength(max: 10000).nullable()();

  /// 头像媒体 ID
  IntColumn get avatarMediaId =>
      integer().nullable().references(MediaTable, #id)();
}

/// 关系表：记录成员之间的血缘与婚姻关系
class Relationships extends Table {
  @override
  String get tableName => 'relationships';

  IntColumn get id => integer().autoIncrement()();

  /// 所属家族
  IntColumn get treeId => integer().references(FamilyTrees, #id)();

  /// 关系发起方
  @ReferenceName('from_relationships')
  IntColumn get fromPersonId => integer().references(Persons, #id)();

  /// 关系接收方
  @ReferenceName('to_relationships')
  IntColumn get toPersonId => integer().references(Persons, #id)();

  /// 关系类型
  TextColumn get type => textEnum<RelationType>()();

  /// 关系开始时间（如婚姻开始年）
  DateTimeColumn get startDate => dateTime().nullable()();

  /// 关系结束时间（如继配结束年）
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 备注（如"继配""过继"等说明）
  TextColumn get note => text().withLength(max: 500).nullable()();
}

/// 事件表：记录家族重要事件
class Events extends Table {
  @override
  String get tableName => 'events';

  IntColumn get id => integer().autoIncrement()();

  /// 关联成员（可空：家族级事件可不关联具体成员）
  IntColumn get personId => integer().nullable().references(Persons, #id)();

  /// 所属家族
  IntColumn get treeId => integer().references(FamilyTrees, #id)();

  /// 事件类型
  TextColumn get type => textEnum<EventType>()();

  /// 事件标题
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// 事件日期
  DateTimeColumn get date => dateTime().nullable()();

  /// 事件地点
  TextColumn get place => text().withLength(max: 200).nullable()();

  /// 事件描述
  TextColumn get description => text().withLength(max: 5000).nullable()();
}

/// 地点表：记录家族相关地点（出生地、葬地、迁徙地等）
class Places extends Table {
  @override
  String get tableName => 'places';

  IntColumn get id => integer().autoIncrement()();

  /// 地点名称
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// 详细地址
  TextColumn get address => text().withLength(max: 500).nullable()();

  /// 纬度
  RealColumn get latitude => real().nullable()();

  /// 经度
  RealColumn get longitude => real().nullable()();
}

/// 媒体表：家族封面、成员头像、照片等
class MediaTable extends Table {
  @override
  String get tableName => 'media';

  IntColumn get id => integer().autoIncrement()();

  /// 所属家族（仅存储 ID，避免与外键循环引用）
  IntColumn get treeId => integer().nullable()();

  /// 关联成员（可空，仅存储 ID 避免与外键循环）
  IntColumn get personId => integer().nullable()();

  /// 媒体类型
  TextColumn get type => textEnum<MediaKind>()();

  /// 本地文件路径
  TextColumn get path => text().withLength(min: 1, max: 1000)();

  /// 说明文字
  TextColumn get caption => text().withLength(max: 500).nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();
}

/// 资料来源表：族谱引用、文献等
class Sources extends Table {
  @override
  String get tableName => 'sources';

  IntColumn get id => integer().autoIncrement()();

  /// 所属家族
  IntColumn get treeId => integer().references(FamilyTrees, #id)();

  /// 资料标题
  TextColumn get title => text().withLength(min: 1, max: 300)();

  /// 资料链接
  TextColumn get url => text().withLength(max: 1000).nullable()();

  /// 备注
  TextColumn get note => text().withLength(max: 2000).nullable()();
}

// ==================== 数据库 ====================

/// 寻渊数据库
@DriftDatabase(
  tables: [
    FamilyTrees,
    Persons,
    Relationships,
    Events,
    Places,
    MediaTable,
    Sources,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 正式构造：使用应用文档目录下的 SQLite 文件
  AppDatabase() : super(_openConnection());

  /// 测试构造：使用内存数据库
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  /// 迁移策略：按版本号逐步升级，保证数据不丢失
  @override
  MigrationStrategy get migration => MigrationStrategy(
        // 首次创建时建立所有表和索引
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes(m);
        },
        // 升级时按版本逐步迁移
        onUpgrade: (m, from, to) async {
          // 版本 1 → 2：添加查询索引，提升族谱树和搜索性能
          if (from < 2) {
            await _migrateV1ToV2(m);
          }
          // 未来版本迁移在此添加：
          // if (from < 3) { await _migrateV2ToV3(m); }
        },
        // 打开前开启外键约束，保证引用完整性
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // 首次创建或升级后执行数据验证
          if (details.wasCreated) {
            // 新数据库无需额外处理
          }
        },
      );

  /// 创建查询索引（新库创建时调用）
  Future<void> _createIndexes(Migrator m) async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_persons_tree_id ON persons(tree_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_persons_generation ON persons(generation)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_relationships_tree_id ON relationships(tree_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_relationships_from_person ON relationships(from_person_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_relationships_to_person ON relationships(to_person_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_events_person_id ON events(person_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_events_tree_id ON events(tree_id)',
    );
  }

  /// 版本 1 → 2 迁移：添加查询索引
  Future<void> _migrateV1ToV2(Migrator m) async {
    await _createIndexes(m);
  }

  /// 级联删除家族及其所有关联数据
  Future<void> deleteFamilyCascade(int treeId) async {
    await transaction(() async {
      // 删除关系
      await (delete(relationships)
            ..where((tbl) => tbl.treeId.equals(treeId)))
          .go();
      // 删除事件：先清理描述中引用的配图文件
      final eventRows =
          await (select(events)..where((tbl) => tbl.treeId.equals(treeId)))
              .get();
      for (final e in eventRows) {
        await EventImageStore.deleteFiles(e.description);
      }
      await (delete(events)..where((tbl) => tbl.treeId.equals(treeId))).go();
      // 清理家族简介与成员简介引用的配图文件
      final familyRow = await (select(familyTrees)
            ..where((tbl) => tbl.id.equals(treeId)))
          .getSingleOrNull();
      if (familyRow != null) {
        await EventImageStore.deleteFiles(familyRow.description);
      }
      final personRows =
          await (select(persons)..where((tbl) => tbl.treeId.equals(treeId)))
              .get();
      for (final pp in personRows) {
        await EventImageStore.deleteFiles(pp.biography);
      }
      // 删除成员
      await (delete(persons)..where((tbl) => tbl.treeId.equals(treeId))).go();
      // 删除媒体：先删磁盘文件再删记录，避免存储泄漏
      final mediaRows =
          await (select(mediaTable)..where((tbl) => tbl.treeId.equals(treeId)))
              .get();
      for (final m in mediaRows) {
        try {
          final f = File(m.path);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {
          // 文件删除失败不阻塞数据库删除
        }
      }
      await (delete(mediaTable)..where((tbl) => tbl.treeId.equals(treeId)))
          .go();
      // 删除资料
      await (delete(sources)..where((tbl) => tbl.treeId.equals(treeId))).go();
      // 最后删除家族本体
      await (delete(familyTrees)..where((tbl) => tbl.id.equals(treeId))).go();
    });
  }
}

/// 打开数据库连接（懒加载，使用应用文档目录）
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    // 后台线程创建，避免阻塞 UI
    return NativeDatabase.createInBackground(file);
  });
}
