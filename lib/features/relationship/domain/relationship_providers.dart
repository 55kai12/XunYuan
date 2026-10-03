/// 关系模块 Provider
/// 领域层：通过 Riverpod 暴露数据仓库和响应式数据流
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../family/domain/family_providers.dart';
import '../data/relationship_repository.dart';

/// 关系数据仓库 Provider
final relationshipRepositoryProvider =
    Provider<RelationshipRepository>((ref) {
  return RelationshipRepository(ref.watch(databaseProvider));
});

/// 监听某人的所有关系
final watchRelationshipsProvider =
    StreamProvider.autoDispose.family<List<Relationship>, int>(
        (ref, personId) {
  return ref
      .watch(relationshipRepositoryProvider)
      .watchRelationshipsForPerson(personId);
});

/// 监听某家族的全部关系（亲属称谓推导用）
final watchRelationshipsByTreeProvider =
    StreamProvider.autoDispose.family<List<Relationship>, int>((ref, treeId) {
  return ref
      .watch(relationshipRepositoryProvider)
      .watchRelationshipsByTree(treeId);
});

/// 获取某人的子女（Future）
final childrenProvider =
    FutureProvider.autoDispose.family<List<Person>, int>((ref, personId) {
  return ref.watch(relationshipRepositoryProvider).getChildren(personId);
});

/// 获取某人的配偶（Future）
final spousesProvider = FutureProvider.autoDispose
    .family<List<({Person person, Relationship rel})>, int>((ref, personId) {
  return ref.watch(relationshipRepositoryProvider).getSpouses(personId);
});

/// 获取某人的父母（Future）
final parentsProvider =
    FutureProvider.autoDispose.family<List<Person>, int>((ref, personId) {
  return ref.watch(relationshipRepositoryProvider).getParents(personId);
});

/// 获取某人的兄弟姐妹（Future）
final siblingsProvider =
    FutureProvider.autoDispose.family<List<Person>, int>((ref, personId) {
  return ref.watch(relationshipRepositoryProvider).getSiblings(personId);
});

/// 构建后代族谱树（Future）
/// 根成员已不存在时为 null，调用方需处理（不要直接 `!`）
final descendantTreeProvider =
    FutureProvider.autoDispose.family<TreeNode?, int>((ref, personId) {
  return ref
      .watch(relationshipRepositoryProvider)
      .buildDescendantTree(rootPersonId: personId);
});
