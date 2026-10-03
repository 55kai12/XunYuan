/// 记事本式图文编辑器
/// 家族简介 / 人物简介 / 事件描述共用：正文里文字与图片逐段排列，
/// 图片可在光标处就地插入、就地删除，像手机记事本一样所见即所得。
/// 存储格式不变（`[img:文件名]` 标记 + `event_media/` 目录），
/// 因此备份、GEDCOM、旧数据完全兼容。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/event_image_store.dart';
import 'description_images.dart';

/// 编辑器内容块：文本段 或 图片段
class NotepadBlock {
  NotepadBlock.text(String initial)
      : controller = TextEditingController(text: initial),
        focusNode = FocusNode(),
        imageFile = null;

  NotepadBlock.image(String file)
      : controller = null,
        focusNode = null,
        imageFile = file;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? imageFile;

  bool get isImage => imageFile != null;

  /// 释放资源（文本块的控制器与焦点节点）
  void release() {
    controller?.dispose();
    focusNode?.dispose();
  }
}

/// 记事本编辑器的内容控制器
/// 对外以 [text] 输出 `[img:文件名]` 标记文本，与旧格式一致。
class NotepadController extends ChangeNotifier {
  NotepadController([String? initial]) {
    load(initial);
  }

  final List<NotepadBlock> _blocks = [];

  /// 已销毁标记：异步清理完成后不再回调监听者（避免 setState after dispose）
  bool _disposed = false;

  /// 待删除的图片文件名。
  /// 删图只入队、不立刻动磁盘 —— 用户可能删完又点「取消」，
  /// 立刻删文件会把仍被已保存内容引用的图弄丢。
  /// 真正删除发生在 [commitPendingDeletions]（保存成功后）。
  final Set<String> _pendingDeletions = {};

  /// 当前待删除的图片文件名（只读，供测试与调试查看）
  Set<String> get pendingDeletions => Set.unmodifiable(_pendingDeletions);

  /// 当前内容块序列（供编辑器渲染）
  List<NotepadBlock> get blocks => List.unmodifiable(_blocks);

  /// 序列化后的描述文本（保存用）
  String get text => _blocks
      .map((b) => b.isImage ? '[img:${b.imageFile}]' : b.controller!.text)
      .join();

  /// 是否既无文字也无图片
  bool get isEmpty => _blocks.every(
      (b) => b.isImage ? false : b.controller!.text.trim().isEmpty);

  /// 重新载入内容（编辑已有简介时调用）
  void load(String? initial) {
    // 换了一条记录，之前登记的待删文件与本条无关，丢弃登记（不动盘）。
    _pendingDeletions.clear();
    for (final b in _blocks) {
      _detach(b);
      b.release();
    }
    _blocks.clear();

    final segments = EventImageStore.parse(initial);
    if (segments.isEmpty) {
      _attach(NotepadBlock.text(''), 0, notify: false);
    } else {
      for (final s in segments) {
        _attach(
          s.isImage
              ? NotepadBlock.image(s.imageFile!)
              : NotepadBlock.text(s.text!),
          _blocks.length,
          notify: false,
        );
      }
      // 末尾补一个空文本块，方便在图后续写
      if (_blocks.last.isImage) {
        _attach(NotepadBlock.text(''), _blocks.length, notify: false);
      }
    }
    notifyListeners();
  }

  /// 插入图片：复制文件后在光标处落块（无焦点时追加到末尾）
  Future<void> insertImage(String sourcePath) async {
    final marker = await EventImageStore.save(sourcePath);
    if (_disposed) return;
    insertImageBlock(EventImageStore.parse(marker).first.imageFile!);
  }

  /// 以已在 `event_media/` 中的文件名插入图片块（纯逻辑，便于测试）
  void insertImageBlock(String fileName) {
    final host = _focusedTextBlock() ?? _lastTextBlock();
    final imageBlock = NotepadBlock.image(fileName);
    if (host == null) {
      _attach(NotepadBlock.text(''), _blocks.length, notify: false);
      _attach(imageBlock, _blocks.length, notify: false);
      _attach(NotepadBlock.text(''), _blocks.length, notify: false);
    } else {
      final index = _blocks.indexOf(host);
      final text = host.controller!.text;
      final sel = host.controller!.selection;
      final pos = (sel.baseOffset >= 0 && sel.baseOffset <= text.length)
          ? sel.baseOffset
          : text.length;
      host.controller!.text = text.substring(0, pos);
      final rest = NotepadBlock.text(text.substring(pos));
      _blocks.insert(index + 1, imageBlock);
      _attach(rest, index + 2, notify: false);
      // 插入后焦点落到后半段，像记事本一样接着写
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rest.focusNode?.requestFocus();
        rest.controller!.selection = const TextSelection.collapsed(offset: 0);
      });
    }
    notifyListeners();
  }

  /// 删除图片块：移除块并登记待删文件，相邻文本块自动合并。
  ///
  /// 注意这里是**惰性删除**：磁盘文件不在此刻删除，只记入
  /// [_pendingDeletions]，等保存成功后由 [commitPendingDeletions] 落地。
  /// 这样「删图 → 取消」不会损坏仍被保存内容引用的图片。
  Future<void> removeImage(NotepadBlock block) async {
    final index = _blocks.indexOf(block);
    if (index < 0) return;
    final fileName = block.imageFile;
    final prev = index > 0 && !_blocks[index - 1].isImage
        ? _blocks[index - 1]
        : null;
    final next = index + 1 < _blocks.length && !_blocks[index + 1].isImage
        ? _blocks[index + 1]
        : null;

    if (prev != null && next != null) {
      prev.controller!.text =
          prev.controller!.text + next.controller!.text;
      _detach(next);
      _blocks.removeAt(index + 1);
      next.release();
      _blocks.removeAt(index);
      block.release();
    } else {
      _blocks.removeAt(index);
      block.release();
      if (_blocks.isEmpty) {
        _blocks.add(_attach(NotepadBlock.text(''), 0, notify: false));
      }
    }

    // 只登记，不删盘。保存成功后才真正落地。
    if (fileName != null) _pendingDeletions.add(fileName);

    if (_disposed) return;
    notifyListeners();
  }

  /// 保存成功后调用：真正删除已登记移除的图片文件。
  /// 失败静默 —— 多留一个孤儿文件远好于报错打断保存流程。
  Future<void> commitPendingDeletions() async {
    if (_pendingDeletions.isEmpty) return;
    final names = List<String>.from(_pendingDeletions);
    _pendingDeletions.clear();
    for (final name in names) {
      try {
        final f = File(await EventImageStore.filePath(name));
        if (await f.exists()) await f.delete();
      } catch (_) {
        // 文件删除失败不影响已完成的保存
      }
    }
  }

  /// 放弃待删除登记（保存失败 / 用户取消时调用），磁盘文件保持不动。
  void discardPendingDeletions() {
    _pendingDeletions.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final b in _blocks) {
      b.release();
    }
    _blocks.clear();
    super.dispose();
  }

  /// 注册文本块的变更监听
  NotepadBlock _attach(NotepadBlock block, int index, {bool notify = true}) {
    block.controller?.addListener(notifyListeners);
    if (_blocks.length <= index) {
      _blocks.add(block);
    } else {
      _blocks.insert(index, block);
    }
    if (notify) notifyListeners();
    return block;
  }

  void _detach(NotepadBlock block) {
    block.controller?.removeListener(notifyListeners);
  }

  NotepadBlock? _focusedTextBlock() {
    for (final b in _blocks) {
      if (!b.isImage && b.focusNode!.hasFocus) return b;
    }
    return null;
  }

  NotepadBlock? _lastTextBlock() {
    for (final b in _blocks.reversed) {
      if (!b.isImage) return b;
    }
    return null;
  }
}

/// 记事本式图文编辑器（正文 + 底部「插入图片」）
class NotepadEditor extends StatefulWidget {
  const NotepadEditor({
    super.key,
    required this.controller,
    this.hintText,
    this.minHeight = 120,
  });

  final NotepadController controller;

  /// 空内容时的占位提示
  final String? hintText;

  /// 编辑区最小高度
  final double minHeight;

  @override
  State<NotepadEditor> createState() => _NotepadEditorState();
}

class _NotepadEditorState extends State<NotepadEditor> {
  final ImagePicker _picker = ImagePicker();

  /// 选择来源并插入图片
  Future<void> _pickAndInsert() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('从相册选择'.tr),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('拍照'.tr),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (image == null) return;
      await widget.controller.insertImage(image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('插入图片失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final blocks = widget.controller.blocks;
        final firstText = blocks.isEmpty || blocks.first.isImage
            ? null
            : blocks.first.controller!.text;
        final showHint = widget.hintText != null && (firstText ?? '').isEmpty;

        return Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...blocks.map(
                (b) => b.isImage
                    ? DescriptionImage(
                        fileName: b.imageFile!,
                        maxHeight: 200,
                        onRemove: () => widget.controller.removeImage(b),
                      )
                    : TextField(
                        controller: b.controller,
                        focusNode: b.focusNode,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.inkBlack,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: showHint ? widget.hintText : null,
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.inkLightGray,
                          ),
                        ),
                      ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickAndInsert,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: Text('插入图片'.tr),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
