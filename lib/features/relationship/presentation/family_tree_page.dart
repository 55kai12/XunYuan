/// 族谱树可视化页
/// 阶段 4：以某人为中心展示世系图，支持缩放、平移、点击节点
/// 阶段 6：新增导出 PNG 功能
/// - 向上显示父母
/// - 向下显示后代树（子女→孙子女…）
/// - 配偶与本人并排
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../person/domain/person_providers.dart';
import '../../export/domain/export_providers.dart';
import '../../export/presentation/export_options_sheet.dart';
import '../../family/domain/family_providers.dart';
import '../data/relationship_repository.dart';
import '../domain/kinship.dart';
import '../domain/relationship_providers.dart';

import '../../../core/i18n/i18n.dart';
// 布局常量
const double _nodeWidth = 110;
const double _nodeHeight = 56;
const double _spouseGap = 8;
const double _hGap = 28; // 兄弟子树之间的水平间距
const double _vGap = 72; // 世代之间的垂直间距
const double _parentSectionHeight = 90; // 父母区域高度（字号放大时按需增长）
const double _padding = 40; // 垂直外边距；水平方向按屏幕宽动态算 paddingX

/// 卡片内「文字区」的高度（= 卡片基准高 56 − 固定内边距/边框 14）。
/// 文字行高随系统字号线性放大，而内边距、边框、行距不放大，
/// 所以只放大这一段；整卡一起放大会在 1.3x 就多留一大截空白。
const double _nodeTextHeight = _nodeHeight - 14;

/// 按当前系统字号算出的卡片高度。
/// 卡片原本写死 56px，只够放「姓名 + 世代·字辈」两行（内容区仅 ~40px），
/// 系统字号一调大就溢出（实测 1.3x 起每张卡溢出 7px，2.0x 达 29px）。
/// 1.0x 时结果恰为 [_nodeHeight]，与改造前逐像素一致。
double _effectiveNodeHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
  return 14 + _nodeTextHeight * scale;
}

/// 族谱树页
class FamilyTreePage extends ConsumerStatefulWidget {
  const FamilyTreePage({
    super.key,
    required this.rootPersonId,
    this.autoExport = false,
  });

  final int rootPersonId;

  /// 进入页面后自动弹出导出选项（供「导出中心」深链直达）
  final bool autoExport;

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
  // 显示称呼模式：卡片副标题由「世代·字辈」换成相对中心人的称谓
  bool _showKinship = false;
  // 当前中心人物 ID
  late int _centerPersonId = widget.rootPersonId;

  // 上一次成功加载的树与父母。
  // 切换中心人物时 treeAsync / parentsAsync 对应的 provider 会重建，期间
  // valueOrNull 为空；若直接渲染 loading 占位符，整棵树的 element 会被销毁重建，
  // 既闪一下空白，也让「称谓切换」的过渡动画永远播不出来（新 element 首帧
  // 不播动画）。沿用上一次的数据即可让卡片按人复用，动画得以接续。
  TreeNode? _lastTree;
  List<Person> _lastParents = const [];

  @override
  void initState() {
    super.initState();
    if (widget.autoExport) {
      // 等首帧布局完成再弹导出选项，确保截图时树已渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _export();
      });
    }
  }

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

  /// 点击成员：弹出「设为中心人物 / 查看详情」菜单
  Future<void> _showPersonMenu(Person person, String? kinshipTerm) async {
    final isCenter = person.id == _centerPersonId;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              title: Text(
                '${person.surname}${person.givenName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: kinshipTerm != null && kinshipTerm.isNotEmpty
                  ? Text('称呼：$kinshipTerm'.tr)
                  : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(isCenter ? '已是中心人物'.tr : '设为中心人物'.tr),
              enabled: !isCenter,
              onTap: () => Navigator.pop(ctx, 'center'),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text('查看详情'.tr),
              onTap: () => Navigator.pop(ctx, 'detail'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'center') {
      _setCenterPerson(person.id);
    } else if (action == 'detail') {
      context.push('/person/${person.id}');
    }
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
            Text('· 点击成员节点：可设为中心人物或查看详情'.tr),
            Text('· 打开「称呼」开关，卡片上会显示相对中心人的称谓'.tr),
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

  /// 单边像素上限。GPU 纹理上限一般是 16384，留一截余量。
  /// 超限时 `toImage` 会直接抛 / OOM，大族谱「超清」导出会崩。
  static const int _maxExportPixels = 12000;

  /// 计算实际可用的 pixelRatio：按用户所选清晰度，但保证长边不超过
  /// [_maxExportPixels]。返回的第二个值是「是否因超限被下调」。
  static (double, bool) _safePixelRatio(Size logicalSize, double requested) {
    final longest = logicalSize.width > logicalSize.height
        ? logicalSize.width
        : logicalSize.height;
    if (longest <= 0) return (requested, false);
    final maxRatio = _maxExportPixels / longest;
    if (requested <= maxRatio) return (requested, false);
    // 下限 0.5，避免极端宽幅树算出接近 0 的比例
    return (maxRatio < 0.5 ? 0.5 : maxRatio, true);
  }

  /// 导出族谱树：先弹选项（格式 + 清晰度），再按选项输出 PNG / PDF / 两者
  Future<void> _export() async {
    final opts = await showExportOptionsSheet(context);
    if (opts == null || !mounted) return;
    setState(() => _isExporting = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw '无法获取族谱树渲染对象'.tr;
      }
      // 大族谱超清导出会撞 GPU 纹理上限，这里按长边压一下 pixelRatio
      final (ratio, capped) = _safePixelRatio(boundary.size, opts.scale);
      final image = await boundary.toImage(pixelRatio: ratio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      // 及时释放位图，否则导出大图后内存长时间不回收（缓慢泄漏）
      image.dispose();
      if (capped && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('族谱较大，已自动降低导出清晰度'.tr)),
        );
      }
      if (byteData == null) {
        throw '图片编码失败'.tr;
      }
      final bytes = Uint8List.view(byteData.buffer);

      final service = ref.read(exportServiceProvider);
      final saved = <String>[];

      if (opts.format == ExportFormat.png ||
          opts.format == ExportFormat.both) {
        final path = await service.savePng(bytes, prefix: '族谱树'.tr);
        saved.add(path);
        if (!mounted) return;
        showSavedSnack(context, '族谱树已保存：$path'.tr);
      }

      if (opts.format == ExportFormat.pdf ||
          opts.format == ExportFormat.both) {
        final rootPerson =
            await ref.read(watchPersonProvider(_centerPersonId).future);
        final familyName = rootPerson != null
            ? await _getFamilyName(rootPerson.treeId)
            : '寻渊'.tr;
        final path = await service.exportFamilyTreePdf(
          treeImage: bytes,
          familyName: familyName,
          rootPersonName: rootPerson != null
              ? '${rootPerson.surname}${rootPerson.givenName}'
              : null,
          memberCount: await _countFamilyMembers(rootPerson?.treeId),
        );
        saved.add(path);
        if (!mounted) return;
        showSavedSnack(context, '族谱树 PDF 已保存：$path'.tr);
      }

      if (!mounted || saved.isEmpty) return;
      await askShare(
        context,
        paths: saved,
        question: '是否分享导出文件？'.tr,
        shareText: '寻渊族谱树'.tr,
      );
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
    final rawTree = ref.watch(descendantTreeProvider(_centerPersonId));
    final rawParents = ref.watch(parentsProvider(_centerPersonId));
    final rootAsync = ref.watch(watchPersonProvider(_centerPersonId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 记住这次成功拿到的数据，供下一次切换中心人物时沿用（见 _lastTree 注释）。
    // 注意只在拿到**非空**树时覆盖：null 表示根成员已被删除，
    // 若拿 null 覆盖缓存，切回有效成员时就没有旧树可撑住动画了。
    if (rawTree.hasValue && rawTree.value != null) _lastTree = rawTree.value;
    final freshParents = rawParents.valueOrNull;
    if (freshParents != null) _lastParents = freshParents;
    final treeAsync = rawTree.hasValue || _lastTree == null
        ? rawTree
        : AsyncData<TreeNode?>(_lastTree);

    // 亲属称谓：需要全家族的成员与关系；treeId 未就绪时用 -1 占位（返回空）。
    // 切换中心人物时 rootAsync 也会短暂为空，此时退用树根成员的家族 ID，
    // 否则称谓表会被清空，所有人的称呼先退回「世代·字辈」再换回来。
    final treeId =
        rootAsync.valueOrNull?.treeId ?? _lastTree?.person.treeId ?? -1;
    var kinship = const <int, String>{};
    if (_showKinship) {
      final ps = ref.watch(watchPersonsByTreeProvider(treeId)).valueOrNull;
      final rs = ref.watch(watchRelationshipsByTreeProvider(treeId)).valueOrNull;
      if (ps != null && ps.isNotEmpty && rs != null) {
        kinship = buildKinshipTerms(
          centerId: _centerPersonId,
          persons: ps,
          relationships: rs,
        );
      }
    }
    String? termOf(int personId) =>
        _showKinship ? kinship[personId] : null;

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
                : const Icon(Icons.ios_share),
            tooltip: '导出'.tr,
            onPressed: _isExporting ? null : _export,
          ),
        ],
      ),
      body: treeAsync.when(
        data: (root) {
          // 根成员已被删除：显示提示而不是崩溃
          if (root == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '该成员已被删除，请返回重新选择中心人物'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkGray),
                ),
              ),
            );
          }
          final parents = rawParents.value ?? _lastParents;
          // 卡片高度跟随系统字号（1.0x 时等于 _nodeHeight）
          final nodeHeight = _effectiveNodeHeight(context);
          // 父母区：为多出来的卡片高度补足空间，保证父母卡片顶部不被容器裁掉
          // 没有父母时不留父母区高度，否则树顶会空出一大块
          final parentSectionHeight = parents.isEmpty
              ? 0.0
              : _parentSectionHeight + (nodeHeight - _nodeHeight);
          // 计算布局（传入折叠状态和只看直系模式）
          final layout = _TreeLayout(
            root,
            nodeHeight: nodeHeight,
            collapsedNodes: _collapsedNodes,
            onlyDirectLine: _onlyDirectLine,
          );
          // 水平边距：内容窄于屏幕时让树整体居中，宽于屏幕时退到最小边距、
          // 交给缩放拖动；固定 40 会在窄屏上把最右一列推出可视区。
          final paddingX = math.max(
            10.0,
            (MediaQuery.sizeOf(context).width - layout.subtreeWidth) / 2,
          );
          final totalWidth = layout.subtreeWidth + paddingX * 2;
          final totalHeight =
              layout.totalHeight + parentSectionHeight + _padding * 2;

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
                            offsetX: paddingX,
                            offsetY: _padding + parentSectionHeight,
                            isDark: isDark,
                            nodeHeight: nodeHeight,
                          ),
                        ),
                        // 父母区域
                        if (parents.isNotEmpty)
                          _ParentsLayer(
                            parents: parents,
                            rootX: paddingX + layout.rootNode.anchorX,
                            rootY: _padding + parentSectionHeight,
                            isDark: isDark,
                            nodeHeight: nodeHeight,
                            kinshipTermOf: termOf,
                            onParentTap: (p) => _showPersonMenu(p, termOf(p.id)),
                          ),
                        // 节点（上层）
                        ...layout.nodes.map((node) => Positioned(
                              // 按人配 key：切换中心人物后树会整体重排，只有让
                              // element 跟着「人」走，留在树上的卡片才会被复用、
                              // 卡片里的称谓才有机会播「旧称谓 → 新称谓」的过渡。
                              key: ValueKey(node.person.id),
                              left: paddingX + node.x - node.groupWidth / 2,
                              top: _padding +
                                  parentSectionHeight +
                                  node.y,
                              child: _TreeNodeWidget(
                                node: node,
                                isDark: isDark,
                                isRoot:
                                    node.person.id == _centerPersonId,
                                isCollapsed: _collapsedNodes.contains(node.person.id),
                                hasChildren: node.children.isNotEmpty,
                                nodeHeight: nodeHeight,
                                kinshipTermOf: termOf,
                                onToggleCollapse: () => _toggleCollapse(node.person.id),
                                onTapPerson: (p) => _showPersonMenu(p, termOf(p.id)),
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
              // 浮动按钮：称呼开关
              Positioned(
                left: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'kinship_toggle',
                  // 主题给 FAB 设了 CircleBorder，extended 会被压成圆形裁掉文字
                  shape: const StadiumBorder(),
                  onPressed: () =>
                      setState(() => _showKinship = !_showKinship),
                  backgroundColor:
                      _showKinship ? AppColors.inkGreen : null,
                  foregroundColor: _showKinship ? Colors.white : null,
                  icon: const Icon(Icons.family_restroom),
                  label: Text('称呼'.tr),
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
    required this.nodeHeight,
    this.kinshipTermOf,
    this.onParentTap,
  });

  final List<Person> parents;
  final double rootX;
  final double rootY;
  final bool isDark;

  /// 按系统字号算出的整卡高度；父母层用它的 compact 版（-8）
  final double nodeHeight;
  final String? Function(int personId)? kinshipTermOf;
  final void Function(Person person)? onParentTap;

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
            // 父母用的是 compact 卡片（高 nodeHeight-8，顶部在 rootY-nodeHeight-16），
            // 连线起点要贴到它的真实底边，否则会悬空 8px
            parentsBottomY: rootY - (nodeHeight - 8) - 16,
            rootTopY: rootY,
            rootX: rootX,
            isDark: isDark,
          ),
        ),
        // 父母节点
        for (var i = 0; i < parents.length; i++)
          Positioned(
            key: ValueKey(parents[i].id),
            left: startX + i * (_nodeWidth + _spouseGap),
            top: rootY - nodeHeight - 16,
            child: _PersonNode(
              person: parents[i],
              isDark: isDark,
              height: nodeHeight - 8,
              compact: true,
              subtitleOverride: kinshipTermOf?.call(parents[i].id),
              onTap: onParentTap != null
                  ? () => onParentTap!(parents[i])
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
    required this.nodeHeight,
    required this.onToggleCollapse,
    required this.onTapPerson,
    this.kinshipTermOf,
  });

  final _LayoutNode node;
  final bool isDark;
  final bool isRoot;
  final bool isCollapsed;
  final bool hasChildren;
  final double nodeHeight;
  final VoidCallback onToggleCollapse;
  final void Function(Person person) onTapPerson;
  final String? Function(int personId)? kinshipTermOf;

  @override
  Widget build(BuildContext context) {
    // 折叠按钮与「N 房」提示统一对齐到本人卡片中心（而非含配偶的整组中点），
    // 这样竖线正好从按钮背后穿过。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PersonNode(
              key: ValueKey(node.person.id),
              person: node.person,
              isDark: isDark,
              height: nodeHeight,
              highlighted: isRoot,
              subtitleOverride: kinshipTermOf?.call(node.person.id),
              onTap: () => onTapPerson(node.person),
            ),
            for (final s in node.spouses) ...[
              const SizedBox(width: _spouseGap),
              _PersonNode(
                key: ValueKey(s.id),
                person: s,
                isDark: isDark,
                height: nodeHeight,
                isSpouse: true,
                subtitleOverride: kinshipTermOf?.call(s.id),
                onTap: () => onTapPerson(s),
              ),
            ],
          ],
        ),
        // 折叠/展开按钮（有子女时显示）
        if (hasChildren)
          SizedBox(
            // 与连线锚点同列：折叠按钮正落在夫妻中点的垂线上
            width: node.groupWidth,
            child: Center(
              child: GestureDetector(
                onTap: onToggleCollapse,
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
            ),
          ),
        // 折叠时显示后代数量提示
        if (isCollapsed && hasChildren)
          SizedBox(
            width: node.groupWidth,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${node.originalChildCount} 房'.tr,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey : AppColors.inkGray,
                  ),
                ),
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
    super.key,
    required this.person,
    required this.isDark,
    required this.height,
    this.isSpouse = false,
    this.highlighted = false,
    this.compact = false,
    this.subtitleOverride,
    this.onTap,
  });

  final Person person;
  final bool isDark;

  /// 卡片高度，由调用方按当前系统字号算好（见 [_effectiveNodeHeight]）
  final double height;
  final bool isSpouse;
  final bool highlighted;
  final bool compact;

  /// 非空时用它替换卡片副标题（用于显示「称呼」）
  final String? subtitleOverride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFemale = person.gender == Gender.female;
    final reduceMotion = reduceMotionOf(context);
    final isDeceased = person.isAlive == false;
    final borderColor =
        isFemale ? AppColors.cinnabar : AppColors.inkGreen;
    // 已故成员降低文字和边框不透明度，视觉上区分
    final nameColor = isDeceased
        ? (isDark ? Colors.grey[500] : AppColors.inkGray)
        : (isDark ? AppColors.darkOnSurface : AppColors.inkBlack);
    final borderOpacity = isDeceased ? 0.3 : (highlighted ? 1.0 : 0.4);

    // 副标题：称呼开关打开时优先显示称谓（紧凑卡片也显示），否则显示世代·字辈
    final subtitle = subtitleOverride ??
        [
          if (person.generation != null) '${person.generation}世'.tr,
          if (person.generationWord != null &&
              person.generationWord!.isNotEmpty)
            person.generationWord!,
          if (isSpouse) '配偶'.tr,
        ].join(' · ');
    final showSubtitle = !compact || subtitleOverride != null;

    return GestureDetector(
      onTap: onTap ?? () => context.push('/person/${person.id}'),
      child: Container(
        width: _nodeWidth,
        height: height,
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
            if (showSubtitle && subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              // 称谓会随「中心人物」改变（儿子 → 本人、儿媳 → 妻子…）。
              // 这里让旧称谓向下淡出、新称谓从下方淡入并归位，切换时能看清
              // 「刚才叫什么、现在叫什么」；直接换字会像闪了一下。
              AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : AppMotion.normal,
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeIn,
                // Stack 默认 Clip.hardEdge，位移中的文字会被切掉一条边
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    ...previous,
                    if (current != null) current,
                  ],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  subtitle,
                  key: ValueKey(subtitle),
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight:
                        subtitleOverride != null ? FontWeight.w600 : null,
                    color: subtitleOverride != null
                        ? (isDark
                            ? AppColors.inkGreenLight
                            : AppColors.inkGreen)
                        : (isDark ? Colors.grey[400] : AppColors.inkGray),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
    required this.nodeHeight,
  });

  final _TreeLayout layout;
  final double offsetX;
  final double offsetY;
  final bool isDark;
  final double nodeHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey[600]! : AppColors.inkLightGray
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final node in layout.nodes) {
      if (node.children.isEmpty) continue;

      final parentX = offsetX + node.anchorX;
      final parentBottomY = offsetY + node.y + nodeHeight;
      final childTopY = offsetY + node.children.first.y;
      final midY = (parentBottomY + childTopY) / 2;

      // 从父母底部向下到中间线
      canvas.drawLine(Offset(parentX, parentBottomY),
          Offset(parentX, midY), paint);

      // 水平连接线：起点必须覆盖父节点自己的落点，
      // 否则父节点锚点与子女锚点错开时会断开（单子女尤其明显）
      final childXs =
          node.children.map((c) => offsetX + c.anchorX).toList()..sort();
      final barLeft = parentX < childXs.first ? parentX : childXs.first;
      final barRight = parentX > childXs.last ? parentX : childXs.last;
      canvas.drawLine(Offset(barLeft, midY), Offset(barRight, midY), paint);

      // 从中间线向下到每个子女顶部
      for (final child in node.children) {
        final childX = offsetX + child.anchorX;
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

  /// 本人卡片 + 配偶卡片的总宽度，即节点实际绘制宽度
  double get groupWidth =>
      _nodeWidth * (spouses.length + 1) + _spouseGap * spouses.length;

  /// 连线锚点：整组（本人 + 配偶）的水平中心。
  /// 传统家谱画法即从夫妻中点垂线，且子女层正是按整组居中排布的，
  /// 锚点取同一列时父子连线才笔直；若锚在本人卡片中心，
  /// 有配偶的节点会比子女层偏左半个配偶宽度，连线被迫拐成钩形。
  double get anchorX => x;
}

/// 树布局计算
class _TreeLayout {
  _TreeLayout(
    TreeNode root, {
    required this.nodeHeight,
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
            nodeHeight;
  }

  /// 按系统字号算出的卡片高度，世代间距与总高都依赖它
  final double nodeHeight;
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
    final selfWidth = node.groupWidth;

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
    if (node.children.isEmpty) {
      node.x = left + node.subtreeWidth / 2;
      return;
    }

    double childLeft =
        left + (node.subtreeWidth - _childrenTotalWidth(node)) / 2;
    for (final child in node.children) {
      _assignX(child, childLeft);
      childLeft += child.subtreeWidth + _hGap;
    }

    // 父锚点对齐到「首尾子女锚点的中点」，而不是子树矩形的中心：
    // 各子女区间宽窄不一时（有配偶的那个占位更宽），矩形中心会让
    // 父线偏离横杆中点、整族左右不对称。再钳进自身区间，
    // 防止父母卡片较宽时越界压到同代兄弟。
    final wanted =
        (node.children.first.anchorX + node.children.last.anchorX) / 2;
    final half = node.groupWidth / 2;
    node.x = wanted
        .clamp(left + half, left + node.subtreeWidth - half)
        .toDouble();
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
    node.y = depth * (nodeHeight + _vGap);
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
