/// 描述配图共享组件（展示端）
/// 家族简介 / 人物简介 / 事件描述共用同一套内联图片机制：
/// 文本中以 `[img:文件名]` 标记引用，文件统一存于应用文档目录 `event_media/`。
/// 备份恢复时随 `event_media/` 整体打包，无需额外处理。
/// 编辑端见 [NotepadEditor]（记事本式图文编辑器）。
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_image_store.dart';

/// 展示端：把含 [img:] 标记的描述渲染为 文本/图片 混排（图片点击全屏查看）
class DescriptionRichText extends StatelessWidget {
  const DescriptionRichText({
    super.key,
    required this.text,
    this.style,
    this.imageMaxHeight = 220,
  });

  final String text;
  final TextStyle? style;
  final double imageMaxHeight;

  @override
  Widget build(BuildContext context) {
    final segments = EventImageStore.parse(text);
    if (segments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((s) {
        if (s.isImage) {
          return DescriptionImage(
            fileName: s.imageFile!,
            maxHeight: imageMaxHeight,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(s.text!, style: style),
        );
      }).toList(),
    );
  }
}

/// 描述中的内联配图（点击全屏查看；[onRemove] 非空时右上角显示删除角标）
class DescriptionImage extends StatelessWidget {
  const DescriptionImage({
    super.key,
    required this.fileName,
    this.maxHeight = 220,
    this.onRemove,
  });

  final String fileName;
  final double maxHeight;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: EventImageStore.filePath(fileName),
      builder: (context, snapshot) {
        final path = snapshot.data;
        final file = path != null ? File(path) : null;
        final exists = file != null && file.existsSync();
        if (!exists) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined,
                      size: 18, color: AppColors.inkGray),
                  const SizedBox(width: 6),
                  Text('图片已丢失'.tr,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkGray)),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullScreen(context, file),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: Image.file(file,
                        fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreen(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.file(file),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
