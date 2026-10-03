/// 应用路由配置
/// 使用 go_router 管理页面导航
/// - StatefulShellRoute.indexedStack 包裹底部导航四个主 Tab（各分支独立
///   Navigator：双页/转场不再共用同一个 Navigator 的 GlobalKey，且保留
///   各 Tab 的滚动与导航状态）
/// - 家族/成员详情、编辑等全屏页面位于壳路由之外
library;

import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/widgets/expressive_page.dart';
import '../../features/tree/presentation/tree_page.dart';
import '../../features/person/presentation/person_list_page.dart';
import '../../features/person/presentation/person_detail_page.dart';
import '../../features/person/presentation/person_edit_page.dart';
import '../../features/event/presentation/event_timeline_page.dart';
import '../../features/event/presentation/event_edit_page.dart';
import '../../features/backup/presentation/backup_page.dart';
import '../../features/export/presentation/export_center_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/about_page.dart';
import '../../features/family/presentation/family_edit_page.dart';
import '../../features/family/presentation/family_home_page.dart';
import '../../features/relationship/presentation/relationship_edit_page.dart';
import '../../features/relationship/presentation/family_tree_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/media/presentation/media_gallery_page.dart';

/// 创建路由配置
/// [onboardingDone] 为 false 时初始跳转到引导页
GoRouter createRouter(bool onboardingDone) {
  return GoRouter(
    initialLocation: onboardingDone ? AppRoutes.tree : '/onboarding',
    debugLogDiagnostics: false,
    routes: [
    // 主 Tab 壳（底部导航，indexedStack 保留各 Tab 状态）
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(
          currentPath: state.uri.toString(),
          navigationShell: navigationShell,
        );
      },
      branches: [
        // 族谱页（家族列表）
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tree,
              name: 'tree',
              builder: (context, state) => const TreePage(),
            ),
          ],
        ),
        // 成员列表页
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.members,
              name: 'members',
              builder: (context, state) => const PersonListPage(),
            ),
          ],
        ),
        // 时间线页（支持 ?treeId= 预筛选家族）
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.timeline,
              name: 'timeline',
              builder: (context, state) => EventTimelinePage(
                initialTreeId:
                    int.tryParse(state.uri.queryParameters['treeId'] ?? ''),
              ),
            ),
          ],
        ),
        // 我的页
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // ===== 家族路由 =====
    // 创建家族页（全屏）
    GoRoute(
      path: '/family/new',
      name: 'family_new',
      pageBuilder: (context, state) => const ExpressivePage(
        child: FamilyEditPage(),
      ),
    ),

    // 家族首页（全屏）
    GoRoute(
      path: '/family/:id',
      name: 'family_home',
      pageBuilder: (context, state) => ExpressivePage(
        child: FamilyHomePage(
          treeId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),

    // 编辑家族页（全屏）
    GoRoute(
      path: '/family/:id/edit',
      name: 'family_edit',
      pageBuilder: (context, state) => ExpressivePage(
        child: FamilyEditPage(
          editId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),

    // ===== 成员路由 =====
    // 添加成员页（全屏）
    GoRoute(
      path: '/person/new',
      name: 'person_new',
      pageBuilder: (context, state) {
        final treeId = state.uri.queryParameters['treeId'];
        return ExpressivePage(
          child: PersonEditPage(
            initialTreeId: treeId != null ? int.tryParse(treeId) : null,
          ),
        );
      },
    ),

    // 成员详情页（全屏）
    GoRoute(
      path: '/person/:id',
      name: 'person_detail',
      pageBuilder: (context, state) => ExpressivePage(
        child: PersonDetailPage(
          personId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),

    // 编辑成员页（全屏）
    GoRoute(
      path: '/person/:id/edit',
      name: 'person_edit',
      pageBuilder: (context, state) => ExpressivePage(
        child: PersonEditPage(
          editId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),

    // ===== 关系路由 =====
    // 关系编辑页（全屏）
    GoRoute(
      path: '/person/:id/relationships',
      name: 'person_relationships',
      pageBuilder: (context, state) => ExpressivePage(
        child: RelationshipEditPage(
          personId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),

    // 族谱树页（全屏）
    GoRoute(
      path: '/person/:id/tree',
      name: 'person_tree',
      pageBuilder: (context, state) => ExpressivePage(
        child: FamilyTreePage(
          rootPersonId: int.parse(state.pathParameters['id']!),
          // 导出中心深链：带 export=1 进入即自动弹出导出选项
          autoExport: state.uri.queryParameters['export'] == '1',
        ),
      ),
    ),

    // ===== 事件路由 =====
    // 添加事件页（全屏）
    GoRoute(
      path: '/event/new',
      name: 'event_new',
      pageBuilder: (context, state) {
        final personId = state.uri.queryParameters['personId'];
        final treeId = state.uri.queryParameters['treeId'];
        return ExpressivePage(
          child: EventEditPage(
            initialPersonId:
                personId != null ? int.tryParse(personId) : null,
            initialTreeId: treeId != null ? int.tryParse(treeId) : null,
          ),
        );
      },
    ),

    // 编辑事件页（全屏）
    GoRoute(
      path: '/event/:id/edit',
      name: 'event_edit',
      pageBuilder: (context, state) => ExpressivePage(
        child: EventEditPage(
          editId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),

    // ===== 备份路由 =====
    // 备份与恢复页（全屏）
    GoRoute(
      path: '/backup',
      name: 'backup',
      pageBuilder: (context, state) => const ExpressivePage(
        child: BackupPage(),
      ),
    ),

    // ===== 导出路由 =====
    // 导出中心页（全屏）
    GoRoute(
      path: '/export',
      name: 'export',
      pageBuilder: (context, state) => const ExpressivePage(
        child: ExportCenterPage(),
      ),
    ),

    // ===== 关于路由 =====
    // 关于寻渊页（全屏）
    GoRoute(
      path: '/about',
      name: 'about',
      pageBuilder: (context, state) => const ExpressivePage(
        child: AboutPage(),
      ),
    ),

    // ===== 引导页路由 =====
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => const ExpressivePage(
        child: OnboardingPage(),
      ),
    ),

    // ===== 全局搜索路由 =====
    GoRoute(
      path: '/search',
      name: 'search',
      pageBuilder: (context, state) => const ExpressivePage(
        child: SearchPage(),
      ),
    ),

    // ===== 媒体相册路由 =====
    GoRoute(
      path: '/gallery',
      name: 'gallery',
      pageBuilder: (context, state) => const ExpressivePage(
        child: MediaGalleryPage(),
      ),
    ),
  ],
  // 未知路由回退到族谱页
  errorBuilder: (context, state) => const TreePage(),
  );
}
