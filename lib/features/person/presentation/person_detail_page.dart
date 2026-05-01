import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/media_poster.dart';
import '../../../shared/animations/staggered_animation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/api/emby_client.dart';
import '../../../core/providers.dart';
import '../../../app/router.dart';
import '../providers.dart';

/// 演员详情页
class PersonDetailPage extends ConsumerStatefulWidget {
  const PersonDetailPage({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  bool _overviewExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(personDetailProvider.notifier).load(widget.personId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personDetailProvider);
    final client = ref.watch(embyClientProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: state.isLoading && state.person == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null && state.person == null
              ? _buildError(state.error!)
              : _buildContent(context, state, client),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.onSurfaceMuted, size: 48),
          const SizedBox(height: 12),
          Text(error,
              style: const TextStyle(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GlassButton(
            onPressed: () =>
                ref.read(personDetailProvider.notifier).load(widget.personId),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, PersonDetailState state, EmbyClient client) {
    final person = state.person!;
    final isFav = person.userData?.isFavorite ?? false;

    return CustomScrollView(
      slivers: [
        // 顶部区域：返回按钮 + 头像 + 姓名 + 收藏
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.surface,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    // 返回按钮
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 大圆形头像
                    ClipOval(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: person.primaryImageTag != null
                            ? CachedNetworkImage(
                                imageUrl: client.imageUrl(person.id,
                                    imageType: 'Primary', maxWidth: 300),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.surfaceContainer,
                                child: const Icon(Icons.person,
                                    color: AppColors.onSurfaceMuted, size: 48),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 姓名
                    Text(
                      person.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // 收藏按钮
                    GlassButton(
                      onPressed: () => ref
                          .read(personDetailProvider.notifier)
                          .toggleFavorite(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: isFav ? AppColors.destructive : null,
                          ),
                          const SizedBox(width: 6),
                          Text(isFav ? '已收藏' : '收藏'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 个人简介
        if (person.overview != null && person.overview!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('个人简介',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _overviewExpanded = !_overviewExpanded),
                    child: Text(
                      person.overview!,
                      style: const TextStyle(
                        color: AppColors.onSurfaceMuted,
                        height: 1.6,
                      ),
                      maxLines: _overviewExpanded ? null : 3,
                      overflow: _overviewExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 参演作品标题
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text('参演作品',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                if (state.totalWorksCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.totalWorksCount} 部',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 参演作品网格 或 空状态
        if (state.works.isEmpty && !state.isLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_outlined,
                      color: AppColors.onSurfaceMuted, size: 48),
                  const SizedBox(height: 12),
                  const Text('暂无参演作品',
                      style: TextStyle(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = state.works[index];
                  return StaggeredAnimation(
                    index: index,
                    child: MediaPoster(
                      imageUrl: item.primaryImageTag != null
                          ? client.imageUrl(item.id,
                              imageType: 'Primary', maxWidth: 300)
                          : '',
                      heroTag: 'person_work_${item.id}',
                      title: item.name,
                      subtitle: [
                        if (item.productionYear != null) '${item.productionYear}',
                        if (item.communityRating != null)
                          '★${item.communityRating!.toStringAsFixed(1)}',
                      ].join(' · '),
                      isFavorite: item.userData?.isFavorite ?? false,
                      onTap: () =>
                          context.push('${AppRoutes.detail}/${item.id}'),
                    ),
                  );
                },
                childCount: state.works.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.55,
              ),
            ),
          ),

        // 底部安全区域
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ),
      ],
    );
  }
}
