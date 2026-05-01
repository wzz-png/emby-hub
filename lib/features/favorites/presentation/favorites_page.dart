import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_tab_bar.dart';
import '../../../shared/widgets/media_poster.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/animations/staggered_animation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/api/emby_client.dart';
import '../../../core/api/models/emby_models.dart';
import '../../../core/providers.dart';
import '../../../app/router.dart';
import '../providers.dart';

/// 收藏页面（底部导航 Tab）
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);
    final client = ref.watch(embyClientProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(favoritesProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // 标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text('收藏',
                    style: Theme.of(context).textTheme.displayMedium),
              ),
            ),

            // Tab 切换
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassTabBar(
                  tabs: const ['收藏影片', '收藏演员'],
                  selectedIndex: state.selectedTab,
                  onTap: (i) =>
                      ref.read(favoritesProvider.notifier).switchTab(i),
                ),
              ),
            ),

            // 加载骨架屏
            if (state.isLoading &&
                state.favoriteItems.isEmpty &&
                state.favoritePersons.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const PosterShimmer(),
                    childCount: 6,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.55,
                  ),
                ),
              )

            // 错误状态
            else if (state.error != null &&
                state.favoriteItems.isEmpty &&
                state.favoritePersons.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.onSurfaceMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(state.error!,
                          style: const TextStyle(
                              color: AppColors.onSurfaceMuted),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )

            // Tab 0: 收藏影片
            else if (state.selectedTab == 0)
              ..._buildFavoriteItemsSliver(state, client)

            // Tab 1: 收藏演员
            else
              ..._buildFavoritePersonsSliver(state, client),

            // 底部安全区域
            SliverToBoxAdapter(
              child:
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFavoriteItemsSliver(
      FavoritesState state, EmbyClient client) {
    if (state.favoriteItems.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border,
                    color: AppColors.onSurfaceMuted, size: 48),
                const SizedBox(height: 12),
                const Text('还没有收藏的影片',
                    style: TextStyle(color: AppColors.onSurfaceMuted)),
                const SizedBox(height: 4),
                const Text('在影片详情页点击爱心即可收藏',
                    style: TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = state.favoriteItems[index];
              return StaggeredAnimation(
                index: index,
                child: MediaPoster(
                  imageUrl: item.primaryImageTag != null
                      ? client.imageUrl(item.id,
                          imageType: 'Primary', maxWidth: 300)
                      : '',
                  heroTag: 'fav_${item.id}',
                  title: item.name,
                  subtitle: [
                    if (item.productionYear != null) '${item.productionYear}',
                    if (item.communityRating != null)
                      '★${item.communityRating!.toStringAsFixed(1)}',
                  ].join(' · '),
                  isFavorite: true,
                  progress: item.progressPercent > 0
                      ? item.progressPercent
                      : null,
                  onTap: () =>
                      context.push('${AppRoutes.detail}/${item.id}'),
                ),
              );
            },
            childCount: state.favoriteItems.length,
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.55,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildFavoritePersonsSliver(
      FavoritesState state, EmbyClient client) {
    if (state.favoritePersons.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline,
                    color: AppColors.onSurfaceMuted, size: 48),
                const SizedBox(height: 12),
                const Text('还没有收藏的演员',
                    style: TextStyle(color: AppColors.onSurfaceMuted)),
                const SizedBox(height: 4),
                const Text('在演员详情页点击爱心即可收藏',
                    style: TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final person = state.favoritePersons[index];
              return StaggeredAnimation(
                index: index,
                child: _PersonCard(
                  person: person,
                  client: client,
                  onTap: () =>
                      context.push('${AppRoutes.person}/${person.id}'),
                ),
              );
            },
            childCount: state.favoritePersons.length,
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
        ),
      ),
    ];
  }
}

/// 收藏演员卡片
class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.client,
    this.onTap,
  });

  final MediaItem person;
  final EmbyClient client;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(
                child: person.primaryImageTag != null
                    ? CachedNetworkImage(
                        imageUrl: client.imageUrl(person.id,
                            imageType: 'Primary', maxWidth: 200),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.surfaceContainer,
                        child: const Icon(Icons.person,
                            color: AppColors.onSurfaceMuted, size: 36),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            person.name,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
