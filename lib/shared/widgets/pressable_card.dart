/// 可按压卡片组件 · S1（Apple Design Mind）
/// 按下 scale 0.97（120ms 快速跟随），松开弹性恢复
/// 无水波纹；轻触觉反馈；可被 Reduce Motion 降级为透明度变化
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_colors.dart';

/// 按压缩放卡片
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = AppColors.cardRadius,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double borderRadius;

  /// 点按时是否触发轻触觉（S1 按压触觉）
  final bool enableHaptic;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = reduceMotionOf(context);

    return AnimatedScale(
      scale: _isPressed ? AppMotion.pressScale : 1.0,
      duration: AppMotion.fast,
      curve: _isPressed ? Curves.easeOut : AppMotion.ease,
      child: AnimatedOpacity(
        // Reduce Motion 降级：不缩放，改用轻微变暗表达按压
        opacity: _isPressed && reduceMotion ? 0.7 : 1.0,
        duration: AppMotion.fast,
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.color ?? colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: Colors.transparent, // S1：无水波纹
              highlightColor: colorScheme.onSurface.withOpacity(0.04),
              onTap: () {
                if (widget.enableHaptic && !reduceMotion) {
                  HapticFeedback.lightImpact();
                }
                widget.onTap?.call();
              },
              onLongPress: () {
                if (widget.enableHaptic && !reduceMotion) {
                  HapticFeedback.mediumImpact();
                }
                widget.onLongPress?.call();
              },
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
