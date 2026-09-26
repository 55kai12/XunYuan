/// 族谱树可视化页
/// 阶段 4：以某人为中心展示世系图，支持缩放、平移、点击节点
/// 阶段 6：新增导出 PNG 功能
/// - 向上显示父母
/// - 向下显示后代树（子女→孙子女…）
/// - 配偶与本人并排
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../person/domain/person_providers.dart';
import '../../export/domain/export_providers.dart';
import '../../family/domain/family_providers.dart';
import '../data/relationship_repository.dart';
import '../domain/relationship_providers.dart';

import '../../../core/i18n/i18n.dart';
// 布局常量
const double _nodeWidth = 110;
const double _nodeHeight = 56;
const double _spouseGap = 8;
const double _hGap = 28; // 兄弟子树之间的水平间距
const double _vGap = 72; // 世代之间的垂直间距
const double _parentSectionHeight = 90; // 父母区域高度
const double _padding = 40;

/// 族谱树页
class FamilyTreePage extends ConsumerStatefulWidget {
  const FamilyTreePage({super.key, required this.rootPersonId});

  final int rootPersonId;

  @override
  ConsumerState<FamilyTreePage> createState() => _FamilyTreePageState();
}

class _FamilyTreePageState extends ConsumerState<FamilyTreePage> {
  final GlobalKey _repaintKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  bool _isExporting = false;
  // 折叠的节点 ID 集合
  final Set<int> _collapsedNodes = {};
  // 只看直系模式
  bool _onlyDirectLine = false;
  // 当前中心人物 ID
  late int _centerPersonId = widget.rootPersonId;

  /// 切换中心人物
  void _setCenterPerson(int personId) {
    setState(() {
      _centerPersonId = personId;
      _collapsedNodes.clear();
    });
    // 重置视图
    _transformController.value = Matrix4.identity();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换中心人物'.tr), duration: const Duration(seconds: 1)),
    );
  }

  /// 折叠/展开某节点的后代
  void _toggleCollapse(int personId) {
    setState(() {
      if (_collapsedNodes.contains(personId)) {
        _collapsedNodes.remove(personId);
      } else {
        _collapsedNodes.add(personId);
      }
    });
  }

  /// 回到中心人物位置
  void _resetView() {
    _transformController.value = Matrix4.identity();
  }

  /// 搜索并定位成员：选中后切换为中心人物
  Future<void> _showLocateDialog() async {
    final rootPerson =
        await ref.read(watchPersonProvider(_centerPersonId).future);
    if (rootPerson == null || !mounted) return;

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => _PersonLocateDialog(treeId: rootPerson.treeId),
    );
    if (selected != null && selected != _centerPersonId) {
      _setCenterPerson(selected);
    }
  }

  /// 切换只看直系模式
  void _toggleDirectLine() {
    setState(() {
      _onlyDirectLine = !_onlyDirectLine;
      _collapsedNodes.clear();
    });
  }
  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('图例说明'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(
              color: AppColors.inkGreen,
              label: '男性成员（墨绿边框）'.tr,
            ),
            const SizedBox(height: 12),
            _legendItem(
              color: AppColors.cinnabar,
              label: '女性成员（朱砂边框）'.tr,
            ),
            const SizedBox(height: 12),
            _legendItem(
              color: AppColors.inkGray,
              label: '已故成员（灰色文字+删除线）'.tr,
              isDeceased: true,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '操作提示：'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('· 双指缩放可放大/缩小族谱树'.tr),
            Text('· 单指拖动可平移族谱树'.tr),
            Text('· 点击成员节点可查看详情'.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('知道了'.tr),
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    bool isDeceased = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              '名'.tr,
              style: TextStyle(
                fontSize: 11,
                color: isDeceased ? AppColors.inkGray : Colors.black87,
                decoration: isDeceased
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  /// 导出族谱树为 PNG
  Future<void> _exportPng() async {
    setState(() => _isExporting = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw '无法获取族谱树渲染对象'.tr;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw '图片编码失败'.tr;
      }
      final bytes = Uint8List.view(byteData.buffer);

      final service = ref.read(exportServiceProvider);
      final path = await service.savePng(bytes, prefix: '族谱树'.tr);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('族谱树已保存：$path'.tr)),
      );

      // 询问是否分享
      final share = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('导出成功'.tr),
          content: Text('是否分享族谱树图片？'.tr),
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
      if (share == true) {
        await Share.shareXFiles([XFile(path)], text: '寻渊族谱树'.tr);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// 导出族谱树为 PDF（含标题和家族信息）
  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      // 截图
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw '无法获取族谱树渲染对象'.tr;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw '图片编码失败'.tr;
      }
      final bytes = Uint8List.view(byteData.buffer);

      // 获取中心人物和家族信息
      final rootPerson = await ref.read(watchPersonProvider(_centerPersonId).future);
      final familyName = rootPerson != null
          ? await _getFamilyName(rootPerson.treeId)
          : '寻渊'.tr;
      final memberCount = await _countFamilyMembers(rootPerson?.treeId);

      final service = ref.read(exportServiceProvider);
      final path = await service.exportFamilyTreePdf(
        treeImage: bytes,
        familyName: familyName,
        rootPersonName: rootPerson != null
            ? '${rootPerson.surname}${rootPerson.givenName}'
            : null,
        memberCount: memberCount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('族谱树 PDF 已保存：$path'.tr)),
      );

      // 询问是否分享
      final share = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('导出成功'.tr),
          content: Text('是否分享族谱树 PDF？'.tr),
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
      if (share == true) {
        await Share.shareXFiles([XFile(path)], text: '寻渊族谱树'.tr);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败：$e'.tr),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// 获取家族名称
  Future<String> _getFamilyName(int treeId) async {
    final familyRepo = ref.read(familyRepositoryProvider);
    final family = await familyRepo.getById(treeId);
    return family?.name ?? '寻渊'.tr;
  }

  /// 统计家族成员数
  Future<int> _countFamilyMembers(int? treeId) async {
    if (treeId == null) return 0;
    final familyRepo = ref.read(familyRepositoryProvider);
    return familyRepo.countMembers(treeId);
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(descendantTreeProvider(_centerPersonId));
    final parentsAsync = ref.watch(parentsProvider(_centerPersonId));
    final rootAsync = ref.watch(watchPersonProvider(_centerPersonId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: rootAsync.maybeWhen(
          data: (p) => p != null
              ? Text('${p.surname}${p.givenName} 的族谱'.tr)
              : Text('族谱树'.tr),
          orElse: () => Text('族谱树'.tr),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: '定位成员'.tr,
            onPressed: _showLocateDialog,
          ),
          IconButton(
            icon: Icon(
              _onlyDirectLine ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _onlyDirectLine ? AppColors.cinnabar : null,
            ),
            tooltip: _onlyDirectLine ? '显示全部'.tr : '只看直系'.tr,
            onPressed: _toggleDirectLine,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '图例说明'.tr,
            onPressed: _showLegend,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: '导出 PDF'.tr,
            onPressed: _isExporting ? null : _exportPdf,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.image_outlined),
            tooltip: '导出 PNG'.tr,
            onPressed: _isExporting ? null : _exportPng,
          ),
        ],
      ),
      body: treeAsync.when(
        data: (root) {
          // 计算布局（传入折叠状态和只看直系模式）
          final layout = _TreeLayout(
            root,
            collapsedNodes: _collapsedNodes,
            onlyDirectLine: _onlyDirectLine,
          );
          final totalWidth = layout.subtreeWidth + _padding * 2;
          final totalHeight =
              layout.totalHeight + _parentSectionHeight + _padding * 2;

          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.3,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(100),
                constrained: false,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    color: isDark
                        ? Theme.of(context).scaffoldBackgroundColor
                        : AppColors.ricePaper,
                    width: totalWidth,
                    height: totalHeight,
                    child: Stack(
                      children: [
                        // 连线（底层）
                        CustomPaint(
                          size: Size(totalWidth, totalHeight),
                          painter: _TreeLinePainter(
                            layout: layout,
                            offsetX: _padding,
                            offsetY: _padding + _parentSectionHeight,
                            isDark: isDark,
                          ),
                        ),
                        // 父母区域
                        if (parentsAsync.value != null &&
                            parentsAsync.value!.isNotEmpty)
                          _ParentsLayer(
                            parents: parentsAsync.value!,
                            rootX: _padding + layout.rootX,
                            rootY: _padding + _parentSectionHeight,
                            isDark: isDark,
                            onParentTap: _setCenterPerson,
                          ),
                        // 节点（上层）
                        ...layout.nodes.map((node) => Positioned(
                              left: _padding + node.x - _nodeWidth / 2,
                              top: _padding +
                                  _parentSectionHeight +
                                  node.y,
                              child: _TreeNodeWidget(
                                node: node,
                                isDark: isDark,
                                isRoot:
                                    node.person.id == _centerPersonId,
                                isCollapsed: _collapsedNodes.contains(node.person.id),
                                hasChildren: node.children.isNotEmpty,
                                onToggleCollapse: () => _toggleCollapse(node.person.id),
                                onSetCenter: () => _setCenterPerson(node.person.id),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              // 浮动按钮：回到中心
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'reset_view',
                      onPressed: _resetView,
                      tooltip: '回到中心'.tr,
                      child: const Icon(Icons.center_focus_strong),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'expand_all',
                      onPressed: () {
                        setState(() => _collapsedNodes.clear());
                      },
                      tooltip: '展开全部'.tr,
                      child: const Icon(Icons.unfold_more),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载族谱失败：$e'.tr)),
      ),
    );
  }
}

/// 父母层（显示在根节点上方）
class _ParentsLayer extends StatelessWidget {
  const _ParentsLayer({
    required this.parents,
    required this.rootX,
    required this.rootY,
    required this.isDark,
    this.onParentTap,
  });

  final List<Person> parents;
  final double rootX;
  final double rootY;
  final bool isDark;
  final void Function(int personId)? onParentTap;

  @override
  Widget build(BuildContext context) {
    final totalWidth = parents.length * _nodeWidth +
        (parents.length - 1) * _spouseGap;
    final startX = rootX - totalWidth / 2;

    return Stack(
      children: [
        // 连线：父母底部中点 → 根节点顶部中点
        CustomPaint(
          size: Size.infinite,
          painter: _ParentLinePainter(
            parentsStartX: startX,
            parentsWidth: totalWidth,
            parentsBottomY: rootY - 16,
            rootTopY: rootY,
            rootX: rootX,
            isDark: isDark,
          ),
        ),
        // 父母节点
        for (var i = 0; i < parents.length; i++)
          Positioned(
            left: startX + i * (_nodeWidth + _spouseGap),
            top: rootY - _nodeHeight - 16,
            child: _PersonNode(
              person: parents[i],
              isDark: isDark,
              compact: true,
              onLongPress: onParentTap != null
                  ? () => onParentTap!(parents[i].id)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// 父母连线绘制
class _ParentLinePainter extends CustomPainter {
  _ParentLinePainter({
    required this.parentsStartX,
    required this.parentsWidth,
    required this.parentsBottomY,
    required this.rootTopY,
    required this.rootX,
    required this.isDark,
  });

  final double parentsStartX;
  final double parentsWidth;
  final double parentsBottomY;
  final double rootTopY;
  final double rootX;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey[600]! : AppColors.inkLightGray
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midY = (parentsBottomY + rootTopY) / 2;
    final parentsCenterX = parentsStartX + parentsWidth / 2;

    // 从父母底部中点向下
    canvas.drawLine(Offset(parentsCenterX, parentsBottomY),
        Offset(parentsCenterX, midY), paint);
    // 水平到根节点上方
    canvas.drawLine(
        Offset(parentsCenterX, midY), Offset(rootX, midY), paint);
    // 向下到根节点顶部
    canvas.drawLine(Offset(rootX, midY), Offset(rootX, rootTopY), paint);
  }

  @override
  bool shouldRepaint(covariant _ParentLinePainter old) =>
      old.parentsStartX != parentsStartX ||
      old.parentsWidth != parentsWidth ||
      old.rootX != rootX;
}

/// 树节点 Widget（含配偶）
class _TreeNodeWidget extends StatelessWidget {
  const _TreeNodeWidget({
    required this.node,
    required this.isDark,
    required this.isRoot,
    required this.isCollapsed,
    required this.hasChildren,
    required this.onToggleCollapse,
    required this.onSetCenter,
  });

  final _LayoutNode node;
  final bool isDark;
  final bool isRoot;
  final bool isCollapsed;
  final bool hasChildren;
  final VoidCallback onToggleCollapse;
  final VoidCallback onSetCenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PersonNode(
              person: node.person,
              isDark: isDark,
              highlighted: isRoot,
              onLongPress: onSetCenter,
            ),
            for (final s in node.spouses) ...[
              const SizedBox(width: _spouseGap),
              _PersonNode(
                person: s,
                isDark: isDark,
                isSpouse: true,
                onLongPress: onSetCenter,
              ),
            ],
          ],
        ),
        // 折叠/展开按钮（有子女时显示）
        if (hasChildren)
          GestureDetector(
            onTap: onToggleCollapse,
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCollapsed ? Icons.expand_more : Icons.expand_less,
                size: 14,
                color: isDark ? Colors.grey : AppColors.inkGray,
              ),
            ),
          ),
        // 折叠时显示后代数量提示
        if (isCollapsed && hasChildren)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${node.originalChildCount} 房'.tr,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.grey : AppColors.inkGray,
              ),
            ),
          ),
      ],
    );
  }
}

/// 个人节点卡片
class _PersonNode extends StatelessWidget {
  const _PersonNode({
    required this.person,
    required this.isDark,
    this.isSpouse = false,
    this.highlighted = false,
    this.compact = false,
    this.onLongPress,
  });

  final Person person;
  final bool isDark;
  final bool isSpouse;
  final bool highlighted;
  final bool compact;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isFemale = person.gender == Gender.female;
    final isDeceased = person.isAlive == false;
    final borderColor =
        isFemale ? AppColors.cinnabar : AppColors.inkGreen;
    // 已故成员降低文字和边框不透明度，视觉上区分
    final nameColor = isDeceased
        ? (isDark ? Colors.grey[500] : AppColors.inkGray)
        : (isDark ? AppColors.darkOnSurface : AppColors.inkBlack);
    final borderOpacity = isDeceased ? 0.3 : (highlighted ? 1.0 : 0.4);

    return GestureDetector(
      onTap: () => context.push('/person/${person.id}'),
      onLongPress: onLongPress,
      child: Container(
        width: _nodeWidth,
        height: compact ? _nodeHeight - 8 : _nodeHeight,
        decoration: BoxDecoration(
          color: highlighted
              ? (isDark
                  ? AppColors.inkGreenLight.withOpacity(0.2)
                  : AppColors.inkGreen.withOpacity(0.1))
              : (isDark
                  ? (isDeceased
                      ? AppColors.darkSurface.withOpacity(0.6)
                      : AppColors.darkSurface)
                  : (isDeceased
                      ? Colors.grey[50]
                      : Colors.white)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor.withOpacity(borderOpacity),
            width: highlighted ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark && !isDeceased)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDeceased) ...[
                  const Icon(Icons.bookmark, size: 10, color: AppColors.inkGray),
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: Text(
                    '${person.surname}${person.givenName}',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: nameColor,
                      decoration: isDeceased
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.inkGray.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                [
                  if (person.generation != null) '${person.generation}世'.tr,
                  if (person.generationWord != null &&
                      person.generationWord!.isNotEmpty)
                    person.generationWord!,
                  if (isSpouse) '配偶'.tr,
                ].join(' · '),
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDark ? Colors.grey[400] : AppColors.inkGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 树连线绘制
class _TreeLinePainter extends CustomPainter {
  _TreeLinePainter({
    required this.layout,
    required this.offsetX,
    required this.offsetY,
    required this.isDark,
  });

  final _TreeLayout layout;
  final double offsetX;
  final double offsetY;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey[600]! : AppColors.inkLightGray
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final node in layout.nodes) {
      if (node.children.isEmpty) continue;

      final parentX = offsetX + node.x;
      final parentBottomY = offsetY + node.y + _nodeHeight;
      final childTopY = offsetY + node.children.first.y;
      final midY = (parentBottomY + childTopY) / 2;

      // 从父母底部向下到中间线
      canvas.drawLine(Offset(parentX, parentBottomY),
          Offset(parentX, midY), paint);

      // 水平连接线（覆盖所有子女）
      final childXs =
          node.children.map((c) => offsetX + c.x).toList()..sort();
      canvas.drawLine(
          Offset(childXs.first, midY),
          Offset(childXs.last, midY),
          paint);

      // 从中间线向下到每个子女顶部
      for (final child in node.children) {
        final childX = offsetX + child.x;
        canvas.drawLine(
            Offset(childX, midY), Offset(childX, childTopY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreeLinePainter old) =>
      old.layout != layout || old.offsetX != offsetX;
}

// ==================== 布局计算 ====================

/// 布局后的节点
class _LayoutNode {
  _LayoutNode({
    required this.person,
    this.spouses = const [],
    this.children = const [],
  });

  final Person person;
  final List<Person> spouses;
  List<_LayoutNode> children;
  // 原始子节点数量（折叠时用于显示"N 房"）
  int _originalChildCount = 0;
  int get originalChildCount => _originalChildCount;

  double x = 0;
  double y = 0;
  double subtreeWidth = 0;
}

/// 树布局计算
class _TreeLayout {
  _TreeLayout(
    TreeNode root, {
    this.collapsedNodes = const {},
    this.onlyDirectLine = false,
  }) {
    // 转换为布局节点（应用折叠和只看直系过滤）
    final layoutRoot = _convert(root, 0);
    // 后序计算子树宽度
    _computeWidth(layoutRoot);
    // 前序分配 x 坐标
    _assignX(layoutRoot, 0);
    // 分配 y 坐标
    _assignY(layoutRoot, 0);

    rootNode = layoutRoot;
    rootX = layoutRoot.x;
    subtreeWidth = layoutRoot.subtreeWidth;
    // 收集所有节点
    nodes = _collect(layoutRoot);
    totalHeight = nodes.isEmpty
        ? 0
        : (nodes.map((n) => n.y).reduce((a, b) => a > b ? a : b)) +
            _nodeHeight;
  }

  final Set<int> collapsedNodes;
  final bool onlyDirectLine;

  late final _LayoutNode rootNode;
  late final double rootX;
  late final double subtreeWidth;
  late final List<_LayoutNode> nodes;
  late final double totalHeight;

  _LayoutNode _convert(TreeNode node, int depth) {
    // 只看直系模式：depth > 0 时只保留第一个子女（长子/主支）
    var children = node.children;
    if (onlyDirectLine && depth > 0 && children.length > 1) {
      children = [children.first];
    }

    // 折叠模式：该节点被折叠时不处理子节点
    final isCollapsed = collapsedNodes.contains(node.person.id);
    final layoutChildren = isCollapsed
        ? <_LayoutNode>[]
        : children.map((c) => _convert(c, depth + 1)).toList();

    return _LayoutNode(
      person: node.person,
      spouses: node.spouses,
      children: layoutChildren,
      // 保存原始子节点数量，用于折叠时显示"N 房"
    ).._originalChildCount = children.length;
  }

  /// 计算子树宽度（后序）
  double _computeWidth(_LayoutNode node) {
    // 自身宽度（含全部配偶）
    final selfWidth =
        _nodeWidth * (node.spouses.length + 1) + _spouseGap * node.spouses.length;

    if (node.children.isEmpty) {
      node.subtreeWidth = selfWidth;
      return selfWidth;
    }

    // 子节点宽度之和 + 间距
    double childrenWidth = 0;
    for (var i = 0; i < node.children.length; i++) {
      childrenWidth += _computeWidth(node.children[i]);
      if (i < node.children.length - 1) {
        childrenWidth += _hGap;
      }
    }

    node.subtreeWidth =
        childrenWidth > selfWidth ? childrenWidth : selfWidth;
    return node.subtreeWidth;
  }

  /// 分配 x 坐标（前序），[left] 为子树左边界
  void _assignX(_LayoutNode node, double left) {
    node.x = left + node.subtreeWidth / 2;

    if (node.children.isEmpty) return;

    double childLeft =
        left + (node.subtreeWidth - _childrenTotalWidth(node)) / 2;
    for (final child in node.children) {
      _assignX(child, childLeft);
      childLeft += child.subtreeWidth + _hGap;
    }
  }

  double _childrenTotalWidth(_LayoutNode node) {
    double w = 0;
    for (var i = 0; i < node.children.length; i++) {
      w += node.children[i].subtreeWidth;
      if (i < node.children.length - 1) w += _hGap;
    }
    return w;
  }

  /// 分配 y 坐标
  void _assignY(_LayoutNode node, int depth) {
    node.y = depth * (_nodeHeight + _vGap);
    for (final child in node.children) {
      _assignY(child, depth + 1);
    }
  }

  List<_LayoutNode> _collect(_LayoutNode node) {
    final result = <_LayoutNode>[node];
    for (final child in node.children) {
      result.addAll(_collect(child));
    }
    return result;
  }
}

/// 成员定位对话框：按姓名/字号过滤，选中后切换为中心人物
class _PersonLocateDialog extends ConsumerStatefulWidget {
  const _PersonLocateDialog({required this.treeId});

  final int treeId;

  @override
  ConsumerState<_PersonLocateDialog> createState() =>
      _PersonLocateDialogState();
}

class _PersonLocateDialogState extends ConsumerState<_PersonLocateDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(watchPersonsByTreeProvider(widget.treeId));
    final persons = (personsAsync.valueOrNull ?? const <Person>[])
        .where((p) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return '${p.surname}${p.givenName}'.toLowerCase().contains(q) ||
              (p.courtesyName ?? '').contains(_query) ||
              (p.artName ?? '').contains(_query);
        })
        .toList()
      ..sort((a, b) =>
          (a.generation ?? 0).compareTo(b.generation ?? 0));

    return AlertDialog(
      title: Text('定位成员'.tr),
      content: SizedBox(
        width: 320,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: '输入姓名搜索'.tr,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: persons.isEmpty
                  ? Center(child: Text('没有匹配的成员'.tr,
                      style: const TextStyle(color: AppColors.inkGray)))
                  : ListView.builder(
                      itemCount: persons.length,
                      itemBuilder: (context, i) {
                        final p = persons[i];
                        final name = '${p.surname}${p.givenName}';
                        return ListTile(
                          dense: true,
                          leading: Text(
                            p.generation != null
                                ? '第${p.generation}世'.tr
                                : '',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.inkGray),
                          ),
                          title: Text(name),
                          subtitle: (p.branch ?? '').isNotEmpty
                              ? Text(p.branch!,
                                  style: const TextStyle(fontSize: 12))
                              : null,
                          onTap: () => Navigator.pop(context, p.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'.tr),
        ),
      ],
    );
  }
}
