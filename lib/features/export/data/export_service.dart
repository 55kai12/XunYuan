/// 导出服务
/// 负责生成 PDF 文档（家族信息 + 成员名册）和保存导出文件
/// PNG 导出通过 Widget 层的 RepaintBoundary 截图实现
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/database.dart';
import '../../../core/utils/event_image_store.dart';

import '../../../core/i18n/i18n.dart';
/// 导出服务
class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  /// 中文字体缓存（pdf 包默认 Helvetica 不含中文字形，必须显式加载）
  pw.Font? _cjkFont;

  /// 加载霞鹜文楷字体用于 PDF 导出（带缓存，避免重复读取）
  Future<pw.Font> _loadCjkFont() async {
    return _cjkFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/LXGWWenKai.ttf'),
    );
  }

  // ==================== PDF 导出 ====================

  /// 生成家族 PDF 文档，返回文件路径
  /// 包含：家族封面、基本信息、成员名册、关系概览
  Future<String> exportFamilyPdf(int treeId) async {
    // 先加载中文字体，所有文本样式统一使用
    final font = await _loadCjkFont();

    final family = await (_db.select(_db.familyTrees)
          ..where((tbl) => tbl.id.equals(treeId)))
        .getSingleOrNull();
    if (family == null) {
      throw ExportException('家族不存在'.tr);
    }

    final persons = await (_db.select(_db.persons)
          ..where((tbl) => tbl.treeId.equals(treeId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.generation),
            (tbl) => OrderingTerm.asc(tbl.rank),
          ]))
        .get();

    final relationships = await (_db.select(_db.relationships)
          ..where((tbl) => tbl.treeId.equals(treeId)))
        .get();

    final doc = pw.Document();

    // ===== 封面页 =====
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 120,
                height: 120,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 3),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    family.surname.isNotEmpty
                        ? family.surname.substring(0, 1)
                        : '族'.tr,
                    style: pw.TextStyle(
                      fontSize: 64,
                      fontWeight: pw.FontWeight.bold,
                      font: font,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Text(
                family.name,
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 12),
              if (family.hallName != null)
                pw.Text('堂号：${family.hallName}'.tr,
                    style: pw.TextStyle(fontSize: 16, font: font)),
              if (family.origin != null)
                pw.Text('郡望：${family.origin}'.tr,
                    style: pw.TextStyle(fontSize: 16, font: font)),
              pw.SizedBox(height: 48),
              pw.Text(
                '族谱名册'.tr,
                style: pw.TextStyle(
                  fontSize: 20,
                  color: PdfColors.grey700,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                '共 ${persons.length} 位族人'.tr,
                style: pw.TextStyle(fontSize: 14, font: font),
              ),
              pw.SizedBox(height: 80),
              pw.Text(
                '寻渊 · 族谱'.tr,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey500,
                  font: font,
                ),
              ),
              pw.Text(
                '导出时间：${_formatDate(DateTime.now())}'.tr,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey400,
                  font: font,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // ===== 家族信息页 =====
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('家族信息'.tr,
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    font: font)),
            pw.SizedBox(height: 16),
            _infoRow('家族名称'.tr, family.name),
            _infoRow('姓氏'.tr, family.surname),
            if (family.hallName != null)
              _infoRow('堂号'.tr, family.hallName!),
            if (family.origin != null)
              _infoRow('郡望'.tr, family.origin!),
            if (family.generationWords != null)
              _infoRow('字辈'.tr, family.generationWords!),
            if (family.description != null) ...[
              pw.SizedBox(height: 12),
              pw.Text('简介'.tr,
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      font: font)),
              pw.SizedBox(height: 6),
              pw.Text(EventImageStore.strip(family.description!),
                  style: pw.TextStyle(fontSize: 12, font: font)),
            ],
            pw.SizedBox(height: 24),
            pw.Text('统计概览'.tr,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: font)),
            pw.SizedBox(height: 12),
            _infoRow('族人总数'.tr, '${persons.length}'),
            _infoRow('在世人数'.tr,
                '${persons.where((p) => p.isAlive).length}'),
            _infoRow('已故人数'.tr,
                '${persons.where((p) => !p.isAlive).length}'),
            _infoRow('男性'.tr,
                '${persons.where((p) => p.gender == Gender.male).length}'),
            _infoRow('女性'.tr,
                '${persons.where((p) => p.gender == Gender.female).length}'),
            _infoRow('关系记录'.tr, '${relationships.length}'),
          ],
        ),
      ),
    );

    // ===== 成员名册页 =====
    // 按世代分组
    final byGeneration = <int?, List<Person>>{};
    for (final p in persons) {
      byGeneration.putIfAbsent(p.generation, () => []).add(p);
    }
    final generations = byGeneration.keys.toList()
      ..sort((a, b) => (a ?? 0).compareTo(b ?? 0));

    for (final gen in generations) {
      final genPersons = byGeneration[gen]!;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                gen != null ? '第 $gen 世'.tr : '未分世代'.tr,
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    font: font),
              ),
              pw.SizedBox(height: 4),
              pw.Text('共 ${genPersons.length} 人'.tr,
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                      font: font)),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableHeader('姓名'.tr),
                      _tableHeader('字/号'.tr),
                      _tableHeader('性别'.tr),
                      _tableHeader('字辈'.tr),
                      _tableHeader('房支'.tr),
                      _tableHeader('生卒'.tr),
                    ],
                  ),
                  ...genPersons.map((p) => pw.TableRow(
                        children: [
                          _tableCell(
                              '${p.surname}${p.givenName}'),
                          _tableCell([
                            if (p.courtesyName != null) p.courtesyName!,
                            if (p.artName != null) '号${p.artName}'.tr,
                          ].join(' ')),
                          _tableCell(_genderLabel(p.gender)),
                          _tableCell(p.generationWord ?? ''),
                          _tableCell(p.branch ?? ''),
                          _tableCell(_lifeSpan(p)),
                        ],
                      )),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 保存文件
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName =
        '${family.surname}氏族谱_$timestamp.pdf'.tr;
    final file = File(p.join(exportDir.path, fileName));
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  // ==================== PNG 保存 ====================

  /// 将 PNG 字节数据保存为文件，返回路径
  Future<String> savePng(Uint8List bytes, {String? prefix}) async {
    prefix ??= '族谱树'.tr;
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = '${prefix}_$timestamp.png';
    final file = File(p.join(exportDir.path, fileName));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// 导出族谱树图片为 PDF
  /// 将族谱树 PNG 嵌入 PDF，包含标题和家族信息
  Future<String> exportFamilyTreePdf({
    required Uint8List treeImage,
    required String familyName,
    String? rootPersonName,
    int? memberCount,
  }) async {
    // 先加载中文字体，所有文本样式统一使用
    final font = await _loadCjkFont();

    final pdf = pw.Document();

    // 解析图片尺寸以计算比例
    final image = pw.MemoryImage(treeImage);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 标题
              pw.Text(
                '$familyName 族谱树'.tr,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 4),
              // 副标题信息
              pw.Text(
                [
                  if (rootPersonName != null) '以 $rootPersonName 为中心'.tr,
                  if (memberCount != null) '共 $memberCount 位成员'.tr,
                  '导出时间：${_formatDate(DateTime.now())}'.tr,
                ].join('  ·  '),
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600, font: font),
              ),
              pw.SizedBox(height: 16),
              // 分隔线
              pw.Container(
                height: 1,
                color: PdfColors.grey300,
              ),
              pw.SizedBox(height: 16),
              // 族谱树图片（按页面宽度缩放）
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(
                    image,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              // 页脚
              pw.Center(
                child:                 pw.Text(
                  '寻渊 · 寻根问祖，渊远流长'.tr,
                  style: pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey400, font: font),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 保存 PDF
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = '$familyName族谱树_$timestamp.pdf'.tr;
    final file = File(p.join(exportDir.path, fileName));
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // ==================== 工具方法 ====================

  /// 当前可用的中文字体（未加载时回退 Helvetica，导出方法开头都会先加载）
  pw.Font get _font => _cjkFont ?? pw.Font.helvetica();

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    font: _font)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(fontSize: 12, font: _font)),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              font: _font)),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 9, font: _font)),
    );
  }

  String _genderLabel(Gender g) {
    switch (g) {
      case Gender.male:
        return '男'.tr;
      case Gender.female:
        return '女'.tr;
      case Gender.other:
        return '其他'.tr;
    }
  }

  String _lifeSpan(Person p) {
    final parts = <String>[];
    if (p.birthDate != null) parts.add('${p.birthDate!.year}');
    if (!p.isAlive && p.deathDate != null) {
      parts.add('${p.deathDate!.year}');
    }
    if (parts.isEmpty) return '—';
    return parts.join('—');
  }

  String _formatDate(DateTime d) {
    return '${d.year}年${d.month}月${d.day}日'.tr;
  }
}

/// 导出异常
class ExportException implements Exception {
  ExportException(this.message);
  final String message;
  @override
  String toString() => message;
}
