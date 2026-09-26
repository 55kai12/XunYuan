/// 导出模块 Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../family/domain/family_providers.dart';
import '../data/export_service.dart';

/// 导出服务 Provider
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(databaseProvider));
});
