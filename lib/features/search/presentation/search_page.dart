import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_chip.dart';
import '../../../shared/widgets/media_poster.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/animations/staggered_animation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/providers.dart';
import '../../../core/api/models/emby_models.dart';
import '../providers.dart';

/// 搜索页面
///
/// 毛玻璃搜索框 + 搜索历史 + 分组结果。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final client = ref.watch(embyClientProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              '搜索',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),

            // 搜索框
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.glassStroke,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.onSurfaceMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: '搜索电影、剧集、音乐...',
                        hintStyle: TextStyle(
                          color: AppColors.onSurfaceMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) {
                        ref.read(searchProvider.notifier).search(value);
                      },
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        ref.read(searchProvider.notifier).search('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.onSurfaceMuted,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 内容区域
            Expanded(
              child: _buildContent(state, client),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_SearchState state, dynamic client) {
    // 正在加载
    if (state.isLoading) {
      return _buildLoadingGrid();
    }

    // 有搜索结果
    if (state.results.isNotEmpty) {
      return _buildResults(state.results, client);
    }

    // 有搜索词但无结果
    if (state.query.trim().isNotEmpty && !state.isLoading) {
      return _buildEmptyResult();
    }

    // 搜索历史 / 空状态
    return _buildIdleState(state);
  }

  Widget _buildIdleState(_SearchState state) {
    if (state.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: AppColors.onSurfaceMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词开始搜索',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
          ],
        ),
      );
    }

    // 搜索历史
    return ListView(
      children: [
        Row(
          children: [
            Text(
              '搜索历史',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                ref.read(searchProvider.notifier).clearHistory();
              },
              child: Text(
                '清除',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.history.map((term) {
            return GlassChip(
              label: term,
              isSelected: false,
              onTap: () {
                _controller.text = term;
                ref.read(searchProvider.notifier).search(term);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults(List<MediaItem> results, dynamic client) {
    // 按类型分组
    final movies = results.where((e) => e.isMovie).toList();
    final series = results.where((e) => e.isSeries).toList();
    final episodes = results.where((e) => e.isEpisode).toList();
    final others =
        results.where((e) => !e.isMovie && !e.isSeries && !e.isEpisode).toList();

    return ListView(
      children: [
        if (movies.isNotEmpty)
          _buildResultSection('电影', movies, client),
        if (series.isNotEmpty)
          _buildResultSection('剧集', series, client),
        if (episodes.isNotEmpty)
          _buildEpisodeSection('单集', episodes, client),
        if (others.isNotEmpty)
          _buildResultSection('其他', others, client),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
      ],
    );
  }

  Widget _buildResultSection(
      String title, List<MediaItem> items, dynamic client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final imageUrl = client.imageUrl(
                item.id,
                imageType: 'Primary',
                maxWidth: 240,
                quality: 90,
                tag: item.primaryImageTag,
              );
              return SizedBox(
                width: 120,
                child: StaggeredAnimation(
                  index: index,
                  child: MediaPoster(
                    imageUrl: imageUrl,
                    heroTag: 'search_${item.id}',
                    title: item.name,
                    subtitle: item.productionYear?.toString(),
                    progress:
                        item.hasProgress ? item.progressPercent : null,
                    onTap: () => context.push('/detail/${item.id}'),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEpisodeSection(
      String title, List<MediaItem> items, dynamic client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
              ),
            ],
          ),
        ),
        ...items.take(10).map((item) {
          final thumbUrl = client.imageUrl(
            item.id,
            imageType: 'Primary',
            maxWidth: 200,
            quality: 85,
            tag: item.primaryImageTag,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: EdgeInsets.zero,
              onTap: () => context.push('/detail/${item.seriesId ?? item.id}'),
              child: Row(
                children: [
                  // 缩略图
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                    child: SizedBox(
                      width: 120,
                      height: 68,
                      child: CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceDim,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceDim,
                          child: const Icon(Icons.movie_outlined,
                              color: AppColors.onSurfaceMuted, size: 20),
                        ),
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
                          Text(
                            item.seriesName ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'S${item.parentIndexNumber ?? 0}E${item.indexNumber ?? 0} ${item.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.hasProgress)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: LinearProgressIndicator(
                                value: item.progressPercent,
                                minHeight: 2,
                                backgroundColor:
                                    Colors.white.withOpacity(0.1),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.onSurfaceMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '未找到相关内容',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试其他关键词吧',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2 / 3,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return StaggeredAnimation(
          index: index,
          child: const PosterShimmer(width: double.infinity),
        );
      },
    );
  }
}

/// 为了类型安全使用 typedef
typedef _SearchState = SearchState;
