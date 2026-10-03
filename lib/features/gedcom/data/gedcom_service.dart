/// GEDCOM 服务
/// 支持 GEDCOM 5.5.1 标准格式的导入与导出
/// 映射关系：
///   INDI 记录 -> Person（成员）
///   FAM 记录  -> Relationship（配偶/父母/子女关系）
///   BIRT/DEAT/MARR 等 -> Event（事件）
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';
import '../../../core/utils/event_image_store.dart';

import '../../../core/i18n/i18n.dart';
/// GEDCOM 服务
class GedcomService {
  GedcomService(this._db);

  final AppDatabase _db;

  // ==================== GEDCOM 导入 ====================

  /// 预览 GEDCOM 文件内容（只解析不写入）
  /// 返回解析统计，用于导入前确认
  GedcomImportStats previewGedcom(String gedcom) {
    final records = _parseGedcom(gedcom);
    var individuals = 0;
    var families = 0;
    var events = 0;

    for (final record in records) {
      if (record.type == 'INDI') {
        individuals++;
        // 统计个人事件（出生、去世、结婚等）
        for (final child in record.children) {
          if (['BIRT', 'DEAT', 'MARR', 'BURI', 'CHR'].contains(child.tag)) {
            events++;
          }
        }
      } else if (record.type == 'FAM') {
        families++;
        // 统计家庭事件（结婚等）
        for (final child in record.children) {
          if (['MARR', 'DIV'].contains(child.tag)) {
            events++;
          }
        }
      }
    }

    return GedcomImportStats(
      individuals: individuals,
      families: families,
      events: events,
    );
  }

  /// 从 GEDCOM 字符串导入数据到指定家族
  /// 返回导入统计
  Future<GedcomImportStats> importFromGedcom(
    String gedcom, {
    required int treeId,
    bool merge = false,
  }) async {
    final records = _parseGedcom(gedcom);
    var stats = const GedcomImportStats();

    await _db.transaction(() async {
      // GEDCOM ID -> 寻渊 Person ID 映射
      final xrefToPersonId = <String, int>{};
      // 收集 FAM 记录，待人员导入后再处理关系
      final famRecords = <_FamRecord>[];

      // 第一遍：导入所有 INDI 记录为 Person
      for (final record in records) {
        if (record.type == 'INDI') {
          final personId = await _importIndividual(record, treeId);
          xrefToPersonId[record.xref] = personId;
          stats = stats.copyWith(individuals: stats.individuals + 1);
        } else if (record.type == 'FAM') {
          famRecords.add(_parseFamRecord(record));
        }
      }

      // 第二遍：处理 FAM 记录，建立配偶和父母子女关系
      for (final fam in famRecords) {
        await _importFamily(fam, xrefToPersonId, treeId);
        stats = stats.copyWith(families: stats.families + 1);
      }
    });

    return stats;
  }

  /// 导入单个 INDI 记录
  Future<int> _importIndividual(_GedcomRecord record, int treeId) async {
    String surname = '';
    String givenName = '';
    Gender gender = Gender.other;
    DateTime? birthDate;
    String? birthPlace;
    DateTime? deathDate;
    String? deathPlace;
    String? burialPlace;
    String? occupation;
    String? title;
    String? biography;
    bool isAlive = true;
    // EVEN 事件暂存（TYPE/DATE/PLAC/NOTE），人员建好后统一入库
    final evenEvents = <(String?, DateTime?, String?, String?)>[];

    for (final child in record.children) {
      switch (child.tag) {
        case 'NAME':
          final nameParts = _parseName(child.value);
          surname = nameParts.$1;
          givenName = nameParts.$2;
          break;
        case 'SEX':
          gender = _parseGender(child.value);
          break;
        case 'BIRT':
          birthDate = _parseDateChild(child);
          birthPlace = _parsePlaceChild(child);
          break;
        case 'DEAT':
          deathDate = _parseDateChild(child);
          deathPlace = _parsePlaceChild(child);
          isAlive = false;
          break;
        case 'BURI':
          burialPlace = _parsePlaceChild(child);
          break;
        case 'OCCU':
          occupation = child.value;
          break;
        case 'TITL':
          title = child.value;
          break;
        case 'NOTE':
          biography = child.value;
          // NOTE 可能有子行的多行文本
          for (final sub in child.children) {
            if (sub.tag == 'CONT' || sub.tag == 'CONC') {
              biography = '${biography ?? ""}${sub.tag == 'CONT' ? '\n' : ''}${sub.value}';
            }
          }
          break;
        case 'EVEN':
          // 自定义事件：2 TYPE 标题 / 2 DATE / 2 PLAC / 2 NOTE(+CONT) 描述
          String? evenTitle;
          for (final sub in child.children) {
            if (sub.tag == 'TYPE' && sub.value.isNotEmpty) {
              evenTitle = sub.value;
              break;
            }
          }
          String? evenNote;
          for (final sub in child.children) {
            if (sub.tag == 'NOTE') {
              evenNote = sub.value;
              for (final n2 in sub.children) {
                if (n2.tag == 'CONT' || n2.tag == 'CONC') {
                  evenNote =
                      '${evenNote ?? ""}${n2.tag == 'CONT' ? '\n' : ''}${n2.value}';
                }
              }
            }
          }
          evenEvents.add((
            evenTitle,
            _parseDateChild(child),
            _parsePlaceChild(child),
            evenNote,
          ));
          break;
      }
    }

    // 如果姓氏为空，使用家族姓氏
    if (surname.isEmpty) {
      final family = await (_db.select(_db.familyTrees)
            ..where((f) => f.id.equals(treeId)))
          .getSingleOrNull();
      surname = family?.surname ?? '';
    }

    final personId = await _db.into(_db.persons).insert(
          PersonsCompanion.insert(
            treeId: treeId,
            surname: surname,
            givenName: givenName,
            gender: gender,
            birthDate: Value(birthDate),
            deathDate: Value(deathDate),
            isAlive: Value(isAlive),
            birthPlace: Value(birthPlace),
            deathPlace: Value(deathPlace),
            burialPlace: Value(burialPlace),
            occupation: Value(occupation),
            title: Value(title),
            biography: Value(biography),
          ),
        );

    // 创建出生事件
    if (birthDate != null || birthPlace != null) {
      await _db.into(_db.events).insert(
            EventsCompanion.insert(
              treeId: treeId,
              personId: Value(personId),
              type: EventType.birth,
              title: '出生'.tr,
              date: Value(birthDate),
              place: Value(birthPlace),
            ),
          );
    }

    // 创建去世事件
    if (deathDate != null || deathPlace != null) {
      await _db.into(_db.events).insert(
            EventsCompanion.insert(
              treeId: treeId,
              personId: Value(personId),
              type: EventType.death,
              title: '去世'.tr,
              date: Value(deathDate),
              place: Value(deathPlace),
            ),
          );
    }

    // 导入 EVEN 自定义事件
    for (final ev in evenEvents) {
      await _db.into(_db.events).insert(
            EventsCompanion.insert(
              treeId: treeId,
              personId: Value(personId),
              type: EventType.other,
              title: ev.$1 ?? '事件'.tr,
              date: Value(ev.$2),
              place: Value(ev.$3),
              description: Value(ev.$4),
            ),
          );
    }

    return personId;
  }

  /// 插入关系（已存在时跳过，保证重复导入幂等，也避免触发
  /// 关系仓库层的唯一性约束导致整个导入事务失败）
  Future<void> _insertRelIfAbsent({
    required int treeId,
    required int fromPersonId,
    required int toPersonId,
    required RelationType type,
    String? note,
  }) async {
    // 去重：有向关系按 (from, to) 判定；配偶/兄弟姐妹无向，
    // 反向已存在同样视为重复（GEDCOM 里 HUSB/WIFE 顺序不固定，
    // 同一对夫妻可能被两个 FAM 记录各写一次）。
    final undirected = type == RelationType.spouse ||
        type == RelationType.sibling;
    final existing = await (_db.select(_db.relationships)
          ..where((t) => undirected
              ? (t.type.equals(type.name) &
                  ((t.fromPersonId.equals(fromPersonId) &
                          t.toPersonId.equals(toPersonId)) |
                      (t.fromPersonId.equals(toPersonId) &
                          t.toPersonId.equals(fromPersonId))))
              : (t.fromPersonId.equals(fromPersonId) &
                  t.toPersonId.equals(toPersonId) &
                  t.type.equals(type.name))))
        .getSingleOrNull();
    if (existing != null) return;
    await _db.into(_db.relationships).insert(
          RelationshipsCompanion.insert(
            treeId: treeId,
            fromPersonId: fromPersonId,
            toPersonId: toPersonId,
            type: type,
            note: Value(note),
          ),
        );
  }

  /// 导入 FAM 记录，建立关系
  Future<void> _importFamily(
    _FamRecord fam,
    Map<String, int> xrefToPersonId,
    int treeId,
  ) async {
    final husbandId = fam.husband != null ? xrefToPersonId[fam.husband] : null;
    final wifeId = fam.wife != null ? xrefToPersonId[fam.wife] : null;

    // 配偶关系
    if (husbandId != null && wifeId != null) {
      await _insertRelIfAbsent(
        treeId: treeId,
        fromPersonId: husbandId,
        toPersonId: wifeId,
        type: RelationType.spouse,
        note: fam.marriageNote,
      );

      // 结婚事件
      if (fam.marriageDate != null || fam.marriagePlace != null) {
        await _db.into(_db.events).insert(
              EventsCompanion.insert(
                treeId: treeId,
                personId: Value(husbandId),
                type: EventType.marriage,
                title: '结婚'.tr,
                date: Value(fam.marriageDate),
                place: Value(fam.marriagePlace),
              ),
            );
      }
    }

    // 父母子女关系
    for (final childXref in fam.children) {
      final childId = xrefToPersonId[childXref];
      if (childId == null) continue;

      if (husbandId != null) {
        await _insertRelIfAbsent(
          treeId: treeId,
          fromPersonId: husbandId,
          toPersonId: childId,
          type: RelationType.father,
        );
      }
      if (wifeId != null) {
        await _insertRelIfAbsent(
          treeId: treeId,
          fromPersonId: wifeId,
          toPersonId: childId,
          type: RelationType.mother,
        );
      }
    }
  }

  // ==================== GEDCOM 导出 ====================

  /// 导出指定家族为 GEDCOM 字符串
  Future<String> exportToGedcom(int treeId) async {
    final family = await (_db.select(_db.familyTrees)
          ..where((f) => f.id.equals(treeId)))
        .getSingleOrNull();
    if (family == null) {
      throw GedcomException('家族不存在'.tr);
    }

    final persons = await (_db.select(_db.persons)
          ..where((p) => p.treeId.equals(treeId)))
        .get();
    final relationships = await (_db.select(_db.relationships)
          ..where((r) => r.treeId.equals(treeId)))
        .get();
    // 事件按人分组（出生/去世由 BIRT/DEAT 表达，不重复导出）
    final allEvents = await (_db.select(_db.events)
          ..where((e) => e.treeId.equals(treeId)))
        .get();
    final eventsByPerson = <int, List<Event>>{};
    for (final ev in allEvents) {
      if (ev.personId == null) continue;
      if (ev.type == EventType.birth || ev.type == EventType.death) continue;
      eventsByPerson.putIfAbsent(ev.personId!, () => []).add(ev);
    }

    final buffer = StringBuffer();

    // GEDCOM 头
    buffer.writeln('0 HEAD');
    buffer.writeln('1 GEDC');
    buffer.writeln('2 VERS 5.5.1');
    buffer.writeln('2 FORM LINEAGE-LINKED');
    buffer.writeln('1 CHAR UTF-8');
    buffer.writeln('1 SOUR XUNYUAN');
    buffer.writeln('2 NAME 寻渊'.tr);
    buffer.writeln('2 VERS ${AppConstants.version}');
    buffer.writeln('1 SUBM @SUBM@');
    buffer.writeln('0 @SUBM@ SUBM');
    buffer.writeln('1 NAME ${family.name}');

    // 人员 ID 映射：寻渊 ID -> GEDCOM xref
    final personIdToXref = <int, String>{};
    for (var i = 0; i < persons.length; i++) {
      personIdToXref[persons[i].id] = 'I${i + 1}';
    }

    // ===== 家庭数据统一构建 =====
    // 修复旧实现两个问题：
    // 1. FAMC 引用错乱：旧代码在"本人配偶关系列表"里 indexOf 父母的配偶
    //    关系，必然返回 -1，输出无效的 @F0@ —— 现改为 INDI 段与 FAM 段
    //    共用同一张 FAM 编号映射；
    // 2. 单亲家庭丢失：旧代码只为配偶关系生成 FAM，单亲（无配偶记录）
    //    的子女不会出现在任何 CHIL 中 —— 现为未覆盖的父母补建单亲 FAM。
    bool isParentType(RelationType t) =>
        t == RelationType.father ||
        t == RelationType.mother ||
        t == RelationType.adoptiveFather ||
        t == RelationType.adoptiveMother ||
        t == RelationType.child;

    final spouseRels = relationships
        .where((r) => r.type == RelationType.spouse)
        .toList();

    // 家庭记录：xref + 父母 + 子女 + 结婚信息
    final famRecords =
        <({String xref, int? husbandId, int? wifeId, Set<int> childIds, String? note, DateTime? startDate})>[];

    // 1) 配偶家庭：编号 F1..Fn 与 spouseRels 顺序一一对应
    //
    // 子女归属：一个人若有多段配偶关系，旧实现把「该人所有子女」塞进每一段
    // 婚姻的 CHIL，导致同一个孩子在每位配偶名下都出现一次（导入端会重复建
    // 家庭）。要按「子女的另一位父母是谁」来分配：
    //   - 找出每个子女的**另一父母**（除本婚配对象外的父母）；
    //   - 子女只在「另一父母 == 本家庭的配偶」时归入该 FAM；
    //   - 找不到另一位父母（单亲，或父母关系缺失）时，为避免丢数据，
    //     归入该人的**第一段**配偶关系，其余婚姻不再重复。
    final parentCandidatesByChild = <int, Set<int>>{};
    for (final r in relationships.where((r) => isParentType(r.type))) {
      parentCandidatesByChild.putIfAbsent(r.toPersonId, () => {}).add(r.fromPersonId);
    }

    // 先算出每个人「第一段配偶关系」的下标，供无另一位父母时兜底
    final firstFamIdxBySpouse = <int, int>{};
    for (var i = 0; i < spouseRels.length; i++) {
      firstFamIdxBySpouse.putIfAbsent(spouseRels[i].fromPersonId, () => i);
      firstFamIdxBySpouse.putIfAbsent(spouseRels[i].toPersonId, () => i);
    }

    // childId -> 归属的 FAM 下标
    final famIdxByChild = <int, int>{};
    for (var i = 0; i < spouseRels.length; i++) {
      final rel = spouseRels[i];
      final couple = {rel.fromPersonId, rel.toPersonId};
      for (final childId in parentCandidatesByChild.keys) {
        if (famIdxByChild.containsKey(childId)) continue;
        if (!parentCandidatesByChild[childId]!.any(couple.contains)) continue;
        final others = parentCandidatesByChild[childId]!.difference(couple);
        // 另一位父母在本家庭 → 明确归入本家庭
        if (others.length == couple.length - 1) {
          famIdxByChild[childId] = i;
        }
      }
    }

    final childIdsByFam = <int, Set<int>>{};
    for (final entry in parentCandidatesByChild.entries) {
      final childId = entry.key;
      final parents = entry.value;
      var idx = famIdxByChild[childId];
      if (idx == null) {
        // 兜底：没有能匹配到「另一位父母」的婚配，归入第一位父母的第一段婚姻
        for (final p in parents) {
          final f = firstFamIdxBySpouse[p];
          if (f != null) {
            idx = f;
            break;
          }
        }
      }
      if (idx != null) {
        childIdsByFam.putIfAbsent(idx, () => {}).add(childId);
      }
    }

    for (var i = 0; i < spouseRels.length; i++) {
      final rel = spouseRels[i];
      famRecords.add((
        xref: 'F${i + 1}',
        husbandId: rel.fromPersonId,
        wifeId: rel.toPersonId,
        childIds: childIdsByFam[i] ?? <int>{},
        note: rel.note,
        startDate: rel.startDate,
      ));
    }

    // 2) 单亲家庭：父母未出现在任何配偶家庭中时，补建一条 FAM 保留亲子关系
    final parentsCovered = <int>{
      for (final f in famRecords) ...[
        if (f.husbandId != null) f.husbandId!,
        if (f.wifeId != null) f.wifeId!,
      ],
    };
    final childIdsByParent = <int, Set<int>>{};
    for (final r in relationships.where((r) => isParentType(r.type))) {
      childIdsByParent.putIfAbsent(r.fromPersonId, () => {}).add(r.toPersonId);
    }
    final personById = {for (final p in persons) p.id: p};
    var famSeq = spouseRels.length;
    for (final entry in childIdsByParent.entries) {
      if (parentsCovered.contains(entry.key)) continue;
      final parent = personById[entry.key];
      if (parent == null) continue;
      famSeq++;
      final isMother = parent.gender == Gender.female;
      famRecords.add((
        xref: 'F$famSeq',
        husbandId: isMother ? null : parent.id,
        wifeId: isMother ? parent.id : null,
        childIds: entry.value,
        note: null,
        startDate: null,
      ));
    }

    // 索引：父母 -> 其所在家庭的下标（供 FAMC 查找）
    final famIdxByParent = <int, List<int>>{};
    for (var i = 0; i < famRecords.length; i++) {
      final f = famRecords[i];
      if (f.husbandId != null) {
        famIdxByParent.putIfAbsent(f.husbandId!, () => []).add(i);
      }
      if (f.wifeId != null) {
        famIdxByParent.putIfAbsent(f.wifeId!, () => []).add(i);
      }
    }

    // 导出 INDI 记录
    for (final person in persons) {
      final xref = personIdToXref[person.id]!;
      buffer.writeln('0 @$xref@ INDI');

      // 姓名
      final namePart = person.givenName.isNotEmpty ? person.givenName : '?';
      final surnamePart = person.surname.isNotEmpty ? person.surname : '';
      buffer.writeln('1 NAME $namePart /$surnamePart/');

      // 性别
      buffer.writeln('1 SEX ${_genderToGedcom(person.gender)}');

      // 出生
      if (person.birthDate != null || person.birthPlace != null) {
        buffer.writeln('1 BIRT');
        if (person.birthDate != null) {
          buffer.writeln('2 DATE ${_formatGedcomDate(person.birthDate!)}');
        }
        if (person.birthPlace != null) {
          buffer.writeln('2 PLAC ${person.birthPlace}');
        }
      }

      // 去世
      if (!person.isAlive || person.deathDate != null || person.deathPlace != null) {
        buffer.writeln('1 DEAT');
        if (person.deathDate != null) {
          buffer.writeln('2 DATE ${_formatGedcomDate(person.deathDate!)}');
        }
        if (person.deathPlace != null) {
          buffer.writeln('2 PLAC ${person.deathPlace}');
        }
      }

      // 安葬
      if (person.burialPlace != null) {
        buffer.writeln('1 BURI');
        buffer.writeln('2 PLAC ${person.burialPlace}');
      }

      // 职业
      if (person.occupation != null) {
        buffer.writeln('1 OCCU ${person.occupation}');
      }

      // 功名/头衔
      if (person.title != null) {
        buffer.writeln('1 TITL ${person.title}');
      }

      // 简介（配图标记不含在导出内）
      if (person.biography != null && person.biography!.isNotEmpty) {
        final lines = EventImageStore.strip(person.biography).split('\n');
        buffer.writeln('1 NOTE ${lines.first}');
        for (var i = 1; i < lines.length; i++) {
          buffer.writeln('2 CONT ${lines[i]}');
        }
      }

      // 事件（EVEN 结构：TYPE 为标题，NOTE 为描述；配图标记不含在导出内）
      final personEvents = eventsByPerson[person.id];
      if (personEvents != null) {
        for (final ev in personEvents) {
          buffer.writeln('1 EVEN');
          buffer.writeln(
              '2 TYPE ${ev.title.isNotEmpty ? ev.title : '事件'.tr}');
          if (ev.date != null) {
            buffer.writeln('2 DATE ${_formatGedcomDate(ev.date!)}');
          }
          if (ev.place != null && ev.place!.isNotEmpty) {
            buffer.writeln('2 PLAC ${ev.place}');
          }
          final desc = EventImageStore.strip(ev.description);
          if (desc.isNotEmpty) {
            final lines = desc.split('\n');
            buffer.writeln('2 NOTE ${lines.first}');
            for (var i = 1; i < lines.length; i++) {
              buffer.writeln('3 CONT ${lines[i]}');
            }
          }
        }
      }

      // 家庭引用（配偶 FAMS）
      for (var i = 0; i < spouseRels.length; i++) {
        final rel = spouseRels[i];
        if (rel.fromPersonId == person.id || rel.toPersonId == person.id) {
          buffer.writeln('1 FAMS @F${i + 1}@');
        }
      }

      // 父母家庭引用（FAMC）：查找"包含本人作为子女、且父母匹配"的家庭
      final parentIds = relationships
          .where((r) => isParentType(r.type) && r.toPersonId == person.id)
          .map((r) => r.fromPersonId)
          .toSet();
      if (parentIds.isNotEmpty) {
        final famIdxList = famIdxByParent[parentIds.first];
        if (famIdxList != null && famIdxList.isNotEmpty) {
          final famIdx = famIdxList.firstWhere(
            (i) => famRecords[i].childIds.contains(person.id),
            orElse: () => famIdxList.first,
          );
          buffer.writeln('1 FAMC @${famRecords[famIdx].xref}@');
        }
      }
    }

    // 导出 FAM 记录
    for (final f in famRecords) {
      buffer.writeln('0 @${f.xref}@ FAM');

      if (f.husbandId != null) {
        final husbandXref = personIdToXref[f.husbandId];
        if (husbandXref != null) {
          buffer.writeln('1 HUSB @$husbandXref@');
        }
      }
      if (f.wifeId != null) {
        final wifeXref = personIdToXref[f.wifeId];
        if (wifeXref != null) {
          buffer.writeln('1 WIFE @$wifeXref@');
        }
      }

      // 子女
      for (final childId in f.childIds) {
        final childXref = personIdToXref[childId];
        if (childXref != null) {
          buffer.writeln('1 CHIL @$childXref@');
        }
      }

      // 结婚信息
      if (f.startDate != null || (f.note != null && f.note!.isNotEmpty)) {
        buffer.writeln('1 MARR');
        if (f.startDate != null) {
          buffer.writeln('2 DATE ${_formatGedcomDate(f.startDate!)}');
        }
        if (f.note != null && f.note!.isNotEmpty) {
          buffer.writeln('2 NOTE ${f.note}');
        }
      }
    }

    buffer.writeln('0 TRLR');
    return buffer.toString();
  }

  // ==================== GEDCOM 解析工具 ====================

  /// 解析 GEDCOM 文本为记录列表
  List<_GedcomRecord> _parseGedcom(String content) {
    final lines = const LineSplitter().convert(content);
    final records = <_GedcomRecord>[];
    _GedcomRecord? currentRecord;
    final nodeStack = <_GedcomNode>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final match = RegExp(r'^(\d+)\s+(@[^@]+@\s+)?(\w+)(?:\s+(.*))?$').firstMatch(line);
      if (match == null) continue;

      final level = int.parse(match.group(1)!);
      final xref = match.group(2)?.trim().replaceAll('@', '');
      final tag = match.group(3)!;
      final value = match.group(4)?.trim() ?? '';

      if (level == 0) {
        // 新记录
        if (currentRecord != null) {
          records.add(currentRecord);
        }
        currentRecord = _GedcomRecord(xref: xref ?? '', type: tag, value: value);
        nodeStack.clear();
      } else {
        if (currentRecord == null) continue;

        final node = _GedcomNode(tag: tag, value: value);

        // 找到父节点
        while (nodeStack.isNotEmpty && nodeStack.last.level >= level) {
          nodeStack.removeLast();
        }

        if (nodeStack.isEmpty) {
          currentRecord.children.add(node);
        } else {
          nodeStack.last.children.add(node);
        }

        node.level = level;
        nodeStack.add(node);
      }
    }

    if (currentRecord != null) {
      records.add(currentRecord);
    }

    return records;
  }

  /// 解析 FAM 记录
  _FamRecord _parseFamRecord(_GedcomRecord record) {
    String? husband;
    String? wife;
    final children = <String>[];
    DateTime? marriageDate;
    String? marriagePlace;
    String? marriageNote;

    for (final child in record.children) {
      switch (child.tag) {
        case 'HUSB':
          husband = _extractXref(child.value);
          break;
        case 'WIFE':
          wife = _extractXref(child.value);
          break;
        case 'CHIL':
          final chilXref = _extractXref(child.value);
          if (chilXref != null) children.add(chilXref);
          break;
        case 'MARR':
          marriageDate = _parseDateChild(child);
          marriagePlace = _parsePlaceChild(child);
          for (final sub in child.children) {
            if (sub.tag == 'NOTE') marriageNote = sub.value;
          }
          break;
      }
    }

    return _FamRecord(
      husband: husband,
      wife: wife,
      children: children,
      marriageDate: marriageDate,
      marriagePlace: marriagePlace,
      marriageNote: marriageNote,
    );
  }

  /// 解析姓名 "John /Smith/" -> (Smith, John)
  (String, String) _parseName(String? value) {
    if (value == null || value.isEmpty) return ('', '');
    final match = RegExp(r'^(.*?)\s*/(.*?)/\s*(.*)$').firstMatch(value);
    if (match != null) {
      final given = '${match.group(1) ?? ""} ${match.group(3) ?? ""}'.trim();
      final surname = match.group(2) ?? '';
      return (surname, given);
    }
    // 没有斜杠分隔，整体作为名
    return ('', value.trim());
  }

  /// 解析性别
  Gender _parseGender(String? value) {
    switch (value?.toUpperCase()) {
      case 'M':
        return Gender.male;
      case 'F':
        return Gender.female;
      default:
        return Gender.other;
    }
  }

  /// 性别转 GEDCOM
  String _genderToGedcom(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'M';
      case Gender.female:
        return 'F';
      case Gender.other:
        return 'U';
    }
  }

  /// 从子节点中提取日期
  DateTime? _parseDateChild(_GedcomNode node) {
    for (final child in node.children) {
      if (child.tag == 'DATE') {
        return _parseGedcomDate(child.value);
      }
    }
    return null;
  }

  /// 从子节点中提取地点
  String? _parsePlaceChild(_GedcomNode node) {
    for (final child in node.children) {
      if (child.tag == 'PLAC') {
        return child.value;
      }
    }
    return null;
  }

  /// 解析 GEDCOM 日期（支持 "1 JAN 1900", "JAN 1900", "1900", "ABT 1900" 等）
  DateTime? _parseGedcomDate(String? value) {
    if (value == null || value.isEmpty) return null;

    // 移除修饰词 ABT/EST/CAL/BEF/AFT/BET/AND
    var cleaned = value
        .replaceAll(RegExp(r'^(ABT|EST|CAL|BEF|AFT|BET)\s+', caseSensitive: false), '')
        .trim();

    // 尝试解析 "1 JAN 1900" 格式
    final match = RegExp(r'^(\d{1,2})\s+(\w{3})\s+(\d{4})$').firstMatch(cleaned);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = _monthToInt(match.group(2)!);
      final year = int.parse(match.group(3)!);
      if (month != null) {
        return DateTime(year, month, day);
      }
    }

    // 尝试 "JAN 1900"
    final match2 = RegExp(r'^(\w{3})\s+(\d{4})$').firstMatch(cleaned);
    if (match2 != null) {
      final month = _monthToInt(match2.group(1)!);
      final year = int.parse(match2.group(2)!);
      if (month != null) {
        return DateTime(year, month);
      }
    }

    // 尝试纯年份 "1900"
    final match3 = RegExp(r'^(\d{4})$').firstMatch(cleaned);
    if (match3 != null) {
      return DateTime(int.parse(match3.group(1)!));
    }

    // 尝试 ISO 格式
    return DateTime.tryParse(cleaned);
  }

  /// 月份缩写转数字
  int? _monthToInt(String month) {
    const months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4,
      'MAY': 5, 'JUN': 6, 'JUL': 7, 'AUG': 8,
      'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
    };
    return months[month.toUpperCase()];
  }

  /// 格式化日期为 GEDCOM 格式 "1 JAN 1900"
  String _formatGedcomDate(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// 从 "@I1@" 中提取 xref "I1"
  String? _extractXref(String? value) {
    if (value == null) return null;
    final match = RegExp(r'@([^@]+)@').firstMatch(value);
    return match?.group(1);
  }
}

// ==================== 内部数据结构 ====================

/// GEDCOM 记录（0 级）
class _GedcomRecord {
  _GedcomRecord({
    required this.xref,
    required this.type,
    this.value = '',
    List<_GedcomNode>? children,
  }) : children = children ?? [];

  final String xref;
  final String type;
  final String value;
  final List<_GedcomNode> children;
}

/// GEDCOM 节点（1 级及以下）
class _GedcomNode {
  _GedcomNode({
    required this.tag,
    this.value = '',
    List<_GedcomNode>? children,
  }) : children = children ?? [];

  int level = 0;
  final String tag;
  final String value;
  final List<_GedcomNode> children;
}

/// FAM 记录解析结果
class _FamRecord {
  _FamRecord({
    this.husband,
    this.wife,
    this.children = const [],
    this.marriageDate,
    this.marriagePlace,
    this.marriageNote,
  });

  final String? husband;
  final String? wife;
  final List<String> children;
  final DateTime? marriageDate;
  final String? marriagePlace;
  final String? marriageNote;
}

/// GEDCOM 导入统计
class GedcomImportStats {
  const GedcomImportStats({
    this.individuals = 0,
    this.families = 0,
    this.events = 0,
  });

  final int individuals;
  final int families;
  final int events;

  int get total => individuals + families;

  GedcomImportStats copyWith({
    int? individuals,
    int? families,
    int? events,
  }) {
    return GedcomImportStats(
      individuals: individuals ?? this.individuals,
      families: families ?? this.families,
      events: events ?? this.events,
    );
  }
}

/// GEDCOM 异常
class GedcomException implements Exception {
  GedcomException(this.message);
  final String message;
  @override
  String toString() => message;
}
