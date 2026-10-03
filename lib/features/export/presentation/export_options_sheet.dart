/// 导出选项面板与共用分享逻辑
/// 族谱树页的「导出」按钮与导出中心共用本文件
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/i18n.dart';

/// 导出格式
enum ExportFormat { png, pdf, both }

/// 一次导出的选项
class ExportOptions {
  const ExportOptions({required this.format, required this.scale});

  /// 输出格式：仅 PNG / 仅 PDF / 两者
  final ExportFormat format;

  /// 位图清晰度倍率（PNG 与嵌入 PDF 的位图都用它）
  final double scale;
}

/// 弹出导出选项面板；用户取消时返回 null
Future<ExportOptions?> showExportOptionsSheet(BuildContext context) {
  var format = ExportFormat.png;
  var scale = 3.0;

  return showModalBottomSheet<ExportOptions>(
    context: context,
    showDragHandle: true,
    // 允许面板按内容取高，避免小屏/大字体下被 9/16 高度限制挤溢出
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('导出选项'.tr,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _label('格式'.tr),
              const SizedBox(height: 8),
              SegmentedButton<ExportFormat>(
                segments: [
                  ButtonSegment(
                      value: ExportFormat.png,
                      label: Text('PNG'.tr),
                      icon: const Icon(Icons.image_outlined, size: 18)),
                  ButtonSegment(
                      value: ExportFormat.pdf,
                      label: Text('PDF'.tr),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18)),
                  ButtonSegment(
                      value: ExportFormat.both,
                      label: Text('两者'.tr),
                      icon: const Icon(Icons.done_all, size: 18)),
                ],
                selected: {format},
                onSelectionChanged: (s) => setSheet(() => format = s.first),
              ),
              const SizedBox(height: 16),
              _label('清晰度'.tr),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                segments: [
                  ButtonSegment(value: 2.0, label: Text('标准'.tr)),
                  ButtonSegment(value: 3.0, label: Text('高清'.tr)),
                  ButtonSegment(value: 4.0, label: Text('超清'.tr)),
                ],
                selected: {scale},
                onSelectionChanged: (s) => setSheet(() => scale = s.first),
              ),
              const SizedBox(height: 10),
              Text(
                '导出内容与当前视图一致（跟随「只看直系」开关）。'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('取消'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                          context,
                          ExportOptions(format: format, scale: scale)),
                      child: Text('导出'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));

/// 文件保存后询问是否分享；返回 true 表示用户点了分享
/// [question] 与 [shareText] 均由调用方传入已本地化的文案；[paths] 可含多个文件
Future<bool> askShare(
  BuildContext context, {
  required List<String> paths,
  required String question,
  required String shareText,
}) async {
  final share = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('导出成功'.tr),
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('仅保存'.tr),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('分享'.tr),
        ),
      ],
    ),
  );
  if (share == true && paths.isNotEmpty) {
    await Share.shareXFiles(paths.map(XFile.new).toList(), text: shareText);
  }
  return share ?? false;
}

/// 保存成功提示条（[message] 为已本地化的完整文案）
void showSavedSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

