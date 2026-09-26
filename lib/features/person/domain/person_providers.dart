/// 成员模块 Provider
/// 领域层：通过 Riverpod 暴露数据仓库和响应式数据流
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../data/person_repository.dart';
import '../../family/domain/family_providers.dart';

/// 成员数据仓库 Provider
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(ref.watch(databaseProvider));
});

/// 成员筛选条件（用于列表页状态管理）
class PersonFilter {
  const PersonFilter({
    this.treeId,
    this.keyword,
    this.generationWord,
    this.generation,
    this.branch,
  });

  final int? treeId;
  final String? keyword;
  final String? generationWord;
  final int? generation;
  final String? branch;

  PersonFilter copyWith({
    int? treeId,
    String? keyword,
    String? generationWord,
    int? generation,
    String? branch,
    bool clearKeyword = false,
    bool clearGenerationWord = false,
    bool clearGeneration = false,
    bool clearBranch = false,
  }) {
    return PersonFilter(
      treeId: treeId ?? this.treeId,
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      generationWord: clearGenerationWord
          ? null
          : (generationWord ?? this.generationWord),
      generation: clearGeneration ? null : (generation ?? this.generation),
      branch: clearBranch ? null : (branch ?? this.branch),
    );
  }
}

/// 成员筛选状态 Provider（StateProvider）
final personFilterProvider =
    StateProvider<PersonFilter>((ref) => const PersonFilter());

/// 成员列表数据流 Provider（响应式，跟随筛选条件变化）
final watchPersonsProvider = StreamProvider<List<Person>>((ref) {
  final filter = ref.watch(personFilterProvider);
  return ref.watch(personRepositoryProvider).watchAll(
        treeId: filter.treeId,
        keyword: filter.keyword,
        generationWord: filter.generationWord,
        generation: filter.generation,
        branch: filter.branch,
      );
});

/// 单个成员数据流 Provider
final watchPersonProvider =
    StreamProvider.family<Person?, int>((ref, personId) {
  return ref.watch(personRepositoryProvider).watchById(personId);
});

/// 按家族 ID 查看成员列表 Provider
final watchPersonsByTreeProvider =
    StreamProvider.family<List<Person>, int>((ref, treeId) {
  return ref.watch(personRepositoryProvider).watchAll(treeId: treeId);
});

/// 某家族的世代列表 Provider
final generationsProvider =
    FutureProvider.autoDispose.family<List<int>, int>((ref, treeId) {
  return ref.watch(personRepositoryProvider).getGenerations(treeId);
});

/// 某家族的房支列表 Provider
final branchesProvider =
    FutureProvider.autoDispose.family<List<String>, int>((ref, treeId) {
  return ref.watch(personRepositoryProvider).getBranches(treeId);
});

/// 某家族的字辈列表 Provider
final generationWordsProvider =
    FutureProvider.autoDispose.family<List<String>, int>((ref, treeId) {
  return ref.watch(personRepositoryProvider).getGenerationWords(treeId);
});
