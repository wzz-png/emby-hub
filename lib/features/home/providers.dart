import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/emby_repository.dart';
import '../../core/api/models/emby_models.dart';
import '../../core/providers.dart';

/// 首页数据状态
class HomeState {
  final bool isLoading;
  final List<MediaItem> resumeItems;
  final List<MediaItem> nextUpItems;
  final List<MediaItem> latestMovies;
  final List<MediaItem> latestSeries;
  final MediaItem? featuredItem;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.resumeItems = const [],
    this.nextUpItems = const [],
    this.latestMovies = const [],
    this.latestSeries = const [],
    this.featuredItem,
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    List<MediaItem>? resumeItems,
    List<MediaItem>? nextUpItems,
    List<MediaItem>? latestMovies,
    List<MediaItem>? latestSeries,
    MediaItem? featuredItem,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      resumeItems: resumeItems ?? this.resumeItems,
      nextUpItems: nextUpItems ?? this.nextUpItems,
      latestMovies: latestMovies ?? this.latestMovies,
      latestSeries: latestSeries ?? this.latestSeries,
      featuredItem: featuredItem ?? this.featuredItem,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._repo) : super(const HomeState());

  final EmbyRepository _repo;

  /// 加载首页全部数据
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.getResumeItems(),
        _repo.getNextUp(),
        _repo.getLatestItems(includeItemTypes: 'Movie'),
        _repo.getLatestItems(includeItemTypes: 'Series'),
      ]);

      final resume = results[0] as List<MediaItem>;
      final nextUp = results[1] as List<MediaItem>;
      final movies = results[2] as List<MediaItem>;
      final series = results[3] as List<MediaItem>;

      // 选一个有背景图的作为 Featured
      MediaItem? featured;
      for (final item in [...movies, ...series]) {
        if (item.backdropImageTag != null) {
          featured = item;
          break;
        }
      }

      state = state.copyWith(
        isLoading: false,
        resumeItems: resume,
        nextUpItems: nextUp,
        latestMovies: movies,
        latestSeries: series,
        featuredItem: featured,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(embyRepositoryProvider));
});
