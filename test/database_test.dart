/// 数据库层测试
/// 验证家族 CRUD、统计、级联删除；成员 CRUD、搜索、级联删除
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familytree/core/database/database.dart';
import 'package:familytree/features/family/data/family_repository.dart';
import 'package:familytree/features/person/data/person_repository.dart';
import 'package:familytree/features/relationship/data/relationship_repository.dart';
import 'package:familytree/features/event/data/event_repository.dart';
import 'package:familytree/features/backup/data/backup_service.dart';
import 'package:familytree/features/gedcom/data/gedcom_service.dart';

void main() {
  late AppDatabase db;
  late FamilyRepository repo;

  setUp(() {
    // 每个测试使用独立的内存数据库
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FamilyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('创建家族并查询', () async {
    final id = await repo.insert(
      name: '颍川陈氏宗族',
      surname: '陈',
      hallName: '颍川堂',
      origin: '河南颍川',
    );

    expect(id, greaterThan(0));

    final family = await repo.getById(id);
    expect(family, isNotNull);
    expect(family!.name, '颍川陈氏宗族');
    expect(family.surname, '陈');
    expect(family.hallName, '颍川堂');
    expect(family.origin, '河南颍川');
  });

  test('创建家族时可选字段默认为空', () async {
    final id = await repo.insert(name: '简单家族', surname: '张');

    final family = await repo.getById(id);
    expect(family, isNotNull);
    expect(family!.hallName, isNull);
    expect(family.origin, isNull);
    expect(family.generationWords, isNull);
    expect(family.description, isNull);
  });

  test('更新家族信息', () async {
    final id = await repo.insert(name: '测试家族', surname: '李');

    final ok = await repo.update(
      id: id,
      name: '陇西李氏',
      surname: '李',
      hallName: '三槐堂',
      generationWords: '忠、孝、传、家',
    );

    expect(ok, isTrue);

    final family = await repo.getById(id);
    expect(family!.name, '陇西李氏');
    expect(family.hallName, '三槐堂');
    expect(family.generationWords, '忠、孝、传、家');
    // 未传入的字段保持不变
    expect(family.origin, isNull);
  });

  test('统计成员数与性别分布', () async {
    final id = await repo.insert(name: '王氏家族', surname: '王');

    // 插入 3 个成员：男 2（1 去世）、女 1
    await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: id,
            surname: '王',
            givenName: '大',
            gender: Gender.male,
          ),
        );
    await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: id,
            surname: '王',
            givenName: '二',
            gender: Gender.male,
            isAlive: const Value(false),
          ),
        );
    await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: id,
            surname: '王',
            givenName: '三',
            gender: Gender.female,
          ),
        );

    expect(await repo.countMembers(id), 3);
    expect(await repo.countAlive(id), 2);

    final genderMap = await repo.countByGender(id);
    expect(genderMap[Gender.male], 2);
    expect(genderMap[Gender.female], 1);
  });

  test('监听家族列表', () async {
    await repo.insert(name: '家族甲', surname: '周');
    await repo.insert(name: '家族乙', surname: '吴');

    final families = await repo.watchAll().first;
    expect(families.length, 2);
    expect(families.map((f) => f.surname), containsAll(['周', '吴']));
  });

  test('级联删除家族及其成员', () async {
    final id = await repo.insert(name: '待删除家族', surname: '赵');

    await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: id,
            surname: '赵',
            givenName: '一',
            gender: Gender.male,
          ),
        );
    await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: id,
            surname: '赵',
            givenName: '二',
            gender: Gender.female,
          ),
        );

    // 删除家族
    await repo.delete(id);

    // 家族被删除
    expect(await repo.getById(id), isNull);
    // 成员被级联删除
    expect(await repo.countMembers(id), 0);
  });

  test('删除不存在的家族不报错', () async {
    // 删除不存在的 ID 应安全返回
    await repo.delete(9999);
  });

  // ==================== 成员测试 ====================

  test('创建成员并查询', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '李');
    final personRepo = PersonRepository(db);

    final personId = await personRepo.insert(
      treeId: treeId,
      surname: '李',
      givenName: '白',
      gender: Gender.male,
      courtesyName: '太白',
      generation: 3,
      generationWord: '白',
      isAlive: false,
      birthDate: DateTime(701, 2, 28),
      deathDate: DateTime(762, 12, 1),
      occupation: '诗人',
      title: '诗仙',
    );

    final person = await personRepo.getById(personId);
    expect(person, isNotNull);
    expect(person!.surname, '李');
    expect(person.givenName, '白');
    expect(person.courtesyName, '太白');
    expect(person.gender, Gender.male);
    expect(person.generation, 3);
    expect(person.isAlive, false);
    expect(person.occupation, '诗人');
  });

  test('更新成员信息', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '王');
    final personRepo = PersonRepository(db);
    final personId = await personRepo.insert(
      treeId: treeId,
      surname: '王',
      givenName: '维',
      gender: Gender.male,
    );

    final updated = await personRepo.update(
      id: personId,
      courtesyName: '摩诘',
      generation: 5,
      isAlive: false,
      deathDate: DateTime(761),
    );
    expect(updated, true);

    final person = await personRepo.getById(personId);
    expect(person!.courtesyName, '摩诘');
    expect(person.generation, 5);
    expect(person.isAlive, false);
  });

  test('按姓名搜索成员', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '苏');
    final personRepo = PersonRepository(db);
    await personRepo.insert(
        treeId: treeId, surname: '苏', givenName: '洵', gender: Gender.male);
    await personRepo.insert(
        treeId: treeId, surname: '苏', givenName: '轼', gender: Gender.male);
    await personRepo.insert(
        treeId: treeId, surname: '苏', givenName: '辙', gender: Gender.male);

    // 搜索"轼"
    final results = await personRepo.watchAll(keyword: '轼').first;
    expect(results.length, 1);
    expect(results.first.givenName, '轼');

    // 搜索"苏"（匹配姓）
    final all = await personRepo.watchAll(keyword: '苏').first;
    expect(all.length, 3);
  });

  test('按世代和字辈筛选成员', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '曾');
    final personRepo = PersonRepository(db);
    await personRepo.insert(
      treeId: treeId, surname: '曾', givenName: '一',
      gender: Gender.male, generation: 1, generationWord: '宗',
    );
    await personRepo.insert(
      treeId: treeId, surname: '曾', givenName: '二',
      gender: Gender.male, generation: 2, generationWord: '祖',
    );
    await personRepo.insert(
      treeId: treeId, surname: '曾', givenName: '三',
      gender: Gender.male, generation: 2, generationWord: '祖',
    );

    // 按世代筛选
    final gen2 = await personRepo.watchAll(generation: 2).first;
    expect(gen2.length, 2);

    // 按字辈筛选
    final zu = await personRepo.watchAll(generationWord: '祖').first;
    expect(zu.length, 2);
  });

  test('删除成员级联删除关系', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '张');
    final personRepo = PersonRepository(db);
    final fatherId = await personRepo.insert(
        treeId: treeId, surname: '张', givenName: '父', gender: Gender.male);
    final childId = await personRepo.insert(
        treeId: treeId, surname: '张', givenName: '子', gender: Gender.male);

    // 创建父子关系
    await db.into(db.relationships).insert(
          RelationshipsCompanion.insert(
            treeId: treeId,
            fromPersonId: fatherId,
            toPersonId: childId,
            type: RelationType.father,
          ),
        );

    // 删除父亲
    await personRepo.delete(fatherId);

    // 父亲被删除
    expect(await personRepo.getById(fatherId), isNull);
    // 关系被级联删除
    final rels = await (db.select(db.relationships)
          ..where((tbl) =>
              tbl.fromPersonId.equals(fatherId) |
              tbl.toPersonId.equals(fatherId)))
        .get();
    expect(rels.length, 0);
    // 子女仍存在
    expect(await personRepo.getById(childId), isNotNull);
  });

  test('获取世代/房支/字辈去重列表', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '刘');
    final personRepo = PersonRepository(db);
    await personRepo.insert(
      treeId: treeId, surname: '刘', givenName: '一',
      gender: Gender.male, generation: 1, generationWord: '德', branch: '长房',
    );
    await personRepo.insert(
      treeId: treeId, surname: '刘', givenName: '二',
      gender: Gender.male, generation: 2, generationWord: '明', branch: '长房',
    );
    await personRepo.insert(
      treeId: treeId, surname: '刘', givenName: '三',
      gender: Gender.male, generation: 2, generationWord: '明', branch: '二房',
    );

    expect(await personRepo.getGenerations(treeId), [1, 2]);
    expect(await personRepo.getBranches(treeId), containsAll(['长房', '二房']));
    expect(await personRepo.getGenerationWords(treeId),
        containsAll(['德', '明']));
  });

  // ==================== 关系测试 ====================

  test('创建父子关系并查询子女', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '孔');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);

    final fatherId = await personRepo.insert(
        treeId: treeId, surname: '孔', givenName: '父', gender: Gender.male);
    final childId = await personRepo.insert(
        treeId: treeId, surname: '孔', givenName: '子', gender: Gender.male);

    await relRepo.insert(
      treeId: treeId,
      fromPersonId: fatherId,
      toPersonId: childId,
      type: RelationType.father,
    );

    final children = await relRepo.getChildren(fatherId);
    expect(children.length, 1);
    expect(children.first.id, childId);

    final father = await relRepo.getFather(childId);
    expect(father, isNotNull);
    expect(father!.id, fatherId);
  });

  test('创建配偶关系', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '周');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);

    final husbandId = await personRepo.insert(
        treeId: treeId, surname: '周', givenName: '夫', gender: Gender.male);
    final wifeId = await personRepo.insert(
        treeId: treeId, surname: '吴', givenName: '妻', gender: Gender.female);

    await relRepo.insert(
      treeId: treeId,
      fromPersonId: husbandId,
      toPersonId: wifeId,
      type: RelationType.spouse,
      note: '元配',
    );

    final spouses = await relRepo.getSpouses(husbandId);
    expect(spouses.length, 1);
    expect(spouses.first.person.id, wifeId);
    expect(spouses.first.rel.note, '元配');
  });

  test('循环关系检测：不能让子女成为父亲', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '郑');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);

    final fatherId = await personRepo.insert(
        treeId: treeId, surname: '郑', givenName: '父', gender: Gender.male);
    final childId = await personRepo.insert(
        treeId: treeId, surname: '郑', givenName: '子', gender: Gender.male);

    // 先建立父子关系
    await relRepo.insert(
      treeId: treeId,
      fromPersonId: fatherId,
      toPersonId: childId,
      type: RelationType.father,
    );

    // 尝试让儿子成为父亲的父亲（循环）
    expect(
      () => relRepo.insert(
        treeId: treeId,
        fromPersonId: childId,
        toPersonId: fatherId,
        type: RelationType.father,
      ),
      throwsA(isA<RelationshipException>()),
    );
  });

  test('不能与自己建立关系', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '冯');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);

    final personId = await personRepo.insert(
        treeId: treeId, surname: '冯', givenName: '一', gender: Gender.male);

    expect(
      () => relRepo.insert(
        treeId: treeId,
        fromPersonId: personId,
        toPersonId: personId,
        type: RelationType.spouse,
      ),
      throwsA(isA<RelationshipException>()),
    );
  });

  test('构建后代族谱树', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '杨');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);

    final rootId = await personRepo.insert(
        treeId: treeId, surname: '杨', givenName: '根', gender: Gender.male);
    final child1Id = await personRepo.insert(
        treeId: treeId, surname: '杨', givenName: '大', gender: Gender.male);
    final child2Id = await personRepo.insert(
        treeId: treeId, surname: '杨', givenName: '二', gender: Gender.male);
    final grandchildId = await personRepo.insert(
        treeId: treeId, surname: '杨', givenName: '孙', gender: Gender.male);

    await relRepo.insert(
        treeId: treeId, fromPersonId: rootId, toPersonId: child1Id, type: RelationType.father);
    await relRepo.insert(
        treeId: treeId, fromPersonId: rootId, toPersonId: child2Id, type: RelationType.father);
    await relRepo.insert(
        treeId: treeId, fromPersonId: child1Id, toPersonId: grandchildId, type: RelationType.father);

    final tree = await relRepo.buildDescendantTree(rootPersonId: rootId);
    expect(tree.person.id, rootId);
    expect(tree.children.length, 2);
    expect(tree.children.first.children.length, 1);
    expect(tree.children.first.children.first.person.id, grandchildId);
  });

  test('删除关系不影响成员', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '朱');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);

    final aId = await personRepo.insert(
        treeId: treeId, surname: '朱', givenName: 'A', gender: Gender.male);
    final bId = await personRepo.insert(
        treeId: treeId, surname: '朱', givenName: 'B', gender: Gender.male);

    final relId = await relRepo.insert(
      treeId: treeId,
      fromPersonId: aId,
      toPersonId: bId,
      type: RelationType.father,
    );

    await relRepo.delete(relId);

    // 关系被删除
    expect(await relRepo.getChildren(aId), isEmpty);
    // 成员仍然存在
    expect(await personRepo.getById(aId), isNotNull);
    expect(await personRepo.getById(bId), isNotNull);
  });

  // ==================== 事件测试 ====================

  test('创建事件并查询', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '林');
    final personRepo = PersonRepository(db);
    final eventRepo = EventRepository(db);

    final personId = await personRepo.insert(
        treeId: treeId, surname: '林', givenName: '则徐', gender: Gender.male);

    final eventId = await eventRepo.insert(
      treeId: treeId,
      personId: personId,
      type: EventType.honor,
      title: '高中进士',
      date: DateTime(1811, 4, 27),
      place: '北京',
      description: '殿试二甲第三名',
    );

    final event = await eventRepo.getById(eventId);
    expect(event, isNotNull);
    expect(event!.title, '高中进士');
    expect(event.type, EventType.honor);
    expect(event.personId, personId);
    expect(event.place, '北京');
  });

  test('按家族和成员查询事件', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '黄');
    final personRepo = PersonRepository(db);
    final eventRepo = EventRepository(db);

    final p1 = await personRepo.insert(
        treeId: treeId, surname: '黄', givenName: '一', gender: Gender.male);
    final p2 = await personRepo.insert(
        treeId: treeId, surname: '黄', givenName: '二', gender: Gender.male);

    await eventRepo.insert(
        treeId: treeId, personId: p1, type: EventType.birth, title: '出生');
    await eventRepo.insert(
        treeId: treeId, personId: p1, type: EventType.marriage, title: '结婚');
    await eventRepo.insert(
        treeId: treeId, personId: p2, type: EventType.birth, title: '出生');

    // 按家族查询
    final treeEvents = await eventRepo.watchByTree(treeId).first;
    expect(treeEvents.length, 3);

    // 按成员查询
    final p1Events = await eventRepo.watchByPerson(p1).first;
    expect(p1Events.length, 2);
    expect(p1Events.map((e) => e.title), containsAll(['出生', '结婚']));
  });

  test('更新事件信息', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '徐');
    final personRepo = PersonRepository(db);
    final eventRepo = EventRepository(db);

    final personId = await personRepo.insert(
        treeId: treeId, surname: '徐', givenName: '一', gender: Gender.male);
    final eventId = await eventRepo.insert(
      treeId: treeId,
      personId: personId,
      type: EventType.other,
      title: '旧标题',
    );

    final updated = await eventRepo.update(
      id: eventId,
      type: EventType.migration,
      title: '迁居南方',
      place: '南京',
    );
    expect(updated, true);

    final event = await eventRepo.getById(eventId);
    expect(event!.type, EventType.migration);
    expect(event.title, '迁居南方');
    expect(event.place, '南京');
  });

  test('删除成员级联删除事件', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '何');
    final personRepo = PersonRepository(db);
    final eventRepo = EventRepository(db);

    final personId = await personRepo.insert(
        treeId: treeId, surname: '何', givenName: '一', gender: Gender.male);
    await eventRepo.insert(
        treeId: treeId, personId: personId, type: EventType.birth, title: '出生');
    await eventRepo.insert(
        treeId: treeId, personId: personId, type: EventType.death, title: '去世');

    // 删除成员
    await personRepo.delete(personId);

    // 事件被级联删除
    final events = await eventRepo.watchByPerson(personId).first;
    expect(events, isEmpty);
  });

  test('删除事件不影响成员', () async {
    final treeId = await repo.insert(name: '测试家族', surname: '吕');
    final personRepo = PersonRepository(db);
    final eventRepo = EventRepository(db);

    final personId = await personRepo.insert(
        treeId: treeId, surname: '吕', givenName: '一', gender: Gender.male);
    final eventId = await eventRepo.insert(
        treeId: treeId, personId: personId, type: EventType.birth, title: '出生');

    await eventRepo.delete(eventId);

    expect(await eventRepo.getById(eventId), isNull);
    expect(await personRepo.getById(personId), isNotNull);
  });

  // ==================== 备份恢复测试 ====================

  test('导出 JSON 并恢复（覆盖模式）', () async {
    final treeId = await repo.insert(name: '备份测试家族', surname: '秦');
    final personRepo = PersonRepository(db);
    final eventRepo = EventRepository(db);
    final backupService = BackupService(db);

    // 创建测试数据
    final personId = await personRepo.insert(
      treeId: treeId,
      surname: '秦',
      givenName: '桧',
      gender: Gender.male,
      generation: 1,
    );
    await eventRepo.insert(
      treeId: treeId,
      personId: personId,
      type: EventType.birth,
      title: '出生',
    );

    // 导出
    final json = await backupService.exportToJson();
    expect(json, contains('备份测试家族'));
    expect(json, contains('秦'));

    // 清空数据
    await backupService.clearAllData();
    expect(await repo.getById(treeId), isNull);

    // 恢复
    final stats = await backupService.importFromJson(json, merge: false);
    expect(stats.families, 1);
    expect(stats.persons, 1);
    expect(stats.events, 1);

    // 验证数据
    final restoredFamily = await repo.getById(treeId);
    expect(restoredFamily, isNotNull);
    expect(restoredFamily!.name, '备份测试家族');

    final restoredPerson = await personRepo.getById(personId);
    expect(restoredPerson, isNotNull);
    expect(restoredPerson!.surname, '秦');
  });

  test('备份版本过高应报错', () async {
    final backupService = BackupService(db);
    const invalidJson = '{"version": 999, "families": []}';

    expect(
      () => backupService.importFromJson(invalidJson),
      throwsA(isA<BackupException>()),
    );
  });

  test('清空所有数据', () async {
    final treeId = await repo.insert(name: '待清空家族', surname: '尤');
    final personRepo = PersonRepository(db);
    await personRepo.insert(
        treeId: treeId, surname: '尤', givenName: '一', gender: Gender.male);

    final backupService = BackupService(db);
    await backupService.clearAllData();

    expect(await repo.getById(treeId), isNull);
    final allPersons = await personRepo.watchAll().first;
    expect(allPersons, isEmpty);
  });

  // ==================== GEDCOM 测试 ====================

  test('GEDCOM 导入：解析 INDI 记录创建成员', () async {
    final treeId = await repo.insert(name: 'GEDCOM测试家族', surname: '张');
    final personRepo = PersonRepository(db);
    final gedcomService = GedcomService(db);

    const gedcom = '''
0 HEAD
1 GEDC
2 VERS 5.5.1
0 @I1@ INDI
1 NAME 三 /张/
1 SEX M
1 BIRT
2 DATE 1 JAN 1900
2 PLAC 广东肇庆
1 OCCU 教师
1 NOTE 这是备注信息
0 @I2@ INDI
1 NAME 四 /李/
1 SEX F
1 BIRT
2 DATE 5 FEB 1905
0 TRLR
''';

    final stats = await gedcomService.importFromGedcom(gedcom, treeId: treeId);
    expect(stats.individuals, 2);

    final persons = await personRepo.watchAll(treeId: treeId).first;
    expect(persons.length, 2);

    final zhang = persons.firstWhere((p) => p.surname == '张');
    expect(zhang.givenName, '三');
    expect(zhang.gender, Gender.male);
    expect(zhang.birthDate, isNotNull);
    expect(zhang.birthPlace, '广东肇庆');
    expect(zhang.occupation, '教师');
    expect(zhang.biography, '这是备注信息');
  });

  test('GEDCOM 导入：解析 FAM 记录建立配偶和子女关系', () async {
    final treeId = await repo.insert(name: 'GEDCOM家庭测试', surname: '王');
    final relRepo = RelationshipRepository(db);
    final gedcomService = GedcomService(db);

    const gedcom = '''
0 HEAD
1 GEDC
2 VERS 5.5.1
0 @I1@ INDI
1 NAME 大 /王/
1 SEX M
0 @I2@ INDI
1 NAME 氏 /赵/
1 SEX F
0 @I3@ INDI
1 NAME 小 /王/
1 SEX M
0 @F1@ FAM
1 HUSB @I1@
1 WIFE @I2@
1 CHIL @I3@
1 MARR
2 DATE 10 OCT 1920
2 PLAC 北京
0 TRLR
''';

    final stats = await gedcomService.importFromGedcom(gedcom, treeId: treeId);
    expect(stats.individuals, 3);
    expect(stats.families, 1);

    // 验证配偶关系
    final persons = await PersonRepository(db).watchAll(treeId: treeId).first;
    final father = persons.firstWhere((p) => p.givenName == '大');
    final mother = persons.firstWhere((p) => p.surname == '赵');
    final child = persons.firstWhere((p) => p.givenName == '小');

    final spouses = await relRepo.getSpouses(father.id);
    expect(spouses.length, 1);
    expect(spouses.first.person.id, mother.id);

    final children = await relRepo.getChildren(father.id);
    expect(children.length, 1);
    expect(children.first.id, child.id);
  });

  test('GEDCOM 导出：生成符合标准的 GEDCOM 文件', () async {
    final treeId = await repo.insert(name: '导出测试', surname: '陈');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);
    final gedcomService = GedcomService(db);

    final fatherId = await personRepo.insert(
      treeId: treeId, surname: '陈', givenName: '父', gender: Gender.male,
      birthDate: DateTime(1900, 1, 1), birthPlace: '广州',
    );
    final motherId = await personRepo.insert(
      treeId: treeId, surname: '林', givenName: '母', gender: Gender.female,
    );
    final childId = await personRepo.insert(
      treeId: treeId, surname: '陈', givenName: '子', gender: Gender.male,
    );

    await relRepo.insert(
      treeId: treeId, fromPersonId: fatherId, toPersonId: motherId,
      type: RelationType.spouse,
    );
    await relRepo.insert(
      treeId: treeId, fromPersonId: fatherId, toPersonId: childId,
      type: RelationType.child,
    );

    final gedcom = await gedcomService.exportToGedcom(treeId);

    // 验证 GEDCOM 头部
    expect(gedcom, contains('0 HEAD'));
    expect(gedcom, contains('2 VERS 5.5.1'));
    expect(gedcom, contains('1 CHAR UTF-8'));

    // 验证 INDI 记录
    expect(gedcom, contains('INDI'));
    expect(gedcom, contains('NAME 父 /陈/'));
    expect(gedcom, contains('1 SEX M'));
    expect(gedcom, contains('1 BIRT'));
    expect(gedcom, contains('2 PLAC 广州'));

    // 验证 FAM 记录
    expect(gedcom, contains('FAM'));
    expect(gedcom, contains('1 HUSB'));
    expect(gedcom, contains('1 WIFE'));
    expect(gedcom, contains('1 CHIL'));

    // 验证结尾
    expect(gedcom, contains('0 TRLR'));
  });

  test('GEDCOM 往返：导出后再导入数据一致', () async {
    final treeId = await repo.insert(name: '往返测试', surname: '周');
    final personRepo = PersonRepository(db);
    final relRepo = RelationshipRepository(db);
    final gedcomService = GedcomService(db);

    final p1 = await personRepo.insert(
      treeId: treeId, surname: '周', givenName: '伯', gender: Gender.male,
      occupation: '农夫',
    );
    final p2 = await personRepo.insert(
      treeId: treeId, surname: '吴', givenName: '婶', gender: Gender.female,
    );
    await relRepo.insert(
      treeId: treeId, fromPersonId: p1, toPersonId: p2,
      type: RelationType.spouse,
    );

    // 导出
    final gedcom = await gedcomService.exportToGedcom(treeId);

    // 导入到新家族
    final treeId2 = await repo.insert(name: '往返测试2', surname: '周');
    final stats = await gedcomService.importFromGedcom(gedcom, treeId: treeId2);

    expect(stats.individuals, 2);
    expect(stats.families, 1);

    final importedPersons = await personRepo.watchAll(treeId: treeId2).first;
    expect(importedPersons.length, 2);
    final importedZhou = importedPersons.firstWhere((p) => p.surname == '周');
    expect(importedZhou.givenName, '伯');
    expect(importedZhou.occupation, '农夫');
  });

  // ==================== 跨家族搜索 ====================

  test('跨家族搜索：不传 treeId 时搜索所有家族成员', () async {
    final personRepo = PersonRepository(db);

    // 创建两个家族
    final treeId1 = await repo.insert(name: '陈家', surname: '陈');
    final treeId2 = await repo.insert(name: '李家', surname: '李');

    // 在两个家族中各添加成员
    await personRepo.insert(
      treeId: treeId1,
      surname: '陈',
      givenName: '元璋',
      gender: Gender.male,
      generation: 1,
    );
    await personRepo.insert(
      treeId: treeId2,
      surname: '李',
      givenName: '元霸',
      gender: Gender.male,
      generation: 1,
    );
    await personRepo.insert(
      treeId: treeId1,
      surname: '陈',
      givenName: '友谅',
      gender: Gender.male,
      generation: 2,
    );

    // 跨家族搜索"元"字，应返回 2 人（陈元璋、李元霸）
    final results = await personRepo.watchAll(keyword: '元').first;
    expect(results.length, 2);
    final surnames = results.map((p) => p.surname).toSet();
    expect(surnames, contains('陈'));
    expect(surnames, contains('李'));

    // 限定家族搜索只返回该家族成员
    final chenOnly = await personRepo.watchAll(treeId: treeId1, keyword: '元').first;
    expect(chenOnly.length, 1);
    expect(chenOnly.first.surname, '陈');
  });

  test('跨家族搜索：按字辈筛选所有家族', () async {
    final personRepo = PersonRepository(db);

    final treeId1 = await repo.insert(name: '王家', surname: '王');
    final treeId2 = await repo.insert(name: '赵家', surname: '赵');

    await personRepo.insert(
      treeId: treeId1, surname: '王', givenName: '明',
      gender: Gender.male, generation: 1, generationWord: '文',
    );
    await personRepo.insert(
      treeId: treeId2, surname: '赵', givenName: '文',
      gender: Gender.male, generation: 1, generationWord: '文',
    );
    await personRepo.insert(
      treeId: treeId1, surname: '王', givenName: '武',
      gender: Gender.male, generation: 2, generationWord: '武',
    );

    // 按字辈"文"跨家族搜索
    final results = await personRepo.watchAll(generationWord: '文').first;
    expect(results.length, 2);
  });

  // ==================== 数据库迁移 ====================

  test('数据库 schemaVersion 为 2', () async {
    expect(db.schemaVersion, 2);
  });

  test('数据库迁移后索引存在', () async {
    // 查询 sqlite_master 验证索引已创建
    final result = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
    ).get();

    final indexNames = result.map((r) => r.data['name'] as String).toList();

    // 验证关键索引存在
    expect(indexNames, contains('idx_persons_tree_id'));
    expect(indexNames, contains('idx_persons_generation'));
    expect(indexNames, contains('idx_relationships_tree_id'));
    expect(indexNames, contains('idx_relationships_from_person'));
    expect(indexNames, contains('idx_relationships_to_person'));
    expect(indexNames, contains('idx_events_person_id'));
    expect(indexNames, contains('idx_events_tree_id'));
  });

  test('外键约束已启用', () async {
    final result = await db.customSelect('PRAGMA foreign_keys').get();
    expect(result.first.data['foreign_keys'], 1);
  });
}
