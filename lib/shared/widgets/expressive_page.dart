/// 二级页过渡 · S1（Apple Design Mind）
/// push：新页整体从右缘滑入（带左缘投影），下层页左移 25% 视差 + 压暗 12%
/// modal（fullscreenDialog）：底部上推 + 顶部圆角，下层缩放 0.94 + 压暗（iOS sheet 层级感）
/// Reduce Motion：全部降级为纯淡入淡出
/// 类名保留 ExpressivePage（15 处路由引用零改动）
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// S1 层级过渡页面
class ExpressivePage<T> extends Page<T> {
  const ExpressivePage({
    required this.child,
    super.key,
    this.maintainState = true,
    this.fullscreenDialog = false,
  });

  final Widget child;
  final bool maintainState;
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      transitionDuration:
          fullscreenDialog ? AppMotion.slow : AppMotion.normal,
      reverseTransitionDuration: AppMotion.exit,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Reduce Motion：纯淡入淡出
        if (reduceMotionOf(context)) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppMotion.easeOut,
              reverseCurve: AppMotion.easeIn,
            ),
            child: child,
          );
        }

        // ===== 下层页（被覆盖时）：视差 + 压暗 =====
        final parallax = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.25, 0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppMotion.ease,
          reverseCurve: AppMotion.ease,
        ));

        final dim = CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppMotion.easeOut,
          reverseCurve: AppMotion.easeIn,
        );

        // ===== 上层页（本页入场）=====
        final Animation<Offset> slideIn;
        final Animation<double> fadeIn;

        if (fullscreenDialog) {
          // modal sheet：底部上推 + 淡入
          slideIn = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: AppMotion.ease,
            reverseCurve: AppMotion.ease,
          ));
          fadeIn = CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.4, curve: AppMotion.easeOut),
            reverseCurve: AppMotion.easeIn,
          );
        } else {
          // push：右缘整页滑入 + 轻微淡入
          slideIn = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: AppMotion.ease,
            reverseCurve: AppMotion.ease,
          ));
          fadeIn = Tween<double>(begin: 0.6, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppMotion.easeOut,
              reverseCurve: AppMotion.easeIn,
            ),
          );
        }

        Widget page = FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(position: slideIn, child: child),
        );

        if (fullscreenDialog) {
          // modal：顶部 16 圆角（sheet 视觉）
          page = ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: page,
          );
        } else {
          // push：左缘投影（页面叠页的深度感）
          page = Stack(
            children: [
              page,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 12,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: AppMotion.easeOut,
                      reverseCurve: AppMotion.easeIn,
                    ),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0x33000000),
                            Color(0x00000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return SlideTransition(
          position: parallax,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(dim),
            child: DimBackground(
              opacity: dim,
              fullscreenDialog: fullscreenDialog,
              child: page,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => child,
    );
  }
}

/// 下层页压暗层（覆盖时背景变暗，iOS 层级纵深）
class DimBackground extends StatelessWidget {
  const DimBackground({
    super.key,
    required this.opacity,
    required this.fullscreenDialog,
    required this.child,
  });

  final Animation<double> opacity;
  final bool fullscreenDialog;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // modal 下层还需轻微缩小（iOS sheet 背景缩放 0.92–0.96）
        if (fullscreenDialog)
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.94).animate(
              CurvedAnimation(
                parent: opacity,
                curve: Curves.linear,
                reverseCurve: Curves.linear,
              ),
            ),
            child: child,
          )
        else
          child,
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: fullscreenDialog ? 0.2 : 0.12)
                  .animate(opacity),
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
