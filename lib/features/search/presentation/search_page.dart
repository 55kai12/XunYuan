/// 全局搜索页
/// 跨家族搜索成员，支持姓名、字辈、世代、房支
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_colors.dart';
import '../../person/data/person_repository.dart';
import '../../person/domain/person_providers.dart';
import '../../family/domain/family_providers.dart';

import '../../../core/i18n/i18n.dart';
/// 全局搜索页
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personRepo = ref.watch(personRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索姓名、字辈、世代…'.tr,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey : AppColors.inkGray,
            ),
            border: InputBorder.none,
            suffixIcon: _keyword.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _keyword = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => _keyword = value.trim());
          },
          textInputAction: TextInputAction.search,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _keyword.isEmpty
          ? _buildEmptyHint(isDark)
          : _buildSearchResults(personRepo, isDark),
    );
  }

  /// 空状态提示
  Widget _buildEmptyHint(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: isDark ? Colors.grey : AppColors.inkLightGray,
          ),
          const SizedBox(height: 16),
          Text(
            '输入关键词搜索家族成员'.tr,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey : AppColors.inkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持按姓名、字辈、世代、房支搜索'.tr,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey : AppColors.inkGray,
            ),
          ),
        ],
      ),
    );
  }

  /// 搜索结果列表
  Widget _buildSearchResults(PersonRepository personRepo, bool isDark) {
    return StreamBuilder<List<Person>>(
      stream: personRepo.watchAll(keyword: _keyword),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: isDark ? Colors.grey : AppColors.inkLightGray,
                ),
                const SizedBox(height: 12),
                Text(
                  '未找到「$_keyword」相关成员'.tr,
                  style: TextStyle(
                    color: isDark ? Colors.grey : AppColors.inkGray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          itemBuilder: (context, index) {
            final person = results[index];
            return _SearchResultItem(
              person: person,
              onTap: () => context.push('/person/${person.id}'),
            );
          },
        );
      },
    );
  }
}

/// 搜索结果项
class _SearchResultItem extends ConsumerWidget {
  const _SearchResultItem({
    required this.person,
    required this.onTap,
  });

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final familyAsync = ref.watch(watchFamilyProvider(person.treeId));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.inkGreen.withOpacity(0.1),
        child: Text(
          person.surname.isNotEmpty ? person.surname.substring(0, 1) : '?',
          style: const TextStyle(
            color: AppColors.inkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            '${person.surname}${person.givenName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (person.generationWord != null && person.generationWord!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.inkGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                person.generationWord!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.inkGreen,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            familyAsync.when(
              data: (family) => family?.name ?? '未知家族'.tr,
              loading: () => '加载中…'.tr,
              error: (_, __) => '未知家族'.tr,
            ),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey : AppColors.inkGray,
            ),
          ),
          if (person.generation != null)
            Text(
              '第${person.generation}代${person.branch != null ? " · ${person.branch}" : ""}'.tr,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey : AppColors.inkGray,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
