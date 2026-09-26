/// 媒体模块 Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../family/domain/family_providers.dart';
import '../data/media_repository.dart';

/// 媒体数据仓库 Provider
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(databaseProvider));
});

/// 按家族查询媒体
final mediaByTreeProvider =
    StreamProvider.autoDispose.family<List<MediaTableData>, int>((ref, treeId) {
  return ref.watch(mediaRepositoryProvider).watchMediaByTree(treeId);
});

/// 按成员查询媒体
final mediaByPersonProvider =
    StreamProvider.autoDispose.family<List<MediaTableData>, int>((ref, personId) {
  return ref.watch(mediaRepositoryProvider).watchMediaByPerson(personId);
});
