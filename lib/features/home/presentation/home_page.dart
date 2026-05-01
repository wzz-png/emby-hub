import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/media_poster.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/animations/staggered_animation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/api/emby_client.dart';
import '../../../core/api/models/emby_models.dart';
import '../../../core/providers.dart';
import '../../../app/router.dart';
import '../../auth/providers.dart';
import '../providers.dart';

/// 首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // 如果已登录，自动加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(isAuthenticatedProvider)) {
        ref.read(homeProvider.notifier).loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final home = ref.watch(homeProvider);
    final isLoggedIn = auth.status == AuthStatus.authenticated;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDim,
      onRefresh: () async {
        if (isLoggedIn) {
          await ref.read(homeProvider.notifier).loadAll();
        }
      },
      child: CustomScrollView(
        slivers: [
          // 顶部 Banner
          SliverToBoxAdapter(
            child: isLoggedIn && home.featuredItem != null
                ? _FeaturedBanner(item: home.featuredItem!)
                : _WelcomeBanner(
                    onConnect: () => context.push(AppRoutes.login),
                  ),
          ),

          // 继续观看
          if (isLoggedIn && home.resumeItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: '继续观看'),
            ),
            SliverToBoxAdapter(
              child: _MediaRow(
                items: home.resumeItems,
                showProgress: true,
              ),
            ),
          ],

          // 下一集
          if (isLoggedIn && home.nextUpItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: '下一集'),
            ),
            SliverToBoxAdapter(
              child: _MediaRow(items: home.nextUpItems),
            ),
          ],

          // 最新电影
          if (isLoggedIn && home.latestMovies.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: '最新电影'),
            ),
            SliverToBoxAdapter(
              child: _MediaRow(items: home.latestMovies),
            ),
          ],

          // 最新剧集
          if (isLoggedIn && home.latestSeries.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: '最新剧集'),
            ),
            SliverToBoxAdapter(
              child: _MediaRow(items: home.latestSeries),
            ),
          ],

          // 加载中骨架屏
          if (isLoggedIn && home.isLoading && home.resumeItems.isEmpty) ...[
            for (final title in ['继续观看', '最新电影', '最新剧集']) ...[
              SliverToBoxAdapter(child: _SectionHeader(title: title)),
              SliverToBoxAdapter(child: _ShimmerRow()),
            ],
          ],

          // 错误提示
          if (home.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.destructive, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          home.error!,
                          style: const TextStyle(
                              color: AppColors.destructive, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 底部安全区域
          SliverToBoxAdapter(
            child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 80),
          ),
        ],
      ),
    );
  }
}

/// 已登录 — 推荐影片大海报 Banner
class _FeaturedBanner extends ConsumerWidget {
  const _FeaturedBanner({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(embyClientProvider);
    final imageUrl = client.imageUrl(item.id,
        imageType: 'Backdrop', maxWidth: 1200, quality: 80);

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.detail}/${item.id}'),
      child: SizedBox(
        height: 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景海报大图
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.surfaceDim,
                child: Center(
                  child: Icon(Icons.movie_rounded,
                      size: 60,
                      color: AppColors.onSurfaceMuted.withOpacity(0.2)),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.surface,
                    ],
                  ),
                ),
              ),
            ),

            // 底部渐变遮罩
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 280,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.surface.withOpacity(0.6),
                      AppColors.surface,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // 信息叠加
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: StaggeredAnimation(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.displayLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.productionYear != null)
                          Text('${item.productionYear}',
                              style: const TextStyle(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 13)),
                        if (item.communityRating != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text('${item.communityRating!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 13)),
                        ],
                        if (item.runtimeDisplay.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(item.runtimeDisplay,
                              style: const TextStyle(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 13)),
                        ],
                      ],
                    ),
                    if (item.overview != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.overview!,
                        style: TextStyle(
                            color: AppColors.onSurfaceMuted.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        GlassButton(
                          isPrimary: true,
                          icon: Icons.play_arrow_rounded,
                          onPressed: () =>
                              context.push('${AppRoutes.detail}/${item.id}'),
                          child: const Text('播放'),
                        ),
                        const SizedBox(width: 10),
                        GlassButton(
                          onPressed: () =>
                              context.push('${AppRoutes.detail}/${item.id}'),
                          child: const Icon(Icons.info_outline_rounded,
                              size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 未登录欢迎 Banner
class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({this.onConnect});
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primaryLight.withOpacity(0.08),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 40,
            right: 24,
            child: StaggeredAnimation(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emby Hub',
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    '连接你的 Emby 服务器，享受精彩内容',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    isPrimary: true,
                    icon: Icons.add_rounded,
                    onPressed: onConnect ?? () {},
                    child: const Text('连接服务器'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 水平媒体行（真实数据）
class _MediaRow extends ConsumerWidget {
  const _MediaRow({required this.items, this.showProgress = false});
  final List<MediaItem> items;
  final bool showProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(embyClientProvider);
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return StaggeredAnimation(
            index: index,
            child: MediaPoster(
              imageUrl: client.imageUrl(item.id, maxWidth: 300, quality: 80),
              heroTag: 'poster_${item.id}',
              title: item.name,
              subtitle: item.productionYear?.toString(),
              progress: showProgress ? item.progressPercent : null,
              isFavorite: item.userData?.isFavorite ?? false,
              width: 120,
              height: 180,
              onTap: () =>
                  context.push('${AppRoutes.detail}/${item.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text('更多',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            StaggeredAnimation(index: i, child: const PosterShimmer(width: 120)),
      ),
    );
  }
}
