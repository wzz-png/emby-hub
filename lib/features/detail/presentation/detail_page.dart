import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_chip.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/media_poster.dart';
import '../../../shared/animations/parallax_delegate.dart';
import '../../../shared/animations/staggered_animation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/api/emby_client.dart';
import '../../../core/api/models/emby_models.dart';
import '../../../core/providers.dart';
import '../../../app/router.dart';
import '../providers.dart';

/// 影片/剧集详情页
class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key, required this.itemId});
  final String itemId;

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(detailProvider.notifier).load(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(detailProvider);
    final client = ref.read(embyClientProvider);

    if (state.isLoading && state.item == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final item = state.item;
    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(state.error ?? '加载失败',
              style: const TextStyle(color: AppColors.onSurfaceMuted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // 视差背景海报
          SliverPersistentHeader(
            pinned: true,
            delegate: ParallaxDelegate(
              maxExtent: 380,
              minExtent: 80,
              builder: (ctx, shrinkOffset, _) {
                final hasBackdrop = item.backdropImageTag != null;
                if (hasBackdrop) {
                  return CachedNetworkImage(
                    imageUrl: client.imageUrl(item.id,
                        imageType: 'Backdrop', maxWidth: 1200),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceDim),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.surface,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  StaggeredAnimation(
                    index: 0,
                    child: Text(item.name,
                        style: Theme.of(context).textTheme.displayLarge),
                  ),
                  const SizedBox(height: 8),

                  // 元数据行
                  StaggeredAnimation(
                    index: 1,
                    child: Row(
                      children: [
                        if (item.productionYear != null)
                          Text('${item.productionYear}',
                              style: Theme.of(context).textTheme.bodySmall),
                        if (item.communityRating != null) ...[
                          const SizedBox(width: 8),
                          const Text('·',
                              style: TextStyle(
                                  color: AppColors.onSurfaceMuted)),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(item.communityRating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (item.runtimeDisplay.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Text('·',
                              style: TextStyle(
                                  color: AppColors.onSurfaceMuted)),
                          const SizedBox(width: 8),
                          Text(item.runtimeDisplay,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (item.officialRating != null) ...[
                          const SizedBox(width: 8),
                          GlassChip(label: item.officialRating!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 类型标签
                  if (item.genres.isNotEmpty)
                    StaggeredAnimation(
                      index: 2,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: item.genres
                            .map((g) => GlassChip(label: g))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 操作按钮
                  StaggeredAnimation(
                    index: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            isPrimary: true,
                            icon: Icons.play_arrow_rounded,
                            onPressed: () => _play(context, item),
                            child:
                                Text(item.hasProgress ? '继续播放' : '播放'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassButton(
                          onPressed: () => ref
                              .read(detailProvider.notifier)
                              .toggleFavorite(),
                          child: Icon(
                            (item.userData?.isFavorite ?? false)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: (item.userData?.isFavorite ?? false)
                                ? AppColors.destructive
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 简介
                  if (item.overview != null) ...[
                    Text('剧情简介',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      item.overview!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color: AppColors.onSurfaceMuted,
                              height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 剧集 — 季选择 + 集列表
                  if (item.isSeries && state.seasons.isNotEmpty) ...[
                    _buildSeasonEpisodes(context, state, client),
                    const SizedBox(height: 24),
                  ],

                  // 演员
                  if (item.people != null &&
                      item.people!.isNotEmpty) ...[
                    Text('演员 & 制作',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.people!.length.clamp(0, 20),
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (ctx, i) {
                          final person = item.people![i];
                          return _buildPersonChip(person, client);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 相似推荐
                  if (state.similarItems.isNotEmpty) ...[
                    Text('相似推荐',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.similarItems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (ctx, i) {
                          final sim = state.similarItems[i];
                          return MediaPoster(
                            imageUrl:
                                client.imageUrl(sim.id, maxWidth: 300),
                            heroTag: 'similar_${sim.id}',
                            title: sim.name,
                            width: 120,
                            height: 180,
                            onTap: () => context.push(
                                '${AppRoutes.detail}/${sim.id}'),
                          );
                        },
                      ),
                    ),
                  ],

                  SizedBox(
                      height:
                          MediaQuery.of(context).padding.bottom + 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonEpisodes(
      BuildContext context, DetailState state, EmbyClient client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              return GlassChip(
                label: state.seasons[i].name,
                isSelected: i == state.selectedSeasonIndex,
                onTap: () =>
                    ref.read(detailProvider.notifier).selectSeason(i),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ...state.episodes.asMap().entries.map((entry) {
          final ep = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildEpisodeTile(context, ep, client),
          );
        }),
      ],
    );
  }

  Widget _buildEpisodeTile(
      BuildContext context, MediaItem ep, EmbyClient client) {
    return GestureDetector(
      onTap: () => context.push('/player/${ep.id}', extra: {
        'title': ep.seriesName ?? ep.name,
        'subtitle': 'S${ep.parentIndexNumber ?? 0}E${ep.indexNumber ?? 0} ${ep.name}',
        'startPositionTicks': ep.userData?.playbackPositionTicks ?? 0,
      }),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12)),
              child: SizedBox(
                width: 130,
                height: 75,
                child: ep.primaryImageTag != null
                    ? CachedNetworkImage(
                        imageUrl: client.imageUrl(ep.id,
                            imageType: 'Primary', maxWidth: 300),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.surfaceContainer,
                        child: const Icon(Icons.play_circle_outline,
                            color: AppColors.onSurfaceMuted),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('第 ${ep.indexNumber ?? '?'} 集',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceMuted)),
                    Text(ep.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (ep.overview != null)
                      Text(ep.overview!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            if (ep.userData?.played ?? false)
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 18),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonChip(PersonInfo person, EmbyClient client) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.person}/${person.id}'),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: 52,
                height: 52,
                child: person.primaryImageTag != null
                    ? CachedNetworkImage(
                        imageUrl: client.imageUrl(person.id,
                            imageType: 'Primary', maxWidth: 120),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.surfaceContainer,
                        child: const Icon(Icons.person,
                            color: AppColors.onSurfaceMuted, size: 24),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(person.name,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
            if (person.role != null)
              Text(person.role!,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.onSurfaceMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _play(BuildContext context, MediaItem item) {
    context.push('/player/${item.id}', extra: {
      'title': item.name,
      'subtitle': item.isSeries ? null : item.runtimeDisplay,
      'startPositionTicks': item.userData?.playbackPositionTicks ?? 0,
    });
  }
}
