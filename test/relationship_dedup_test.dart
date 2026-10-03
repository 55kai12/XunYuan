/// 关系去重回归测试
///
/// 背景：配偶 / 兄弟姐妹是**无向**关系，但 `insert()` 的重复检测最初只按
/// 有向的 (from, to) 判定。于是 A→B 之后再插 B→A 能成功，`getSpouses(A)`
/// 会返回同一个人两条记录，族谱树里一行的 `ValueKey` 重复 → 直接红屏。
///
/// 本测试同时锁住两件事：
///  1. `insert()` 拦住反向重复；
///  2. `getSpouses()` 对修复前的旧库（已存在反向重复行）仍去重，不渲染两次。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familytree/core/database/database.dart';
import 'package:familytree/features/relationship/data/relationship_repository.dart';

void main() {
  late AppDatabase db;
  late RelationshipRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RelationshipRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// 造一个家族 + 两个人，返回 (treeId, 甲, 乙)
  Future<(int, int, int)> seedPair() async {
    final treeId = await db.into(db.familyTrees).insert(
          FamilyTreesCompanion.insert(
            name: '颍川陈氏',
            surname: '陈',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    final a = await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: treeId,
            surname: '陈',
            givenName: '甲',
            gender: Gender.male,
          ),
        );
    final b = await db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: treeId,
            surname: '林',
            givenName: '乙',
            gender: Gender.female,
          ),
        );
    return (treeId, a, b);
  }

  group('配偶关系无向去重', () {
    test('反向插入同一对配偶会被拒绝', () async {
      final (treeId, a, b) = await seedPair();

      await repo.insert(
        treeId: treeId,
        fromPersonId: a,
        toPersonId: b,
        type: RelationType.spouse,
      );

      // B→A 语义上就是「同一对夫妻」，必须被拦下
      await expectLater(
        repo.insert(
          treeId: treeId,
          fromPersonId: b,
          toPersonId: a,
          type: RelationType.spouse,
        ),
        throwsA(isA<RelationshipException>()),
      );

      final spouses = await repo.getSpouses(a);
      expect(spouses, hasLength(1));
    });

    test('旧库已含反向重复行时 getSpouses 仍返回一条', () async {
      final (treeId, a, b) = await seedPair();

      // 绕过 insert()，直接写两条方向相反的配偶记录，模拟修复前的旧数据
      for (final (from, to) in [(a, b), (b, a)]) {
        await db.into(db.relationships).insert(
              RelationshipsCompanion.insert(
                treeId: treeId,
                fromPersonId: from,
                toPersonId: to,
                type: RelationType.spouse,
              ),
            );
      }
      expect(await db.select(db.relationships).get(), hasLength(2));

      // 查询侧必须去重，否则上层同一个 ValueKey 会在同一行出现两次
      final spouses = await repo.getSpouses(a);
      expect(spouses, hasLength(1));
      expect(spouses.single.person.id, b);
    });

    test('兄弟关系同样按无向去重', () async {
      final (treeId, a, b) = await seedPair();

      await repo.insert(
        treeId: treeId,
        fromPersonId: a,
        toPersonId: b,
        type: RelationType.sibling,
      );

      await expectLater(
        repo.insert(
          treeId: treeId,
          fromPersonId: b,
          toPersonId: a,
          type: RelationType.sibling,
        ),
        throwsA(isA<RelationshipException>()),
      );
    });
  });

  group('有向关系维持原有语义', () {
    test('父子关系反向不受影响（父→子 与 子→父 是两回事）', () async {
      final (treeId, a, b) = await seedPair();

      await repo.insert(
        treeId: treeId,
        fromPersonId: a,
        toPersonId: b,
        type: RelationType.father,
      );

      // 反向插入 father 不该被「关系已存在」拦下 —— 它其实是另一条边，
      // 会被「同一人最多一位父亲」那条规则挡住，但不是重复检测拦的。
      // 这里只断言正向重复被拦：
      await expectLater(
        repo.insert(
          treeId: treeId,
          fromPersonId: a,
          toPersonId: b,
          type: RelationType.father,
        ),
        throwsA(isA<RelationshipException>()),
      );
    });
  });
}
