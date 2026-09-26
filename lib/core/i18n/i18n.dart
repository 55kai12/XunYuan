/// 轻量 i18n：`'中文原文'.tr`
/// 以中文原文作词典 key 查英文，缺失时回退原文。
/// 生效语言由 app.dart 在构建时写入 [I18n.useEnglish]（先于子树构建）。
///
/// 插值说明：`'共${n}人'.tr` 在调用时已完成插值求值，无法整串命中词典。
/// 对此 tr() 提供**模板回退**：把词典中含 `${...}`/`$var` 占位的 key 编译为
/// 正则去匹配求值后的字符串，命中后把捕获内容回填进英文译文的占位符。
library;

import 'strings_en.dart';

/// 全局翻译状态
class I18n {
  I18n._();

  /// 是否使用英文（由 app.dart 根据语言设置写入）
  static bool useEnglish = false;

  /// 模板 key → 正则缓存（按 key 长度降序的候选列表）
  static List<MapEntry<String, RegExp>>? _templateCache;

  static List<MapEntry<String, RegExp>> _templates() {
    final cache = _templateCache;
    if (cache != null) return cache;
    // 占位符形如 ${xx.yy} 或 $var（仅匹配简单标识符链，过滤复杂表达式）
    final phPattern = RegExp(r'\$\{[A-Za-z_][A-Za-z0-9_.!]*\}|\$[A-Za-z_][A-Za-z0-9_]*');
    final list = <MapEntry<String, RegExp>>[];
    for (final e in enStrings.entries) {
      final k = e.key;
      if (!k.contains(r'$')) continue;
      final buf = StringBuffer('^');
      var pos = 0;
      var hasPh = false;
      for (final m in phPattern.allMatches(k)) {
        buf.write(RegExp.escape(k.substring(pos, m.start)));
        buf.write('(.+)');
        pos = m.end;
        hasPh = true;
      }
      if (!hasPh) continue;
      buf.write(RegExp.escape(k.substring(pos)));
      buf.write(r'$');
      list.add(MapEntry(k, RegExp(buf.toString())));
    }
    // 长模板优先，减少误匹配
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    _templateCache = list;
    return list;
  }
}

extension Tr on String {
  /// 翻译为当前语言；词典缺失或当前为中文时原样返回
  String get tr {
    if (!I18n.useEnglish) return this;
    final exact = enStrings[this];
    if (exact != null) return exact;

    // 模板回退：匹配含占位符的词典 key，把捕获内容回填英文译文
    for (final entry in I18n._templates()) {
      final m = entry.value.firstMatch(this);
      if (m == null) continue;
      var out = enStrings[entry.key]!;
      // 依次用捕获组替换译文中的占位符
      final phInValue = RegExp(r'\$\{[A-Za-z_][A-Za-z0-9_.!]*\}|\$[A-Za-z_][A-Za-z0-9_]*');
      var i = 1;
      out = out.replaceAllMapped(phInValue, (_) {
        final v = i <= m.groupCount ? m.group(i) : null;
        i++;
        return v ?? '';
      });
      return out;
    }
    return this;
  }
}
