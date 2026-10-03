/// 备份服务
/// 负责全量数据的导出与导入恢复
/// v2 起：导出为 zip 包（backup.json + event_media/ + avatars/ + media/），
/// 事件配图与头像随包迁移；v1 的纯 JSON 备份仍可恢复（无媒体文件）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database.dart';

import '../../../core/i18n/i18n.dart';
/// 备份文件版本号，未来格式变更时用于迁移
const int _backupVersion = 2;

/// 备份内 JSON 数据文件名
const String _backupJsonName = 'backup.json';

/// 自动备份文件名前缀
const String autoBackupPrefix = 'xunyuan_auto_';

/// 备份服务
class BackupService {
  /// [docsDir] 测试注入用：指定后所有文件操作基于该目录而非系统文档目录
  BackupService(this._db, {Directory? docsDir}) : _docsDirOverride = docsDir;

  final AppDatabase _db;
  final Directory? _docsDirOverride;

  Future<Directory> _docsDir() async =>
      _docsDirOverride ?? await getApplicationDocumentsDirectory();

  // ==================== 导出 ====================

  /// 导出全量数据为 JSON 字符串
  Future<String> exportToJson() async {
    final families = await _db.select(_db.familyTrees).get();
    final persons = await _db.select(_db.persons).get();
    final relationships = await _db.select(_db.relationships).get();
    final events = await _db.select(_db.events).get();
    final places = await _db.select(_db.places).get();
    final media = await _db.select(_db.mediaTable).get();
    final sources = await _db.select(_db.sources).get();

    final backup = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'families': families.map((e) => e.toJson()).toList(),
      'persons': persons.map((e) => e.toJson()).toList(),
      'relationships': relationships.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'places': places.map((e) => e.toJson()).toList(),
      'media': media.map((e) => e.toJson()).toList(),
      'sources': sources.map((e) => e.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// 导出全量数据并保存到应用文档目录，返回文件路径
  /// v2：zip 包 = backup.json + event_media/ + avatars/ + media/（媒体表引用的文件）
  Future<String> exportToFile({String? customName}) async {
    final json = await exportToJson();
    final docsDir = await _docsDir();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = customName ?? 'xunyuan_backup_$timestamp';
    final file = File(p.join(backupDir.path, '$fileName.zip'));
    // 先写临时文件再原子重命名：避免打包中途崩溃/断电留下半截 zip，
    // 让用户以为备份成功却无法恢复（listBackups 会把它当正常备份列出）。
    final tmpFile = File('${file.path}.tmp');

    final encoder = ZipEncoder();
    final archive = Archive();

    // 1) 数据 JSON
    final jsonBytes = utf8.encode(json);
    archive.addFile(ArchiveFile(_backupJsonName, jsonBytes.length, jsonBytes));

    // 2) 事件配图 + 头像目录整体打包；media 表引用的其他文件按 basename 收进 media/
    final included = <String>{};
    for (final sub in const ['event_media', 'avatars']) {
      final dir = Directory(p.join(docsDir.path, sub));
      if (!await dir.exists()) continue;
      await for (final f in dir.list(recursive: true)) {
        if (f is! File) continue;
        final rel = p.relative(f.path, from: docsDir.path);
        final bytes = await f.readAsBytes();
        archive.addFile(
            ArchiveFile(rel.replaceAll('\\', '/'), bytes.length, bytes));
        included.add(p.basename(f.path));
      }
    }
    final mediaRows = await _db.select(_db.mediaTable).get();
    for (final m in mediaRows) {
      if (m.path.isEmpty) continue;
      final base = p.basename(m.path);
      if (included.contains(base)) continue;
      final f = File(m.path);
      if (!await f.exists()) continue;
      final bytes = await f.readAsBytes();
      archive.addFile(
          ArchiveFile('media/$base', bytes.length, bytes));
      included.add(base);
    }

    await tmpFile.writeAsBytes(encoder.encode(archive)!, flush: true);
    // 原子落地：先删掉同名旧文件（Windows 上 rename 目标已存在会报错）
    if (await file.exists()) {
      await file.delete();
    }
    await tmpFile.rename(file.path);
    return file.path;
  }

  /// 列出本地所有备份文件（v2 zip 与 v1 json 均支持）
  Future<List<File>> listBackups() async {
    final docsDir = await _docsDir();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!await backupDir.exists()) return [];
    // 顺手清掉历史遗留的半截临时文件（打包中途被杀会留下 .tmp）
    for (final f in backupDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.tmp')) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.zip') || f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  // ==================== 导入恢复 ====================

  /// 从 JSON 字符串恢复数据
  /// [merge] 为 true 时保留现有数据并追加；为 false 时清空后恢复
  /// 返回恢复的记录统计
  Future<BackupRestoreStats> importFromJson(
    String jsonString, {
    bool merge = false,
  }) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    // 版本校验
    final version = data['version'] as int?;
    if (version == null || version > _backupVersion) {
      throw BackupException('备份文件版本过高，无法识别'.tr);
    }

    final familiesJson = (data['families'] as List?) ?? [];
    final personsJson = (data['persons'] as List?) ?? [];
    final relationshipsJson = (data['relationships'] as List?) ?? [];
    final eventsJson = (data['events'] as List?) ?? [];
    final placesJson = (data['places'] as List?) ?? [];
    final mediaJson = (data['media'] as List?) ?? [];
    final sourcesJson = (data['sources'] as List?) ?? [];

    var stats = const BackupRestoreStats();

    await _db.transaction(() async {
      // merge 模式下的 ID 重映射表：备份中的旧 ID → 现库中的新 ID
      final treeIdMap = <int, int>{};
      final personIdMap = <int, int>{};
      final mediaIdMap = <int, int>{};
      // 待回填引用（merge 模式）：新 personId → 旧 avatarMediaId / 新 familyId → 旧 coverMediaId
      final pendingAvatar = <int, int>{};
      final pendingCover = <int, int>{};

      if (!merge) {
        // 清空模式下：现有媒体记录即将删除，先把磁盘文件一并清掉
        final oldMedia = await _db.select(_db.mediaTable).get();
        for (final m in oldMedia) {
          try {
            final f = File(m.path);
            if (await f.exists()) await f.delete();
          } catch (_) {
            // 文件删除失败不阻塞恢复
          }
        }
        // 清空所有表。删除顺序必须满足两条：
        //  ① 引用了 `media` 的表（persons.avatarMediaId 有外键）要先于 media 删除，
        //     否则删 media 时撞 FK 787；
        //  ② 引用了 persons / familyTrees 的表（events / relationships / sources）
        //     要先于 persons / familyTrees 删除。
        // 合成一条满足两者的顺序：sources → events → relationships → persons
        //   → familyTrees → media → places。
        await _db.delete(_db.sources).go();
        await _db.delete(_db.events).go();
        await _db.delete(_db.relationships).go();
        await _db.delete(_db.persons).go();
        await _db.delete(_db.familyTrees).go();
        await _db.delete(_db.mediaTable).go();
        await _db.delete(_db.places).go();
      }

      // 按依赖顺序恢复：地点 → 家族 → 成员 → 关系/事件/媒体/资料
      for (final row in placesJson) {
        await _db.into(_db.places).insert(
              PlacesCompanion.insert(
                name: row['name'] as String? ?? '',
                address: Value(row['address'] as String?),
                latitude: Value((row['latitude'] as num?)?.toDouble()),
                longitude: Value((row['longitude'] as num?)?.toDouble()),
              ),
            );
        stats = stats.copyWith(places: stats.places + 1);
      }

      // 家族：merge 时重新分配 ID，非 merge（已清空）保留原 ID
      for (final row in familiesJson) {
        final newId = await _db.into(_db.familyTrees).insert(
              FamilyTreesCompanion.insert(
                id: merge ? const Value.absent() : Value(row['id'] as int),
                name: row['name'] as String,
                surname: row['surname'] as String? ?? '',
                hallName: Value(row['hallName'] as String?),
                origin: Value(row['origin'] as String?),
                generationWords: Value(row['generationWords'] as String?),
                description: Value(row['description'] as String?),
                // 封面引用同理：先留空，等媒体表插完再回填。
                coverMediaId: const Value.absent(),
                createdAt: _parseDate(row['createdAt']) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt']) ?? DateTime.now(),
              ),
              mode: merge ? InsertMode.insert : InsertMode.insertOrReplace,
            );
        treeIdMap[row['id'] as int] = newId;
        final cover = row['coverMediaId'] as int?;
        if (cover != null) pendingCover[newId] = cover;
        stats = stats.copyWith(families: stats.families + 1);
      }

      // 成员
      for (final row in personsJson) {
        final newTreeId = merge ? treeIdMap[row['treeId'] as int] : row['treeId'] as int;
        if (newTreeId == null) continue; // 所属家族缺失，跳过该成员
        final oldAvatar = row['avatarMediaId'] as int?;
        final newId = await _db.into(_db.persons).insert(
              PersonsCompanion.insert(
                id: merge ? const Value.absent() : Value(row['id'] as int),
                treeId: newTreeId,
                surname: row['surname'] as String? ?? '',
                givenName: row['givenName'] as String? ?? '',
                courtesyName: Value(row['courtesyName'] as String?),
                artName: Value(row['artName'] as String?),
                gender: Gender.values[row['gender'] as int? ?? 0],
                generation: Value(row['generation'] as int?),
                generationWord: Value(row['generationWord'] as String?),
                branch: Value(row['branch'] as String?),
                rank: Value(row['rank'] as int?),
                birthDate: Value(_parseDate(row['birthDate'])),
                deathDate: Value(_parseDate(row['deathDate'])),
                isAlive: Value((row['isAlive'] as bool?) ?? true),
                birthPlace: Value(row['birthPlace'] as String?),
                deathPlace: Value(row['deathPlace'] as String?),
                burialPlace: Value(row['burialPlace'] as String?),
                occupation: Value(row['occupation'] as String?),
                title: Value(row['title'] as String?),
                biography: Value(row['biography'] as String?),
                // 头像引用一律先留空，等媒体表插完再回填。
                // 媒体表在成员表之后插入，这里直接写旧 ID 会撞外键约束
                // （清空模式下媒体记录已被删光；merge 模式下 ID 已重映射）。
                avatarMediaId: const Value.absent(),
              ),
              mode: merge ? InsertMode.insert : InsertMode.insertOrReplace,
            );
        personIdMap[row['id'] as int] = newId;
        if (oldAvatar != null) pendingAvatar[newId] = oldAvatar;
        stats = stats.copyWith(persons: stats.persons + 1);
      }

      // 关系
      for (final row in relationshipsJson) {
        final newTreeId = merge ? treeIdMap[row['treeId'] as int] : row['treeId'] as int;
        final newFrom = merge
            ? personIdMap[row['fromPersonId'] as int]
            : row['fromPersonId'] as int;
        final newTo = merge
            ? personIdMap[row['toPersonId'] as int]
            : row['toPersonId'] as int;
        if (newTreeId == null || newFrom == null || newTo == null) continue;
        await _db.into(_db.relationships).insert(
              RelationshipsCompanion.insert(
                id: merge ? const Value.absent() : Value(row['id'] as int),
                treeId: newTreeId,
                fromPersonId: newFrom,
                toPersonId: newTo,
                type: _parseTextEnum(
                    row['type'], RelationType.values, RelationType.father),
                startDate: Value(_parseDate(row['startDate'])),
                endDate: Value(_parseDate(row['endDate'])),
                note: Value(row['note'] as String?),
              ),
              mode: merge ? InsertMode.insert : InsertMode.insertOrReplace,
            );
        stats = stats.copyWith(relationships: stats.relationships + 1);
      }

      // 事件
      for (final row in eventsJson) {
        final newTreeId = merge ? treeIdMap[row['treeId'] as int] : row['treeId'] as int;
        if (newTreeId == null) continue;
        final oldPersonId = row['personId'] as int?;
        final newPersonId = merge
            ? (oldPersonId == null ? null : personIdMap[oldPersonId])
            : oldPersonId;
        if (merge && oldPersonId != null && newPersonId == null) {
          continue; // 关联成员缺失，跳过该事件
        }
        await _db.into(_db.events).insert(
              EventsCompanion.insert(
                id: merge ? const Value.absent() : Value(row['id'] as int),
                treeId: newTreeId,
                personId: Value(newPersonId),
                type: _parseTextEnum(
                    row['type'], EventType.values, EventType.other),
                title: row['title'] as String? ?? '',
                date: Value(_parseDate(row['date'])),
                place: Value(row['place'] as String?),
                description: Value(row['description'] as String?),
              ),
              mode: merge ? InsertMode.insert : InsertMode.insertOrReplace,
            );
        stats = stats.copyWith(events: stats.events + 1);
      }

      // 媒体
      for (final row in mediaJson) {
        final oldTreeId = row['treeId'] as int?;
        final oldPersonId = row['personId'] as int?;
        final newTreeId = merge
            ? (oldTreeId == null ? null : treeIdMap[oldTreeId])
            : oldTreeId;
        final newPersonId = merge
            ? (oldPersonId == null ? null : personIdMap[oldPersonId])
            : oldPersonId;
        if (merge &&
            ((oldTreeId != null && newTreeId == null) ||
                (oldPersonId != null && newPersonId == null))) {
          continue; // 引用悬空的媒体记录直接丢弃
        }
        final newId = await _db.into(_db.mediaTable).insert(
              MediaTableCompanion.insert(
                id: merge ? const Value.absent() : Value(row['id'] as int),
                treeId: Value(newTreeId),
                personId: Value(newPersonId),
                type: _parseTextEnum(
                    row['type'], MediaKind.values, MediaKind.image),
                path: row['path'] as String? ?? '',
                caption: Value(row['caption'] as String?),
                createdAt: _parseDate(row['createdAt']) ?? DateTime.now(),
              ),
              mode: merge ? InsertMode.insert : InsertMode.insertOrReplace,
            );
        // 两种模式都要记录映射：清空模式保留原 ID（映射为恒等），
        // merge 模式是新分配 ID。回填头像/封面时统一走这张表。
        mediaIdMap[row['id'] as int] = newId;
        stats = stats.copyWith(media: stats.media + 1);      }

      // 回填头像 / 封面引用（此时媒体表已插完，外键可满足）
      for (final entry in pendingAvatar.entries) {
        final newMediaId = mediaIdMap[entry.value];
        if (newMediaId == null) continue;
        await (_db.update(_db.persons)
              ..where((tbl) => tbl.id.equals(entry.key)))
            .write(PersonsCompanion(avatarMediaId: Value(newMediaId)));
      }
      for (final entry in pendingCover.entries) {
        final newMediaId = mediaIdMap[entry.value];
        if (newMediaId == null) continue;
        await (_db.update(_db.familyTrees)
              ..where((tbl) => tbl.id.equals(entry.key)))
            .write(FamilyTreesCompanion(coverMediaId: Value(newMediaId)));
      }

      // 资料
      for (final row in sourcesJson) {
        final newTreeId = merge ? treeIdMap[row['treeId'] as int] : row['treeId'] as int;
        if (newTreeId == null) continue;
        await _db.into(_db.sources).insert(
              SourcesCompanion.insert(
                id: merge ? const Value.absent() : Value(row['id'] as int),
                treeId: newTreeId,
                title: row['title'] as String? ?? '',
                url: Value(row['url'] as String?),
                note: Value(row['note'] as String?),
              ),
              mode: merge ? InsertMode.insert : InsertMode.insertOrReplace,
            );
        stats = stats.copyWith(sources: stats.sources + 1);
      }
    });

    return stats;
  }

  /// 从文件恢复
  /// v2 zip：解出 backup.json 走标准恢复，再回写 event_media/avatars/media 文件
  /// v1 json：直接恢复（无媒体文件，与旧版行为一致）
  Future<BackupRestoreStats> importFromFile(String filePath,
      {bool merge = false}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw BackupException('备份文件不存在'.tr);
    }

    if (filePath.endsWith('.zip')) {
      return _importFromZip(file, merge: merge);
    }
    final jsonString = await file.readAsString(encoding: utf8);
    return importFromJson(jsonString, merge: merge);
  }

  /// 从 zip 备份包恢复
  Future<BackupRestoreStats> _importFromZip(File zipFile,
      {bool merge = false}) async {
    final docsDir = await _docsDir();

    // 解包到临时目录
    final tmpDir =
        await Directory.systemTemp.createTemp('xunyuan_restore_');
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      String? jsonString;
      final extracted = <String, File>{}; // 包内相对路径 → 解出文件

      for (final f in archive) {
        if (f.isFile) {
          final out = File(p.join(tmpDir.path, f.name));
          await out.create(recursive: true);
          await out.writeAsBytes(f.content as List<int>);
          if (f.name == _backupJsonName) {
            jsonString = await out.readAsString(encoding: utf8);
          } else {
            extracted[f.name] = out;
          }
        }
      }
      if (jsonString == null) {
        throw BackupException('备份文件缺少数据文件，可能已损坏'.tr);
      }

      final stats = await importFromJson(jsonString, merge: merge);

      // 回写媒体文件：media/ 按名字放回并改写记录路径；event_media/、avatars/ 原位放回
      final restored = <String, String>{}; // basename → 新绝对路径
      for (final entry in extracted.entries) {
        if (entry.key.startsWith('media/')) {
          final destDir = Directory(p.join(docsDir.path, 'media'));
          if (!await destDir.exists()) await destDir.create(recursive: true);
          final base = p.basename(entry.key);
          final dest = File(p.join(destDir.path, base));
          await entry.value.copy(dest.path);
          restored[base] = dest.path;
        } else {
          // event_media/xxx、avatars/xxx 原样放回
          final rel = entry.key.replaceAll('/', p.separator);
          final dest = File(p.join(docsDir.path, rel));
          await dest.parent.create(recursive: true);
          await entry.value.copy(dest.path);
          restored[p.basename(entry.key)] = dest.path;
        }
      }

      // 改写媒体表里指向旧设备路径的记录（按 basename 匹配）
      if (restored.isNotEmpty) {
        final rows = await _db.select(_db.mediaTable).get();
        for (final row in rows) {
          if (row.path.isEmpty) continue;
          final base = p.basename(row.path);
          final newPath = restored[base];
          if (newPath == null || newPath == row.path) continue;
          if (await File(row.path).exists()) continue; // 本机文件还在就不动
          await (_db.update(_db.mediaTable)
                ..where((tbl) => tbl.id.equals(row.id)))
              .write(MediaTableCompanion(path: Value(newPath)));
        }
      }
      return stats;
    } finally {
      try {
        await tmpDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  // ==================== 数据清理 ====================

  /// 清空所有数据（不可恢复，需二次确认）
  Future<void> clearAllData() async {
    await _db.transaction(() async {
      // 媒体记录清空前先把磁盘文件删掉
      final oldMedia = await _db.select(_db.mediaTable).get();
      for (final m in oldMedia) {
        try {
          final f = File(m.path);
          if (await f.exists()) await f.delete();
        } catch (_) {
          // 忽略文件删除失败
        }
      }
      await _db.delete(_db.sources).go();
      await _db.delete(_db.mediaTable).go();
      await _db.delete(_db.events).go();
      await _db.delete(_db.relationships).go();
      await _db.delete(_db.persons).go();
      await _db.delete(_db.places).go();
      await _db.delete(_db.familyTrees).go();
    });
  }

  /// 删除备份文件
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ==================== 自动备份 ====================

  /// 执行一次自动备份并清理旧的自动备份（只保留最近 [keep] 份）
  /// 失败静默返回 null，不打扰用户
  Future<String?> runAutoBackup({int keep = 5}) async {
    try {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final path = await exportToFile(
          customName: '$autoBackupPrefix$timestamp');
      // 清理超出保留数的旧自动备份（手动备份不受影响）
      // 注：这里是「先删备份文件再退栈」的循环，listBackups 已按时间倒序，
      // 必须先删完再插入新记录，否则 autos 里刚写入的新备份会成为第 0 项。
      final autos = (await listBackups())
          .where((f) => p.basename(f.path).startsWith(autoBackupPrefix))
          .toList();
      autos.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      for (var i = keep; i < autos.length; i++) {
        try {
          await autos[i].delete();
        } catch (_) {}
      }
      return path;
    } catch (_) {
      return null;
    }
  }

  // ==================== 工具 ====================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  /// 解析 textEnum 列的 JSON 值（存储为枚举名字符串）
  T _parseTextEnum<T extends Enum>(
      dynamic value, List<T> values, T defaultValue) {
    if (value is String) {
      return values.firstWhere(
        (e) => e.name == value,
        orElse: () => defaultValue,
      );
    }
    if (value is int) {
      return values[value.clamp(0, values.length - 1)];
    }
    return defaultValue;
  }
}

/// 备份异常
class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 恢复统计
class BackupRestoreStats {
  const BackupRestoreStats({
    this.families = 0,
    this.persons = 0,
    this.relationships = 0,
    this.events = 0,
    this.places = 0,
    this.media = 0,
    this.sources = 0,
  });

  final int families;
  final int persons;
  final int relationships;
  final int events;
  final int places;
  final int media;
  final int sources;

  int get total =>
      families + persons + relationships + events + places + media + sources;

  BackupRestoreStats copyWith({
    int? families,
    int? persons,
    int? relationships,
    int? events,
    int? places,
    int? media,
    int? sources,
  }) {
    return BackupRestoreStats(
      families: families ?? this.families,
      persons: persons ?? this.persons,
      relationships: relationships ?? this.relationships,
      events: events ?? this.events,
      places: places ?? this.places,
      media: media ?? this.media,
      sources: sources ?? this.sources,
    );
  }
}
