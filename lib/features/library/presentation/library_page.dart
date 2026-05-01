import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_chip.dart';
import '../../../shared/widgets/glass_tab_bar.dart';
import '../../../shared/widgets/media_poster.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/animations/staggered_animation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/providers.dart';
import '../providers.dart';

/// 媒体库页面
///
/// 网格浏览媒体内容，支持类型切换、排序和筛选。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final ScrollController _scrollController = ScrollController();
  int _selectedTab = 0;

  static const _tabs = ['电影', '剧集', '音乐', '综艺'];
  static const _tabTypes = ['Movie', 'Series', 'Audio', 'TvChannel'];

  static const _sortOptions = [
    ('SortName', 'Ascending', '名称'),
    ('DateCreated', 'Descending', '最新添加'),
    ('CommunityRating', 'Descending', '评分最高'),
    ('ProductionYear', 'Descending', '年份'),
    ('PremiereDate', 'Descending', '上映日期'),
  ];

  static const _genres = [
    '全部',
    '动作',
    '喜剧',
    '科幻',
    '恐怖',
    '剧情',
    '爱情',
    '动画',
    '纪录片',
    '冒险',
    '悬疑',
    '犯罪',
  ];
  int _selectedGenre = 0;
  int _selectedSort = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 初始加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryProvider.notifier).load(itemType: _tabTypes[0]);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(libraryProvider.notifier).loadMore();
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
      _selectedGenre = 0;
      _selectedSort = 0;
    });
    ref.read(libraryProvider.notifier).load(itemType: _tabTypes[index]);
  }

  void _onGenreChanged(int index) {
    setState(() => _selectedGenre = index);
    final genre = index == 0 ? null : _genres[index];
    ref.read(libraryProvider.notifier).setGenre(genre);
  }

  void _onSortChanged(int index) {
    setState(() => _selectedSort = index);
    final sort = _sortOptions[index];
    ref.read(libraryProvider.notifier).setSort(sort.$1, sort.$2);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final client = ref.watch(embyClientProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainer,
        onRefresh: () => ref.read(libraryProvider.notifier).load(
              itemType: _tabTypes[_selectedTab],
            ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Text(
                      '媒体库',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Spacer(),
                    if (state.totalCount > 0)
                      Text(
                        '${state.totalCount} 项',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                      ),
                  ],
                ),
              ),
            ),

            // Tab 切换
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassTabBar(
                  tabs: _tabs,
                  selectedIndex: _selectedTab,
                  onTap: _onTabChanged,
                ),
              ),
            ),

            // 排序按钮
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: _sortOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedSort;
                    return GestureDetector(
                      onTap: () => _onSortChanged(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.3)
                                : AppColors.glassStroke,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort_rounded,
                              size: 14,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sortOptions[index].$3,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.onSurfaceMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 筛选标签
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _genres.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return GlassChip(
                      label: _genres[index],
                      isSelected: index == _selectedGenre,
                      onTap: () => _onGenreChanged(index),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 错误提示
            if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.destructive, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: const TextStyle(
                              color: AppColors.destructive,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 加载中 shimmer
            if (state.isLoading && state.items.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return StaggeredAnimation(
                        index: index,
                        child: const PosterShimmer(width: double.infinity),
                      );
                    },
                    childCount: 12,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2 / 3,
                  ),
                ),
              ),

            // 空状态
            if (!state.isLoading && state.items.isEmpty && state.error == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.movie_filter_outlined,
                        size: 64,
                        color: AppColors.onSurfaceMuted.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无内容',
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurfaceMuted,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请确认已连接 Emby 服务器',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceMuted,
                                ),
                      ),
                    ],
                  ),
                ),
              ),

            // 媒体网格
            if (state.items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = state.items[index];
                      final imageUrl = client.imageUrl(
                        item.id,
                        imageType: 'Primary',
                        maxWidth: 300,
                        quality: 90,
                        tag: item.primaryImageTag,
                      );

                      return StaggeredAnimation(
                        index: index,
                        child: MediaPoster(
                          imageUrl: imageUrl,
                          heroTag: 'library_${item.id}',
                          title: item.name,
                          subtitle: _buildSubtitle(item),
                          progress: item.hasProgress
                              ? item.progressPercent
                              : null,
                          isFavorite:
                              item.userData?.isFavorite ?? false,
                          onTap: () {
                            context.push('/detail/${item.id}');
                          },
                        ),
                      );
                    },
                    childCount: state.items.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.55,
                  ),
                ),
              ),

            // 加载更多指示器
            if (state.isLoading && state.items.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
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
      ),
    );
  }

  String _buildSubtitle(dynamic item) {
    final parts = <String>[];
    if (item.productionYear != null) parts.add('${item.productionYear}');
    if (item.communityRating != null) {
      parts.add('${item.communityRating.toStringAsFixed(1)}');
    }
    return parts.join(' · ');
  }
}
