/// S1（Apple Design Mind）动效 Token
/// 时序：入场 250–400ms，退场 200–300ms，列表错峰 20–50ms
/// 物理：跟手、可中断、轻微过冲克制；按压 scale 0.96–0.98
/// 可访问性：所有动效在 Reduce Motion 下降级为淡入淡出或直接切换
library;

import 'package:flutter/material.dart';

/// S1 动效常量
class AppMotion {
  AppMotion._();

  // ===== 时长 =====
  /// 快速交互（按压、chip 切换）
  static const Duration fast = Duration(milliseconds: 200);

  /// 常规转场（push/sheet 入场）
  static const Duration normal = Duration(milliseconds: 350);

  /// modal 上推（iOS sheet）
  static const Duration slow = Duration(milliseconds: 420);

  /// 退场
  static const Duration exit = Duration(milliseconds: 280);

  /// Tab 内容切换（双页联动转场）
  static const Duration tabSwitch = Duration(milliseconds: 360);

  /// 列表错峰间隔（30ms，超过 8 项后不再递增）
  static const Duration staggerStep = Duration(milliseconds: 30);
  static const int maxStaggerSteps = 8;

  // ===== 曲线 =====
  /// S1 主曲线：模拟 iOS spring（response ~0.4, damping ~0.85）
  /// 前段快、尾段缓，无过冲，用于位移/尺寸
  static const Curve ease = Cubic(0.32, 0.72, 0, 1);

  /// 减速曲线：用于淡入、透明度
  static const Curve easeOut = Curves.easeOutCubic;

  /// 加速曲线：用于退场、淡出
  static const Curve easeIn = Curves.easeInCubic;

  // ===== 按压 =====
  /// 按压缩放（S1: 0.96–0.98）
  static const double pressScale = 0.97;

  // ===== 列表错峰 =====
  /// 第 [index] 项的错峰延迟，封顶 [maxStaggerSteps]
  static Duration staggerDelay(int index) {
    final step = index < maxStaggerSteps ? index : maxStaggerSteps;
    return staggerStep * step;
  }
}

/// 读取系统 Reduce Motion 设置
/// 开启时调用方应把动画降级为淡入淡出或直接切换
bool reduceMotionOf(BuildContext context) {
  return MediaQuery.of(context).disableAnimations;
}
