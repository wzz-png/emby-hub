import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_page.dart';
import '../features/library/presentation/library_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/favorites/presentation/favorites_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/detail/presentation/detail_page.dart';
import '../features/person/presentation/person_detail_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/video_player/presentation/video_player_page.dart';
import '../shared/animations/page_transitions.dart';
import 'shell_scaffold.dart';

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/home';
  static const library = '/library';
  static const search = '/search';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const detail = '/detail';
  static const person = '/person';
  static const settings = '/settings';
  static const player = '/player';
}

/// GoRouter 配置
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // 登录页（独立，不在 Shell 内）
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => buildGlassPage(
        key: state.pageKey,
        child: const LoginPage(),
      ),
    ),

    // 视频播放器（独立全屏路由）
    GoRoute(
      path: '${AppRoutes.player}/:id',
      pageBuilder: (context, state) {
        final itemId = state.pathParameters['id'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final title = extra['title'] as String? ?? '';
        final subtitle = extra['subtitle'] as String?;
        final startPositionTicks = extra['startPositionTicks'] as int? ?? 0;
        final mediaSourceId = extra['mediaSourceId'] as String?;

        return buildGlassPage(
          key: state.pageKey,
          child: VideoPlayerPage(
            itemId: itemId,
            title: title,
            subtitle: subtitle,
            startPositionTicks: startPositionTicks,
            mediaSourceId: mediaSourceId,
          ),
        );
      },
    ),

    // 主 Shell — 包含底栏/侧栏的持久化导航
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // 首页
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => buildGlassPage(
                key: state.pageKey,
                child: const HomePage(),
              ),
            ),
          ],
        ),

        // 媒体库
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.library,
              pageBuilder: (context, state) => buildGlassPage(
                key: state.pageKey,
                child: const LibraryPage(),
              ),
            ),
          ],
        ),

        // 搜索
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              pageBuilder: (context, state) => buildGlassPage(
                key: state.pageKey,
                child: const SearchPage(),
              ),
            ),
          ],
        ),

        // 收藏
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              pageBuilder: (context, state) => buildGlassPage(
                key: state.pageKey,
                child: const FavoritesPage(),
              ),
            ),
          ],
        ),

        // 个人
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) => buildGlassPage(
                key: state.pageKey,
                child: const ProfilePage(),
              ),
            ),
          ],
        ),
      ],
    ),

    // 详情页（独立路由，Hero 过渡）
    GoRoute(
      path: '${AppRoutes.detail}/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return buildGlassPage(
          key: state.pageKey,
          child: DetailPage(itemId: id),
        );
      },
    ),

    // 演员详情页
    GoRoute(
      path: '${AppRoutes.person}/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return buildGlassPage(
          key: state.pageKey,
          child: PersonDetailPage(personId: id),
        );
      },
    ),

    // 设置页
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => buildGlassPage(
        key: state.pageKey,
        child: const SettingsPage(),
      ),
    ),
  ],
);
