/// 备份模块 Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../family/domain/family_providers.dart';
import '../data/backup_service.dart';

/// 备份服务 Provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
