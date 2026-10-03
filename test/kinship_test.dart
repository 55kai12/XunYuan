/// 亲属称谓计算测试
///
/// 覆盖：直系长辈/晚辈、兄弟姐妹长幼、父母的兄弟姐妹（伯叔姑舅姨）、
/// 堂表亲、侄甥辈、姻亲（儿媳/女婿/岳父/岳母等）、远亲兜底、不连通。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:familytree/core/database/database.dart';
import 'package:familytree/features/relationship/domain/kinship.dart';

/// 构造成员（默认排行/生日留空，需要判长幼时显式传入）
Person mk(
  int id,
  Gender gender, {
  int? rank,
  DateTime? birthDate,
}) =>
    Person(
      id: id,
      treeId: 1,
      surname: '陈',
      givenName: 'P$id',
      gender: gender,
      rank: rank,
      birthDate: birthDate,
      isAlive: true,
    );

/// 构造关系
Relationship rel(int from, int to, RelationType type) => Relationship(
      id: from * 1000 + to,
      treeId: 1,
      fromPersonId: from,
      toPersonId: to,
      type: type,
    );

void main() {
  // ---- 基础家庭 ----
  // 1 中心男主；2 父；3 母；4 祖父；5 祖母
  // 6/7 兄/弟；8/9 姐/妹
  // 10/11/12 伯父/叔父/姑母（父之兄/弟/姐）
  // 13/14 舅父/姨母（母之兄/姐）
  // 15 堂兄（伯父之子）；16 表兄（舅父之子）
  // 17/18 侄子/侄女（兄之子/女）；19/20 儿子/女儿
  // 21 孙女（子之女）；22 外孙女（女之女）
  // 23 妻；24 儿媳；25 女婿；26/27 岳父/岳母；28 内弟
  // 99 无关成员
  final persons = <Person>[
    mk(1, Gender.male, rank: 2),
    mk(2, Gender.male, rank: 2), // 父
    mk(3, Gender.female, rank: 2), // 母
    mk(4, Gender.male, rank: 2), // 祖父
    mk(5, Gender.female, rank: 2), // 祖母
    mk(6, Gender.male, rank: 1), // 兄
    mk(7, Gender.male, rank: 3), // 弟
    mk(8, Gender.female, rank: 1), // 姐
    mk(9, Gender.female, rank: 4), // 妹
    mk(10, Gender.male, rank: 1), // 伯父
    mk(11, Gender.male, rank: 3), // 叔父
    mk(12, Gender.female, rank: 2), // 姑母
    mk(13, Gender.male, rank: 1), // 舅父
    mk(14, Gender.female, rank: 1), // 姨母
    mk(15, Gender.male, rank: 1), // 堂兄（伯父之子）
    mk(16, Gender.male, rank: 1), // 表兄（舅父之子）
    mk(17, Gender.male, rank: 3), // 侄子（兄之子）
    mk(18, Gender.female, rank: 3), // 侄女（兄之女）
    mk(19, Gender.male, rank: 3), // 儿子
    mk(20, Gender.female, rank: 3), // 女儿
    mk(21, Gender.female, rank: 4), // 孙女（子之女）
    mk(22, Gender.female, rank: 4), // 外孙女（女之女）
    mk(23, Gender.female, rank: 2), // 妻
    mk(24, Gender.female, rank: 3), // 儿媳
    mk(25, Gender.male, rank: 3), // 女婿
    mk(26, Gender.male, rank: 2), // 岳父
    mk(27, Gender.female, rank: 2), // 岳母
    mk(28, Gender.male, rank: 3), // 内弟（妻之弟）
    mk(99, Gender.male, rank: 2), // 无关成员
  ];

  final relationships = <Relationship>[
    // 中心 1 的父母
    rel(2, 1, RelationType.father),
    rel(3, 1, RelationType.mother),
    // 父 2 的父母
    rel(4, 2, RelationType.father),
    rel(5, 2, RelationType.mother),
    // 中心的兄弟姐妹
    rel(1, 6, RelationType.sibling),
    rel(1, 7, RelationType.sibling),
    rel(1, 8, RelationType.sibling),
    rel(1, 9, RelationType.sibling),
    // 父与伯/叔/姑
    rel(2, 10, RelationType.sibling),
    rel(2, 11, RelationType.sibling),
    rel(2, 12, RelationType.sibling),
    // 母与舅/姨
    rel(3, 13, RelationType.sibling),
    rel(3, 14, RelationType.sibling),
    // 伯父之子 15、舅父之子 16
    rel(10, 15, RelationType.child),
    rel(13, 16, RelationType.child),
    // 兄 6 的子女
    rel(6, 17, RelationType.child),
    rel(6, 18, RelationType.child),
    // 中心 1 与妻 23 的共同子女
    rel(1, 19, RelationType.child),
    rel(1, 20, RelationType.child),
    rel(23, 19, RelationType.child),
    rel(23, 20, RelationType.child),
    // 子 19 之女、女 20 之女
    rel(19, 21, RelationType.child),
    rel(20, 22, RelationType.child),
    // 中心 1 与妻 23
    rel(1, 23, RelationType.spouse),
    // 儿媳 24、女婿 25
    rel(19, 24, RelationType.spouse),
    rel(20, 25, RelationType.spouse),
    // 妻 23 的父母与弟
    rel(26, 23, RelationType.father),
    rel(27, 23, RelationType.mother),
    rel(23, 28, RelationType.sibling),
  ];

  final terms = buildKinshipTerms(
    centerId: 1,
    persons: persons,
    relationships: relationships,
  );

  test('中心人为本人', () {
    expect(terms[1], '本人');
  });

  test('直系长辈', () {
    expect(terms[2], '父亲');
    expect(terms[3], '母亲');
    expect(terms[4], '祖父');
    expect(terms[5], '祖母');
  });

  test('直系晚辈（含外孙）', () {
    expect(terms[19], '儿子');
    expect(terms[20], '女儿');
    expect(terms[21], '孙女');
    expect(terms[22], '外孙女');
  });

  test('兄弟姐妹分长幼', () {
    expect(terms[6], '哥哥');
    expect(terms[7], '弟弟');
    expect(terms[8], '姐姐');
    expect(terms[9], '妹妹');
  });

  test('父母的兄弟姐妹', () {
    expect(terms[10], '伯父'); // 父之兄
    expect(terms[11], '叔父'); // 父之弟
    expect(terms[12], '姑母'); // 父之姐妹
    expect(terms[13], '舅父'); // 母之兄弟
    expect(terms[14], '姨母'); // 母之姐妹
  });

  test('堂表兄弟姐妹', () {
    expect(terms[15], '堂兄'); // 伯父之子
    expect(terms[16], '表兄'); // 舅父之子
  });

  test('侄甥辈', () {
    expect(terms[17], '侄子');
    expect(terms[18], '侄女');
  });

  test('姻亲', () {
    expect(terms[23], '妻子');
    expect(terms[24], '儿媳');
    expect(terms[25], '女婿');
    expect(terms[26], '岳父'); // 妻之父
    expect(terms[27], '岳母'); // 妻之母
    expect(terms[28], '内弟'); // 妻之弟
  });

  test('不连通的成员不出现在结果里', () {
    expect(terms.containsKey(99), isFalse);
  });

  test('以妻子为中心时，丈夫的父母是公婆', () {
    final t2 = buildKinshipTerms(
      centerId: 23,
      persons: persons,
      relationships: relationships,
    );
    expect(t2[1], '丈夫');
    expect(t2[26], '父亲');
    expect(t2[19], '儿子'); // 丈夫之子，妻视角也是儿子
  });

  test('不存在的中心人返回空', () {
    final t3 = buildKinshipTerms(
      centerId: 12345,
      persons: persons,
      relationships: relationships,
    );
    expect(t3, isEmpty);
  });

  test('出生日期优先于排行判长幼', () {
    final ps = <Person>[
      mk(1, Gender.male, birthDate: DateTime(1995)),
      mk(2, Gender.male, rank: 9, birthDate: DateTime(1990)),
      mk(3, Gender.male, rank: 1, birthDate: DateTime(2000)),
    ];
    // 2 生日更早（虽 rank 更大）→ 应判为兄；3 相反 → 弟
    final rs = <Relationship>[
      rel(1, 2, RelationType.sibling),
      rel(1, 3, RelationType.sibling),
    ];
    final t = buildKinshipTerms(centerId: 1, persons: ps, relationships: rs);
    expect(t[2], '哥哥');
    expect(t[3], '弟弟');
  });
}
