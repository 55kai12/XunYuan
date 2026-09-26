/// 家族模块 Provider
/// 领域层：通过 Riverpod 暴露数据仓库和响应式数据流
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../data/family_repository.dart';
import '../../person/domain/person_providers.dart';

/// 数据库 Provider（全局单例）
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // 应用退出时关闭数据库
  ref.onDispose(db.close);
  return db;
});

/// 家族数据仓库 Provider
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(databaseProvider));
});

/// 家族列表数据流 Provider（响应式监听）
final watchFamiliesProvider = StreamProvider<List<FamilyTree>>((ref) {
  return ref.watch(familyRepositoryProvider).watchAll();
});

/// 单个家族数据流 Provider
/// 参数：家族 ID
final watchFamilyProvider =
    StreamProvider.family<FamilyTree?, int>((ref, treeId) {
  return ref.watch(familyRepositoryProvider).watchFamily(treeId);
});

/// 家族统计信息
class FamilyStats {
  const FamilyStats({
    required this.total,
    required this.alive,
    required this.genderMap,
    required this.generationCount,
  });

  /// 成员总数
  final int total;

  /// 在世人数
  final int alive;

  /// 已故人数
  int get deceased => total - alive;

  /// 性别分布
  final Map<Gender, int> genderMap;

  /// 男性人数
  int get maleCount => genderMap[Gender.male] ?? 0;

  /// 女性人数
  int get femaleCount => genderMap[Gender.female] ?? 0;

  /// 世代数
  final int generationCount;
}

/// 家族统计 Provider（按家族 ID 缓存）
final familyStatsProvider =
    FutureProvider.autoDispose.family<FamilyStats, int>((ref, treeId) async {
  final repo = ref.watch(familyRepositoryProvider);
  final personRepo = ref.watch(personRepositoryProvider);
  final total = await repo.countMembers(treeId);
  final alive = await repo.countAlive(treeId);
  final genderMap = await repo.countByGender(treeId);
  final generations = await personRepo.getGenerations(treeId);
  return FamilyStats(
    total: total,
    alive: alive,
    genderMap: genderMap,
    generationCount: generations.length,
  );
});
