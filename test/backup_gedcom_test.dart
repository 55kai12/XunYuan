/// 备份与 GEDCOM round-trip 测试
/// - v2 zip 备份：含事件配图与头像的导出/恢复，媒体文件原位还原
/// - v1 纯 JSON 备份：向后兼容恢复
/// - GEDCOM：EVEN 事件（标题/日期/地点/描述）导出后可完整导回
/// 使用内存数据库 + 临时目录注入，不依赖平台通道
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:familytree/core/database/database.dart';
import 'package:familytree/core/utils/event_image_store.dart';
import 'package:familytree/features/backup/data/backup_service.dart';
import 'package:familytree/features/gedcom/data/gedcom_service.dart';

void main() {
  late AppDatabase db;
  late Directory docsDir;
  late BackupService backupService;
  late GedcomService gedcomService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    docsDir = await Directory.systemTemp.createTemp('xunyuan_test_docs_');
    backupService = BackupService(db, docsDir: docsDir);
    gedcomService = GedcomService(db);
  });

  tearDown(() async {
    await db.close();
    try {
      await docsDir.delete(recursive: true);
    } catch (_) {}
  });

  /// 造一套完整数据：1 家族 + 2 成员 + 1 关系 + 1 事件（带配图标记）
  Future<int> seedData() async {
    final treeId = await db.into(db.familyTrees).insert(
          FamilyTreesCompanion.insert(
            name: '颍川陈氏',
            surname: '陈',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    final father = await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: treeId,
            surname: '陈',
            givenName: '大郎',
            gender: Gender.male,
          ),
        );
    await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: treeId,
            surname: '陈',
            givenName: '小郎',
            gender: Gender.male,
          ),
        );
    await db.into(db.relationships).insert(
          RelationshipsCompanion.insert(
            treeId: treeId,
            fromPersonId: father,
            toPersonId: father + 1,
            type: RelationType.father,
          ),
        );
    await db.into(db.events).insert(
          EventsCompanion.insert(
            treeId: treeId,
            personId: Value(father),
            type: EventType.migration,
            title: '南迁',
            date: Value(DateTime(1620, 3, 5)),
            place: const Value('广东南雄珠玑巷'),
            description:
                Value('自珠玑巷南迁 $father 至广州府 [img:event_test.jpg]'),
          ),
        );
    return treeId;
  }

  /// 在临时文档目录里造媒体文件
  Future<void> seedMediaFiles() async {
    final eventDir = Directory(p.join(docsDir.path, 'event_media'));
    await eventDir.create(recursive: true);
    await File(p.join(eventDir.path, 'event_test.jpg'))
        .writeAsBytes([1, 2, 3, 4]);
    final avatarDir = Directory(p.join(docsDir.path, 'avatars'));
    await avatarDir.create(recursive: true);
    await File(p.join(avatarDir.path, 'avatar_test.jpg'))
        .writeAsBytes([5, 6, 7]);
  }

  group('备份 round-trip', () {
    test('v2 zip 导出后恢复，数据与媒体文件完整', () async {
      await seedData();
      await seedMediaFiles();

      final zipPath = await backupService.exportToFile(customName: 't1');
      expect(File(zipPath).existsSync(), isTrue);
      expect(zipPath.endsWith('.zip'), isTrue);

      // 模拟换机：清空数据库与媒体文件
      final stats0 = await backupService.importFromJson(
        '{"version": 2, "families": [], "persons": []}',
        merge: false,
      );
      expect(stats0.total, 0);
      await File(p.join(docsDir.path, 'event_media', 'event_test.jpg'))
          .delete();
      await File(p.join(docsDir.path, 'avatars', 'avatar_test.jpg')).delete();

      // 恢复
      final stats = await backupService.importFromFile(zipPath, merge: false);
      expect(stats.families, 1);
      expect(stats.persons, 2);
      expect(stats.relationships, 1);
      expect(stats.events, 1);

      // 事件数据完整
      final events = await db.select(db.events).get();
      expect(events, hasLength(1));
      expect(events.single.title, '南迁');
      expect(events.single.description!,
          contains('[img:event_test.jpg]'));

      // 媒体文件已还原
      expect(
          File(p.join(docsDir.path, 'event_media', 'event_test.jpg'))
              .existsSync(),
          isTrue);
      expect(
          File(p.join(docsDir.path, 'avatars', 'avatar_test.jpg'))
              .existsSync(),
          isTrue);

      // 配图标记可解析
      final segs = EventImageStore.parse(events.single.description);
      expect(segs.where((s) => s.isImage), hasLength(1));
    });

    // 回归：清空模式恢复带头像/封面的备份曾抛
    // SqliteException(787) FOREIGN KEY constraint failed ——
    // 成员表先于媒体表插入，直接写旧 avatarMediaId 时媒体记录已被删光。
    test('清空模式恢复带头像与封面的备份不触发外键失败', () async {
      await seedData();
      await seedMediaFiles();

      // 造一条媒体记录并把它挂到成员头像 + 家族封面上
      final treeId = (await db.select(db.familyTrees).getSingle()).id;
      final personId = (await db.select(db.persons).get()).first.id;
      final mediaId = await db.into(db.mediaTable).insert(
            MediaTableCompanion.insert(
              treeId: Value(treeId),
              personId: Value(personId),
              type: MediaKind.image,
              path: 'avatars/avatar_test.jpg',
              createdAt: DateTime.now(),
            ),
          );
      await (db.update(db.persons)..where((t) => t.id.equals(personId)))
          .write(PersonsCompanion(avatarMediaId: Value(mediaId)));
      await (db.update(db.familyTrees)..where((t) => t.id.equals(treeId)))
          .write(FamilyTreesCompanion(coverMediaId: Value(mediaId)));

      final zipPath = await backupService.exportToFile(customName: 'fk');
      expect(File(zipPath).existsSync(), isTrue);

      // 清空模式恢复（merge: false）——修复前此处抛外键约束失败
      final stats = await backupService.importFromFile(zipPath, merge: false);
      expect(stats.persons, 2);
      expect(stats.media, greaterThanOrEqualTo(1));

      // 头像 / 封面引用被正确回填，不是悬空 null
      final restoredPerson =
          (await db.select(db.persons).get()).firstWhere((p) => p.id == personId);
      expect(restoredPerson.avatarMediaId, isNotNull);
      final restoredTree = await db.select(db.familyTrees).getSingle();
      expect(restoredTree.coverMediaId, isNotNull);
      // 回填后的 ID 必须真实存在于媒体表（外键语义）
      final mediaIds =
          (await db.select(db.mediaTable).get()).map((m) => m.id).toSet();
      expect(mediaIds, contains(restoredPerson.avatarMediaId));
      expect(mediaIds, contains(restoredTree.coverMediaId));
    });

    test('v1 纯 JSON 备份仍可恢复（向后兼容）', () async {      await seedData();

      // 用 exportToJson 造一份旧式 JSON 文件
      final json = await backupService.exportToJson();
      final jsonPath = p.join(docsDir.path, 'legacy_v1.json');
      File(jsonPath).writeAsStringSync(json);

      // 清空后恢复
      final cleared = await backupService.importFromJson(
        '{"version": 2, "families": [], "persons": []}',
        merge: false,
      );
      expect(cleared.families, 0);

      final stats = await backupService.importFromFile(jsonPath);
      expect(stats.families, 1);
      expect(stats.persons, 2);
      expect(stats.events, 1);
    });

    test('自动备份保留最近 5 份并清理旧文件', () async {
      await seedData();

      // 手动造 7 份自动备份 + 1 份手动备份
      for (var i = 0; i < 7; i++) {
        await backupService.runAutoBackup();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await backupService.exportToFile(customName: 'manual_one');

      final all = await backupService.listBackups();
      final autos = all
          .where((f) => p.basename(f.path).startsWith(autoBackupPrefix))
          .toList();
      expect(autos.length, 5);
      // 手动备份不受影响
      expect(all.any((f) => p.basename(f.path).startsWith('manual_one')),
          isTrue);
    });

    test('备份写入是原子的：不留 .tmp 残留，且同名单文件可被覆盖重写', () async {
      await seedData();

      // 同一 customName 连续导出两次：第二次必须覆盖成功（Windows 上
      // rename 到已存在目标会失败，实现里已先删旧文件）
      final first = await backupService.exportToFile(customName: 'same_name');
      expect(File(first).existsSync(), isTrue);
      final second = await backupService.exportToFile(customName: 'same_name');
      expect(second, first);
      expect(File(second).existsSync(), isTrue);
      // 覆盖后仍是可解析的完整 zip
      final stats = await backupService.importFromFile(second, merge: false);
      expect(stats.families, 1);

      // 正常路径下不残留临时文件
      final backupDir = Directory(p.join(docsDir.path, 'backups'));
      final leftovers = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty, reason: '不应残留 .tmp 文件：$leftovers');

      // 手动塞一个历史残留的 .tmp，listBackups 应顺手清掉且不把它当备份列出
      File(p.join(backupDir.path, 'stale.zip.tmp')).writeAsStringSync('half');
      final listed = await backupService.listBackups();
      expect(listed.any((f) => f.path.endsWith('.tmp')), isFalse);
      expect(
        backupDir.listSync().whereType<File>().any((f) => f.path.endsWith('.tmp')),
        isFalse,
        reason: 'listBackups 应清理历史 .tmp 残留',
      );
    });
  });

  group('GEDCOM round-trip', () {
    test('EVEN 事件导出后导入，标题/日期/地点/描述完整', () async {
      final treeId = await seedData();
      final gedcom = await gedcomService.exportToGedcom(treeId);

      // 导出内容包含 EVEN 结构
      expect(gedcom, contains('1 EVEN'));
      expect(gedcom, contains('2 TYPE 南迁'));
      expect(gedcom, contains('2 PLAC 广东南雄珠玑巷'));
      expect(gedcom, contains('2 NOTE 自珠玑巷南迁'));

      // 导入到同一树（人员翻倍，EVEN 事件重现）
      final stats =
          await gedcomService.importFromGedcom(gedcom, treeId: treeId);
      expect(stats.individuals, 2);

      // 原始事件类型为 migration；EVEN 导入后类型为 other，标题相同
      final events = await (db.select(db.events)
            ..where((e) => e.title.equals('南迁')))
          .get();
      expect(events, hasLength(2));
      final imported =
          events.firstWhere((e) => e.type == EventType.other);
      expect(imported.personId, isNotNull);
      expect(imported.place, '广东南雄珠玑巷');
      expect(imported.date, DateTime(1620, 3, 5));
      // 配图标记被剥离
      expect(imported.description, isNot(contains('[img:')));
      expect(imported.description, contains('自珠玑巷南迁'));
    });

    test('出生/去世事件不重复导出为 EVEN', () async {
      final treeId = await seedData();
      // 给成员补一个出生事件
      final persons = await db.select(db.persons).get();
      await db.into(db.events).insert(
            EventsCompanion.insert(
              treeId: treeId,
              personId: Value(persons.first.id),
              type: EventType.birth,
              title: '出生',
              date: Value(DateTime(1900, 1, 1)),
            ),
          );

      final gedcom = await gedcomService.exportToGedcom(treeId);
      // 出生事件类型不会被导出为 EVEN（EVEN 只承载自定义事件）
      expect(gedcom, isNot(contains('2 TYPE 出生')));
    });

    test('多配偶时同一子女不会出现在每段婚姻的 CHIL（按另一位父母归属）', () async {
      final treeId = await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              name: '测试家族',
              surname: '张',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      Future<int> addPerson(String given, Gender g) => db
          .into(db.persons)
          .insert(PersonsCompanion.insert(
            treeId: treeId,
            surname: '张',
            givenName: given,
            gender: g,
          ));
      final father = await addPerson('父', Gender.male);
      final wife1 = await addPerson('妻一', Gender.female);
      final wife2 = await addPerson('妻二', Gender.female);
      final child1 = await addPerson('子一', Gender.male);
      final child2 = await addPerson('子二', Gender.male);

      Future<void> relate(int from, int to, RelationType t) =>
          db.into(db.relationships).insert(RelationshipsCompanion.insert(
                treeId: treeId,
                fromPersonId: from,
                toPersonId: to,
                type: t,
              ));
      // 父与两位配偶
      await relate(father, wife1, RelationType.spouse);
      await relate(father, wife2, RelationType.spouse);
      // 子一 ← 父+妻一；子二 ← 父+妻二
      await relate(father, child1, RelationType.father);
      await relate(wife1, child1, RelationType.mother);
      await relate(father, child2, RelationType.father);
      await relate(wife2, child2, RelationType.mother);

      final gedcom = await gedcomService.exportToGedcom(treeId);

      // 两个孩子各只能有一条 CHIL（旧实现会各出现 2 次，因为两段婚姻都收)
      final chilLines =
          gedcom.split('\n').where((l) => l.startsWith('1 CHIL ')).toList();
      expect(chilLines, hasLength(2), reason: '两个孩子各只应出现一次，实际：$chilLines');
      expect(chilLines.toSet(), hasLength(2));

      // 按 FAM 段切分：两段婚姻各分到恰好 1 个孩子
      final famBlocks = gedcom.split('0 @F').skip(1).toList();
      final perFamChildren = <String, int>{};
      for (final block in famBlocks) {
        final xref = block.split(' ').first;
        final n =
            block.split('\n').where((l) => l.startsWith('1 CHIL ')).length;
        if (n > 0) perFamChildren[xref] = n;
      }
      expect(perFamChildren.length, 2);
      expect(perFamChildren.values, everyElement(1),
          reason: '每段婚姻只应分到 1 个孩子，实际：$perFamChildren');

      // 两位配偶都出现在导出里
      expect(gedcom, contains('1 WIFE @I$wife1@'));
      expect(gedcom, contains('1 WIFE @I$wife2@'));
    });
  });
}
