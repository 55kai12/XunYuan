/// FLAG_SECURE 窗口标记控制
/// 隐私锁开启时禁止系统截图与任务切换器预览（recent apps 显示黑屏）
library;

import 'package:flutter/services.dart';

class SecureWindow {
  SecureWindow._();

  static const MethodChannel _channel = MethodChannel('xunyuan/security');

  /// 设置/清除 FLAG_SECURE。通道不可用时静默（如测试环境）。
  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } on PlatformException catch (_) {
      // 原生侧未实现时忽略
    } on MissingPluginException catch (_) {
      // 非 Android 平台或引擎未就绪时忽略
    }
  }
}
