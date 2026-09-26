/// 列表项错峰入场动画 · S1（Apple Design Mind）
/// 淡入 + 轻微上滑，按 index 30ms 错峰（封顶 8 档）
/// Reduce Motion：降级为纯淡入
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// 错峰入场容器：包住列表项即可
/// 用法：StaggerIn(index: i, child: _Card(...))
class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.child,
  });

  /// 列表项序号，决定错峰延迟
  final int index;

  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
            .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
    );
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.ease));

    if (reduceMotion) {
      // Reduce Motion：纯淡入，无位移
      _controller.forward();
    } else {
      Future.delayed(AppMotion.staggerDelay(widget.index), () {
        if (mounted) _controller.forward();
      });
    }
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
