/// 全局字号上限
///
/// Flutter 默认 1:1 跟随系统字号。老年用户常把系统字号调到 1.3~2.0x
/// （1.3x 是很多长辈实际在用的档位），而部分 ROM 的「超大」档能到 ≈2.0x，
/// 会把固定高度的卡片撑爆。这里只封顶、不抬底 —— 用户特意调小就尊重他。
///
/// 单独抽成一个函数，是因为截图测试自建了一个 MaterialApp（不复用
/// XunYuanApp，因为它从设置里读主题与语言，会让截图不确定），
/// 两边必须套同一层限制，否则测不到这个上限到底有没有生效。
library;

import 'package:flutter/material.dart';

/// 应用允许的最大系统字号倍率
const double kMaxTextScale = 1.6;

/// 把 [child] 子树里的系统字号钳到 [kMaxTextScale] 以内。
///
/// 未超上限时不额外包一层 MediaQuery —— 绝大多数用户（1.0x）零开销、零重建。
Widget limitTextScale(BuildContext context, Widget child) {
  final media = MediaQuery.of(context);
  if (media.textScaler.scale(1.0) <= kMaxTextScale) return child;
  return MediaQuery(
    data: media.copyWith(
      textScaler: media.textScaler.clamp(maxScaleFactor: kMaxTextScale),
    ),
    child: child,
  );
}
