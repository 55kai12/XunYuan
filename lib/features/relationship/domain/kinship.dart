/// 亲属称谓计算
///
/// 以某人为中心，推导其他成员的称呼（父亲/伯父/堂兄/儿媳/岳父…）。
///
/// 做法：把关系图当作无向图，四类边分别是
///   上（到父母）、下（到子女）、侧（配偶）、横（兄弟姐妹），
/// 从中心人做 BFS 取最短路径，再把路径翻译成称谓。
///
/// 路径记号：设 上^a 下^b 表示「先向上 a 代，再向下 b 代」。
/// 展开后的节点序列 nodes 与步序列 moves 一一对应（nodes.length == moves.length + 1）：
///   nodes[0]        = 中心人
///   nodes[1..a]     = 上行途中的祖先
///   nodes[a+1..a+b] = 下行途中的人（nodes[a+b] 即目标）
/// 于是：目标 = nodes[a+b]；旁系分支上那位 = nodes[a+1]；
/// 长幼参照人 = nodes[a-b]（a>=b 时恰好落在直系上的同辈）。
///
/// 精度边界：上下行各 3 代以内、以及一侧姻亲给准确称谓；
/// 更远的关系退化为描述性称呼或「远亲」—— 不会算错，只会不精细。
library;

import '../../../core/database/database.dart';
import '../../../core/i18n/i18n.dart';

/// 图上的一步
enum _Move { up, down, side, sibling }

/// BFS 前驱记录
class _Step {
  const _Step(this.prevId, this.move);
  final int prevId;
  final _Move move;
}

/// 计算以 [centerId] 为中心的亲属称谓
///
/// 返回 personId → 称呼；中心人自己为「本人」。
/// 与中心人不连通的成员不会出现在结果里。
Map<int, String> buildKinshipTerms({
  required int centerId,
  required List<Person> persons,
  required List<Relationship> relationships,
}) {
  final byId = <int, Person>{for (final p in persons) p.id: p};
  final center = byId[centerId];
  if (center == null) return const {};

  final parents = <int, List<int>>{};
  final children = <int, List<int>>{};
  final spouses = <int, Set<int>>{};
  final siblings = <int, Set<int>>{};

  void link(Map<int, Set<int>> m, int a, int b) => (m[a] ??= <int>{}).add(b);

  for (final r in relationships) {
    final from = r.fromPersonId;
    final to = r.toPersonId;
    if (!byId.containsKey(from) || !byId.containsKey(to)) continue;
    switch (r.type) {
      // 父母类与 child 均为 from=父母、to=子女
      case RelationType.father:
      case RelationType.mother:
      case RelationType.adoptiveFather:
      case RelationType.adoptiveMother:
      case RelationType.child:
        (parents[to] ??= <int>[]).add(from);
        (children[from] ??= <int>[]).add(to);
        break;
      case RelationType.spouse:
        link(spouses, from, to);
        link(spouses, to, from);
        break;
      case RelationType.sibling:
        link(siblings, from, to);
        link(siblings, to, from);
        break;
    }
  }

  // ---- BFS：求每个人到中心人的最短路径 ----
  final prev = <int, _Step?>{centerId: null};
  final queue = <int>[centerId];
  for (var head = 0; head < queue.length; head++) {
    final cur = queue[head];
    void visit(int next, _Move mv) {
      if (prev.containsKey(next)) return;
      prev[next] = _Step(cur, mv);
      queue.add(next);
    }

    for (final p in parents[cur] ?? const <int>[]) {
      visit(p, _Move.up);
    }
    for (final c in children[cur] ?? const <int>[]) {
      visit(c, _Move.down);
    }
    for (final s in spouses[cur] ?? const <int>{}) {
      visit(s, _Move.side);
    }
    for (final s in siblings[cur] ?? const <int>{}) {
      visit(s, _Move.sibling);
    }
  }

  // ---- 逐人回溯路径并翻译 ----
  final result = <int, String>{centerId: '本人'.tr};
  for (final id in queue) {
    if (id == centerId) continue;
    final backNodes = <int>[id];
    final backMoves = <_Move>[];
    var cur = id;
    while (true) {
      final step = prev[cur];
      if (step == null) break;
      backMoves.add(step.move);
      cur = step.prevId;
      backNodes.add(cur);
    }
    final nodes = backNodes.reversed.toList();
    final moves = backMoves.reversed.toList();
    result[id] = moves.length > 12
        ? '远亲'.tr
        : _term(
            moves: moves,
            nodes: nodes,
            byId: byId,
            parents: parents,
            center: center,
          );
  }
  return result;
}

/// 把一条路径翻译成称呼
String _term({
  required List<_Move> moves,
  required List<int> nodes,
  required Map<int, Person> byId,
  required Map<int, List<int>> parents,
  required Person center,
}) {
  // 把「横」步展开成 上→共同父母→下，使路径只由 上/下/侧 组成
  final exMoves = <_Move>[];
  final exNodes = <int>[nodes.first];
  for (var i = 0; i < moves.length; i++) {
    if (moves[i] == _Move.sibling) {
      final shared = _sharedParent(nodes[i], nodes[i + 1], parents);
      exMoves.add(_Move.up);
      exNodes.add(shared ?? -1); // -1 = 未知占位，只用于保持下标对齐
      exMoves.add(_Move.down);
      exNodes.add(nodes[i + 1]);
    } else {
      exMoves.add(moves[i]);
      exNodes.add(nodes[i + 1]);
    }
  }

  // 剥离前导 / 后置的配偶步（两侧姻亲）
  var start = 0;
  var end = exMoves.length;
  var leadSide = 0;
  var trailSide = 0;
  while (start < end && exMoves[start] == _Move.side) {
    start++;
    leadSide++;
  }
  while (end > start && exMoves[end - 1] == _Move.side) {
    end--;
    trailSide++;
  }

  final midMoves = exMoves.sublist(start, end);
  final midNodes = exNodes.sublist(start, end + 1);
  final target = byId[exNodes.last];

  if (midMoves.isEmpty) {
    if (leadSide + trailSide == 1) return _spouseWord(target);
    if (leadSide + trailSide == 0) return '本人'.tr;
    return '姻亲'.tr;
  }

  // 中间段必须是 上^a 下^b
  var a = 0;
  var b = 0;
  var i = 0;
  while (i < midMoves.length && midMoves[i] == _Move.up) {
    a++;
    i++;
  }
  while (i < midMoves.length && midMoves[i] == _Move.down) {
    b++;
    i++;
  }
  if (i != midMoves.length) {
    return _chainFallback(midMoves, midNodes, byId);
  }

  final base = _bloodTerm(
    a: a,
    b: b,
    nodes: midNodes,
    byId: byId,
    center: center,
  );
  if (base == null) return _chainFallback(midMoves, midNodes, byId);

  var term = base;
  if (trailSide == 1) {
    term = _spouseOf(term);
  } else if (trailSide > 1) {
    return '姻亲'.tr;
  }
  if (leadSide == 1) {
    return _spouseSideOf(term, center);
  } else if (leadSide > 1) {
    return '姻亲'.tr;
  }
  return term;
}

/// 血亲段的称谓；[nodes] 长度为 a+b+1
String? _bloodTerm({
  required int a,
  required int b,
  required List<int> nodes,
  required Map<int, Person> byId,
  required Person center,
}) {
  Person? at(int i) => byId[nodes[i]];

  // 直系长辈：上 a 代
  if (b == 0 && a >= 1) return _ancestorTerm(a, at(a));

  // 直系晚辈：下 b 代（b>=2 且第一代是女儿时加「外」）
  if (a == 0 && b >= 1) {
    final viaDaughter = b >= 2 && at(1)?.gender == Gender.female;
    return _descendantTerm(b, at(b), viaDaughter);
  }

  final parent = at(1); // 第一代上行的那位（父/母）
  final target = at(a + b); // 目标
  final collateral = at(a + 1); // 旁系分支上那位（下行第一人）
  final ref = a >= b ? at(a - b) : null; // 长幼参照人（同辈/上一辈）

  // 兄弟姐妹
  if (a == 1 && b == 1) return _siblingTerm(target, ref);

  // 兄弟姐妹的后代
  if (a == 1 && b == 2) return _gender(target, '侄子', '侄女', '侄子');
  if (a == 1 && b == 3) return _gender(target, '侄孙', '侄孙女', '侄孙');
  if (a == 1 && b >= 4) return '${b - 1}世侄孙'.tr;

  // 父母的兄弟姐妹
  if (a == 2 && b == 1) {
    final paternal = parent?.gender == Gender.male;
    final elder = _ageOrder(collateral, ref) < 0;
    if (paternal) {
      if (collateral?.gender == Gender.female) return '姑母'.tr;
      return elder ? '伯父'.tr : '叔父'.tr;
    }
    if (collateral?.gender == Gender.female) return '姨母'.tr;
    return '舅父'.tr;
  }

  // 堂 / 表兄弟姐妹
  if (a == 2 && b == 2) {
    return _cousinTerm(target, ref, _isPaternal(parent, collateral));
  }

  // 堂 / 表侄辈
  if (a == 2 && b == 3) {
    final p = _isPaternal(parent, collateral) ? '堂' : '表';
    return '$p${_gender(target, '侄', '侄女', '侄')}'.tr;
  }
  if (a == 2 && b >= 4) {
    final p = _isPaternal(parent, collateral) ? '堂' : '表';
    return '$p${b - 2}世侄孙'.tr;
  }

  // 祖辈的兄弟姐妹
  if (a == 3 && b == 1) {
    final paternal = parent?.gender == Gender.male;
    final elder = _ageOrder(collateral, ref) < 0;
    final male = collateral?.gender != Gender.female;
    if (!paternal) return male ? '舅祖父'.tr : '姨祖母'.tr;
    if (!male) return '姑祖母'.tr;
    return elder ? '伯祖父'.tr : '叔祖父'.tr;
  }

  // 祖辈兄弟姐妹的子女（＝父母的堂表亲）
  if (a == 3 && b == 2) {
    final paternal = parent?.gender == Gender.male;
    final male = collateral?.gender == Gender.male;
    final elder = _ageOrder(target, ref) < 0;
    if (paternal && male) {
      if (target?.gender == Gender.female) return '堂姑母'.tr;
      return elder ? '堂伯父'.tr : '堂叔父'.tr;
    }
    if (target?.gender == Gender.female) return '表姨母'.tr;
    return '表舅父'.tr;
  }

  // 更远的旁系：只给同类粗称呼
  if (a >= 2 && b >= 1) {
    if (a == b) return '远房堂兄弟姐妹'.tr;
    return a > b ? '远房长辈'.tr : '远房晚辈'.tr;
  }
  return null;
}

/// 直系长辈
String _ancestorTerm(int a, Person? target) {
  final f = target?.gender == Gender.female;
  switch (a) {
    case 1:
      return f ? '母亲'.tr : '父亲'.tr;
    case 2:
      return f ? '祖母'.tr : '祖父'.tr;
    case 3:
      return f ? '曾祖母'.tr : '曾祖父'.tr;
    case 4:
      return f ? '高祖母'.tr : '高祖父'.tr;
    case 5:
      return f ? '天祖母'.tr : '天祖父'.tr;
    default:
      return f ? '$a世祖母'.tr : '$a世祖'.tr;
  }
}

/// 直系晚辈；[viaDaughter] 为真时加「外」
String _descendantTerm(int d, Person? target, bool viaDaughter) {
  final f = target?.gender == Gender.female;
  final ext = viaDaughter ? '外' : '';
  switch (d) {
    case 1:
      return f ? '女儿'.tr : '儿子'.tr;
    case 2:
      return '$ext${f ? '孙女' : '孙子'}'.tr;
    case 3:
      return '$ext${f ? '曾孙女' : '曾孙'}'.tr;
    case 4:
      return '$ext${f ? '玄孙女' : '玄孙'}'.tr;
    default:
      return f ? '$d世孙女'.tr : '$d世孙'.tr;
  }
}

/// 兄弟姐妹（[ref] 为本人，用于分长幼）
String _siblingTerm(Person? target, Person? ref) {
  final diff = _ageOrder(target, ref);
  final f = target?.gender == Gender.female;
  if (diff < 0) return f ? '姐姐'.tr : '哥哥'.tr;
  if (diff > 0) return f ? '妹妹'.tr : '弟弟'.tr;
  return f ? '姐妹'.tr : '兄弟'.tr;
}

/// 堂 / 表兄弟姐妹
String _cousinTerm(Person? target, Person? ref, bool tang) {
  final diff = _ageOrder(target, ref);
  final f = target?.gender == Gender.female;
  final p = tang ? '堂' : '表';
  if (diff < 0) return '$p${f ? '姐' : '兄'}'.tr;
  if (diff > 0) return '$p${f ? '妹' : '弟'}'.tr;
  return '$p${f ? '姐妹' : '兄弟'}'.tr;
}

/// 配偶
String _spouseWord(Person? target) {
  if (target?.gender == Gender.female) return '妻子'.tr;
  if (target?.gender == Gender.male) return '丈夫'.tr;
  return '配偶'.tr;
}

/// 「某人的配偶」
String _spouseOf(String base) {
  const map = {
    '儿子': '儿媳', '女儿': '女婿',
    '孙子': '孙媳', '孙女': '孙女婿',
    '哥哥': '嫂子', '弟弟': '弟媳', '姐姐': '姐夫', '妹妹': '妹夫',
    '伯父': '伯母', '叔父': '婶母', '姑母': '姑父',
    '舅父': '舅母', '姨母': '姨父',
    '祖父': '祖母', '父亲': '母亲',
    '侄子': '侄媳', '侄女': '侄女婿',
    '堂兄': '堂嫂', '堂弟': '堂弟媳', '堂姐': '堂姐夫', '堂妹': '堂妹夫',
    '表兄': '表嫂', '表弟': '表弟媳', '表姐': '表姐夫', '表妹': '表妹夫',
  };
  final hit = map[base];
  return hit != null ? hit.tr : '$base的配偶'.tr;
}

/// 「配偶的某人」
String _spouseSideOf(String base, Person center) {
  final male = center.gender == Gender.male;
  switch (base) {
    case '父亲':
      return (male ? '岳父' : '公公').tr;
    case '母亲':
      return (male ? '岳母' : '婆婆').tr;
    case '哥哥':
      return '内兄'.tr;
    case '弟弟':
      return '内弟'.tr;
    case '姐姐':
      return '姨姐'.tr;
    case '妹妹':
      return '姨妹'.tr;
    default:
      return '配偶的$base'.tr;
  }
}

/// 路径不成「上^a 下^b」形状时的兜底：逐段拼「X的Y」
String _chainFallback(
  List<_Move> moves,
  List<int> nodes,
  Map<int, Person> byId,
) {
  if (moves.length > 4) return '远亲'.tr;
  final parts = <String>[];
  for (var i = 0; i < moves.length; i++) {
    final t = byId[nodes[i + 1]];
    switch (moves[i]) {
      case _Move.up:
        parts.add(t?.gender == Gender.female ? '母亲' : '父亲');
        break;
      case _Move.down:
        parts.add(t?.gender == Gender.female ? '女儿' : '儿子');
        break;
      case _Move.sibling:
        parts.add(t?.gender == Gender.female ? '姐妹' : '兄弟');
        break;
      case _Move.side:
        parts.add('配偶');
        break;
    }
  }
  if (parts.isEmpty) return '本人'.tr;
  return parts.join('的');
}

/// 堂 / 表判据：父系且分支上那位是男性 → 堂，否则表
bool _isPaternal(Person? parent, Person? collateral) =>
    parent?.gender == Gender.male && collateral?.gender == Gender.male;

/// 找共同父母，用于把「横」步展开成 上→下
int? _sharedParent(int a, int b, Map<int, List<int>> parents) {
  final pa = parents[a] ?? const <int>[];
  if (pa.isEmpty) return null;
  final pb = parents[b] ?? const <int>[];
  for (final p in pa) {
    if (pb.contains(p)) return p;
  }
  return pa.first;
}

/// 长幼比较：<0 表示 [a] 更长，>0 更幼，0 无法判定
int _ageOrder(Person? a, Person? b) {
  final da = a?.birthDate;
  final db = b?.birthDate;
  if (da != null && db != null && !da.isAtSameMomentAs(db)) {
    return da.isBefore(db) ? -1 : 1;
  }
  final ra = a?.rank;
  final rb = b?.rank;
  if (ra != null && rb != null && ra != rb) return ra < rb ? -1 : 1;
  return 0;
}

/// 按性别三选一
String _gender(Person? p, String male, String female, String other) {
  switch (p?.gender) {
    case Gender.male:
      return male;
    case Gender.female:
      return female;
    default:
      return other;
  }
}
