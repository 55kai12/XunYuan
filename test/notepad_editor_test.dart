/// 记事本式图文编辑器内容模型测试
/// 覆盖：装载/序列化往返、光标处插图、删除插图后的文本块合并。
/// 存储格式必须与旧版 `[img:文件名]` 标记完全一致（备份/GEDCOM 兼容）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familytree/shared/widgets/notepad_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotepadController 装载与序列化', () {
    test('空内容只有一个空文本块', () {
      final c = NotepadController();
      expect(c.blocks.length, 1);
      expect(c.blocks.first.isImage, isFalse);
      expect(c.text, '');
      expect(c.isEmpty, isTrue);
      c.dispose();
    });

    test('图文内容解析为 文本/图片 交替块并原样序列化回来', () {
      final c = NotepadController('先人[img:a.jpg]迁居佛山');
      expect(c.blocks.length, 3);
      expect(c.blocks[0].isImage, isFalse);
      expect(c.blocks[1].isImage, isTrue);
      expect(c.blocks[1].imageFile, 'a.jpg');
      expect(c.text, '先人[img:a.jpg]迁居佛山');
      expect(c.isEmpty, isFalse);
      c.dispose();
    });

    test('以图片结尾时自动补一个空文本块供继续输入', () {
      final c = NotepadController('祖祠[img:b.png]');
      expect(c.blocks.length, 3);
      expect(c.blocks.last.isImage, isFalse);
      expect(c.text, '祖祠[img:b.png]');
      c.dispose();
    });

    test('只有图片时不为空', () {
      final c = NotepadController('[img:c.jpg]');
      expect(c.text, '[img:c.jpg]');
      expect(c.isEmpty, isFalse);
      c.dispose();
    });

    test('重新载入会替换全部内容', () {
      final c = NotepadController('旧内容[img:old.jpg]');
      c.load('新内容');
      expect(c.blocks.length, 1);
      expect(c.text, '新内容');
      c.dispose();
    });
  });

  group('插入图片块', () {
    test('无焦点时追加到末尾并保留原文字', () {
      final c = NotepadController('族谱记载');
      c.insertImageBlock('d.jpg');
      expect(c.text, '族谱记载[img:d.jpg]');
      c.dispose();
    });

    test('光标在中间时按光标切分文本', () {
      final c = NotepadController('前半后半');
      final block = c.blocks.first;
      block.controller!.selection =
          const TextSelection.collapsed(offset: 2);
      block.focusNode!.requestFocus();
      c.insertImageBlock('e.jpg');
      expect(c.text, '前半[img:e.jpg]后半');
      c.dispose();
    });
  });

  group('删除图片块', () {
    test('删除后前后文本块合并', () async {
      final c = NotepadController('前[img:f.jpg]后');
      final imageBlock = c.blocks[1];
      await c.removeImage(imageBlock);
      expect(c.blocks.length, 1);
      expect(c.text, '前后');
      c.dispose();
    });

    test('删除后编辑区不会变成零块', () async {
      final c = NotepadController('[img:g.jpg]');
      // 末块为空文本、首块为图片
      await c.removeImage(c.blocks.first);
      expect(c.blocks, isNotEmpty);
      expect(c.blocks.first.isImage, isFalse);
      c.dispose();
    });

    test('异步清理期间控制器已销毁也不会崩', () async {
      final c = NotepadController('前[img:h.jpg]后');
      final pending = c.removeImage(c.blocks[1]);
      c.dispose();
      await pending; // 不应抛 setState after dispose
    });
  });

  // 回归：删图曾经立刻删磁盘文件，用户删完点「取消」会弄丢
  // 仍被已保存内容引用的图片。现在删图只登记，保存成功后才落地。
  group('图片惰性删除', () {
    test('删除图片块只登记待删，不立即动盘', () async {
      final c = NotepadController('前[img:keep.jpg]后');
      await c.removeImage(c.blocks[1]);
      expect(c.pendingDeletions, contains('keep.jpg'));
      c.dispose();
    });

    test('放弃登记后待删集合为空（模拟用户取消）', () async {
      final c = NotepadController('前[img:a.jpg]中[img:b.jpg]后');
      await c.removeImage(c.blocks[1]);
      expect(c.pendingDeletions, isNotEmpty);
      c.discardPendingDeletions();
      expect(c.pendingDeletions, isEmpty);
      c.dispose();
    });

    test('重新载入会清空上一次的待删登记', () async {
      final c = NotepadController('前[img:old.jpg]后');
      await c.removeImage(c.blocks[1]);
      expect(c.pendingDeletions, contains('old.jpg'));
      c.load('全新内容');
      expect(c.pendingDeletions, isEmpty);
      c.dispose();
    });

    test('同一张图删两次只登记一条', () async {
      final c = NotepadController('前[img:dup.jpg]后[img:dup.jpg]尾');
      await c.removeImage(c.blocks[1]);
      // 第二张同名图此时索引已变
      final second = c.blocks.firstWhere((b) => b.isImage);
      await c.removeImage(second);
      expect(c.pendingDeletions, hasLength(1));
      c.dispose();
    });
  });
}
