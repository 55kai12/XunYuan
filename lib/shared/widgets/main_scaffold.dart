/// 主页面骨架：底部导航 + 内容区 · S1（Apple Design Mind）
/// 导航栏：surface 底色 + 0.5 separator 描边，tint 选中态，无胶囊指示器
/// 交互：Tab 切换 selection 触觉；内容切换双页联动转场（方向感知滑入/滑出）
/// Reduce Motion：Tab 切换动画直接跳过
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_motion.dart';

import '../../core/i18n/i18n.dart';
/// 底部导航主骨架
/// 通过 StatefulShellRoute 注入，根据当前路径高亮对应 Tab；
/// goBranch 切换分支（各分支 Navigator 独立，滚动状态保留）
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.currentPath,
    required this.navigationShell,
  });

  /// 当前路由路径，用于判断选中的 Tab
  final String currentPath;

  /// 分支导航壳（含各 Tab 的独立 Navigator）
  final StatefulNavigationShell navigationShell;

  /// 根据路径计算当前选中的 Tab 索引
  int _getSelectedIndex() {
    if (currentPath.startsWith(AppRoutes.members)) return NavIndex.members;
    if (currentPath.startsWith(AppRoutes.timeline)) return NavIndex.timeline;
    if (currentPath.startsWith(AppRoutes.profile)) return NavIndex.profile;
    return NavIndex.tree;
  }

  /// 底部导航项点击跳转
  void _onItemTapped(BuildContext context, int index) {
    // S1：Tab 切换轻触觉（selection click）
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      // 再点当前 Tab：回到该 Tab 初始页
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex();
    final colorScheme = Theme.of(context).colorScheme;

    // 根据当前 Tab 配置 FAB；「我的」页不显示 FAB
    FloatingActionButton? fab;

    switch (selectedIndex) {
      case NavIndex.tree:
        fab = FloatingActionButton(
          onPressed: () => context.push('/family/new'),
          tooltip: '新建家族'.tr,
          child: const Icon(Icons.add, size: 24),
        );
        break;
      case NavIndex.members:
        fab = FloatingActionButton(
          onPressed: () => context.push('/person/new'),
          tooltip: '添加成员'.tr,
          child: const Icon(Icons.person_add, size: 24),
        );
        break;
      case NavIndex.timeline:
        fab = FloatingActionButton(
          onPressed: () => context.push('/event/new'),
          tooltip: '添加事件'.tr,
          child: const Icon(Icons.event_note, size: 24),
        );
        break;
      case NavIndex.profile:
        fab = null; // 我的页不显示 FAB
        break;
    }

    return Scaffold(
      // 内容延伸到玻璃栏后（blur 才有东西可糊）
      extendBody: true,
      body: _AnimatedTabContent(
        currentPath: currentPath,
        child: navigationShell,
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: ClipRect(
        // S1 chrome 材质：blur + 72% surface；顶部 0.5 separator
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: colorScheme.surface.withOpacity(0.72),
            foregroundDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    _onItemTapped(context, index),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.account_tree_outlined),
                    selectedIcon: const Icon(Icons.account_tree),
                    label: '族谱'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.supervisor_account_outlined),
                    selectedIcon: const Icon(Icons.supervisor_account),
                    label: '成员'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.trending_up_outlined),
                    selectedIcon: const Icon(Icons.trending_up),
                    label: '时间线'.tr,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings),
                    label: '我的'.tr,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab 切换动画容器 · S1 · 方向感知转场
/// 切向更高索引 Tab：内容从右侧滑入（25% 屏宽）并淡入；
/// 切向更低索引则从左侧滑入——方向感明确，且不用同时挂载两份
/// 导航子树（IndexedStack 内含各分支 Navigator 的 GlobalKey，双挂载必冲突）
/// Reduce Motion：Tab 切换动画直接跳过
class _AnimatedTabContent extends StatefulWidget {
  const _AnimatedTabContent({
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  @override
  State<_AnimatedTabContent> createState() => _AnimatedTabContentState();
}

class _AnimatedTabContentState extends State<_AnimatedTabContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  int _lastIndex = 0;

  /// 路径 → Tab 索引（与 MainScaffold 的选中逻辑一致）
  int _indexOf(String path) {
    if (path.startsWith(AppRoutes.members)) return NavIndex.members;
    if (path.startsWith(AppRoutes.timeline)) return NavIndex.timeline;
    if (path.startsWith(AppRoutes.profile)) return NavIndex.profile;
    return NavIndex.tree;
  }

  /// 按切换方向构建入场动画（位移为屏宽比例）
  void _setupAnimations(double dir) {
    _fade = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
    );
    _slide = Tween<Offset>(
      begin: Offset(dir * 0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.ease,
    ));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.tabSwitch,
    );
    _lastIndex = _indexOf(widget.currentPath);
    _setupAnimations(0);
    _controller.value = 1.0; // 初始状态完全显示
  }

  @override
  void didUpdateWidget(_AnimatedTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath == widget.currentPath) return;

    final newIndex = _indexOf(widget.currentPath);
    final direction =
        newIndex > _lastIndex ? 1.0 : (newIndex < _lastIndex ? -1.0 : 0.0);
    _lastIndex = newIndex;

    if (reduceMotionOf(context)) {
      _controller.value = 1.0; // Reduce Motion：直接切换
      return;
    }

    _setupAnimations(direction);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
