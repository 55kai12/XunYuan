/// 事件配图存取工具
/// 事件描述中以内联标记 `[img:文件名]` 引用图片，
/// 文件统一存放在应用文档目录 `event_media/` 下（不进数据库）。
/// 删除事件 / 成员 / 家族时须调用 [deleteFiles] 清理引用的图片文件。
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 描述片段：纯文本或图片
class DescriptionSegment {
  const DescriptionSegment.text(this.text) : imageFile = null;
  const DescriptionSegment.image(this.imageFile) : text = null;

  final String? text;
  final String? imageFile;

  bool get isImage => imageFile != null;
}

class EventImageStore {
  EventImageStore._();

  /// 内联图片标记：[img:event_1737xxxx.jpg]
  static final RegExp _marker = RegExp(r'\[img:([^\[\]]+)\]');

  /// 是否包含图片标记
  static bool hasImages(String? description) =>
      description != null && _marker.hasMatch(description);

  /// 复制图片到应用目录，返回应插入描述的标记文本
  static Future<String> save(String sourcePath) async {
    final dir = await _ensureDir();
    final fileName =
        'event_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    await File(sourcePath).copy(p.join(dir.path, fileName));
    return '[img:$fileName]';
  }

  /// 标记中文件名对应的完整路径
  static Future<String> filePath(String fileName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'event_media', fileName);
  }

  /// 解析描述为 文本/图片 片段序列（保序）
  static List<DescriptionSegment> parse(String? description) {
    final result = <DescriptionSegment>[];
    if (description == null || description.isEmpty) return result;
    var last = 0;
    for (final m in _marker.allMatches(description)) {
      if (m.start > last) {
        result.add(
            DescriptionSegment.text(description.substring(last, m.start)));
      }
      result.add(DescriptionSegment.image(m.group(1)));
      last = m.end;
    }
    if (last < description.length) {
      result.add(DescriptionSegment.text(description.substring(last)));
    }
    return result;
  }

  /// 去掉图片标记得到纯文本（用于卡片摘要）
  static String strip(String? description) =>
      (description ?? '').replaceAll(_marker, ' ').trim();

  /// 删除描述中引用的所有图片文件（单个失败不阻塞）
  static Future<void> deleteFiles(String? description) async {
    if (description == null || !hasImages(description)) return;
    final dir = await _ensureDir();
    for (final m in _marker.allMatches(description)) {
      try {
        final f = File(p.join(dir.path, m.group(1)!));
        if (await f.exists()) await f.delete();
      } catch (_) {
        // 文件删除失败不影响数据库删除
      }
    }
  }

  static Future<Directory> _ensureDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'event_media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
