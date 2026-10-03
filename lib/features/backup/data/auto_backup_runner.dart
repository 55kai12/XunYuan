/// 自动备份触发器
/// App 启动后检查：开关开启且距上次自动备份超过 24 小时则静默执行一次。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';
import '../../family/domain/family_providers.dart';
import '../data/backup_service.dart';

/// 自动备份间隔：24 小时
const Duration _autoBackupInterval = Duration(hours: 24);

/// 每次冷启动最多尝试一次（避免热重建重复触发）
bool _ranThisSession = false;

/// 检查并按需执行自动备份；在 App 根组件首帧后调用一次即可
Future<void> maybeRunAutoBackup(WidgetRef ref) async {
  // 先读开关再打会话标记：旧顺序（先置 _ranThisSession = true 再读开关）
  // 会让「启动时开关是关的、用户进设置打开开关」这一轮被永久跳过，
  // 必须等下次冷启动才生效 —— 用户看到的是「开了没反应」。
  if (!ref.read(autoBackupProvider)) return;
  if (_ranThisSession) return;
  _ranThisSession = true;
  try {
    final service = ref.read(settingsServiceProvider);
    final last = service.lastAutoBackupAt;
    if (last != null && DateTime.now().difference(last) < _autoBackupInterval) {
      return;
    }
    final backupService = BackupService(ref.read(databaseProvider));
    final path = await backupService.runAutoBackup();
    if (path != null) {
      await service.setLastAutoBackupAt(DateTime.now());
      debugPrint('[AutoBackup] saved: $path');
    }
  } catch (e) {
    // 自动备份失败静默，不打扰用户
    debugPrint('[AutoBackup] failed: $e');
  }
}
