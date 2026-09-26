/// 事件模块 Provider
/// 领域层：通过 Riverpod 暴露数据仓库和响应式数据流
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../family/domain/family_providers.dart';
import '../data/event_repository.dart';

/// 事件数据仓库 Provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(databaseProvider));
});

/// 监听某家族的事件流
final watchEventsByTreeProvider =
    StreamProvider.autoDispose.family<List<Event>, int>((ref, treeId) {
  return ref.watch(eventRepositoryProvider).watchByTree(treeId);
});

/// 监听某成员的事件流
final watchEventsByPersonProvider =
    StreamProvider.autoDispose.family<List<Event>, int>((ref, personId) {
  return ref.watch(eventRepositoryProvider).watchByPerson(personId);
});

/// 监听单个事件
final watchEventProvider =
    StreamProvider.autoDispose.family<Event?, int>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchById(eventId);
});
