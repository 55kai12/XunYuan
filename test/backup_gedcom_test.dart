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

    test('v1 纯 JSON 备份仍可恢复（向后兼容）', () async {
      await seedData();

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
  });
}
