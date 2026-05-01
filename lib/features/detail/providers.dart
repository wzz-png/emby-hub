import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/emby_repository.dart';
import '../../core/api/models/emby_models.dart';
import '../../core/providers.dart';

/// 详情页状态
class DetailState {
  final bool isLoading;
  final MediaItem? item;
  final List<MediaItem> similarItems;
  final List<SeasonInfo> seasons;
  final List<MediaItem> episodes;
  final int selectedSeasonIndex;
  final String? error;

  const DetailState({
    this.isLoading = false,
    this.item,
    this.similarItems = const [],
    this.seasons = const [],
    this.episodes = const [],
    this.selectedSeasonIndex = 0,
    this.error,
  });

  DetailState copyWith({
    bool? isLoading,
    MediaItem? item,
    List<MediaItem>? similarItems,
    List<SeasonInfo>? seasons,
    List<MediaItem>? episodes,
    int? selectedSeasonIndex,
    String? error,
  }) {
    return DetailState(
      isLoading: isLoading ?? this.isLoading,
      item: item ?? this.item,
      similarItems: similarItems ?? this.similarItems,
      seasons: seasons ?? this.seasons,
      episodes: episodes ?? this.episodes,
      selectedSeasonIndex: selectedSeasonIndex ?? this.selectedSeasonIndex,
      error: error,
    );
  }
}

class DetailNotifier extends StateNotifier<DetailState> {
  DetailNotifier(this._repo) : super(const DetailState());

  final EmbyRepository _repo;

  /// 加载详情
  Future<void> load(String itemId) async {
    state = const DetailState(isLoading: true);
    try {
      final item = await _repo.getItemDetail(itemId);

      // 并行加载相似推荐 + 季（如果是剧集）
      final futures = <Future>[
        _repo.getSimilarItems(itemId),
      ];
      if (item.isSeries) {
        futures.add(_repo.getSeasons(itemId));
      }

      final results = await Future.wait(futures);
      final similar = results[0] as List<MediaItem>;

      List<SeasonInfo> seasons = [];
      List<MediaItem> episodes = [];

      if (item.isSeries && results.length > 1) {
        seasons = results[1] as List<SeasonInfo>;
        if (seasons.isNotEmpty) {
          episodes = await _repo.getEpisodes(
            itemId,
            seasonId: seasons[0].id,
          );
        }
      }

      state = state.copyWith(
        isLoading: false,
        item: item,
        similarItems: similar,
        seasons: seasons,
        episodes: episodes,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  /// 切换季
  Future<void> selectSeason(int index) async {
    if (state.item == null || index == state.selectedSeasonIndex) return;
    final season = state.seasons[index];

    state = state.copyWith(selectedSeasonIndex: index, isLoading: true);
    try {
      final episodes = await _repo.getEpisodes(
        state.item!.id,
        seasonId: season.id,
      );
      state = state.copyWith(isLoading: false, episodes: episodes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  /// 切换收藏
  Future<void> toggleFavorite() async {
    if (state.item == null) return;
    final isFav = state.item!.userData?.isFavorite ?? false;
    try {
      await _repo.toggleFavorite(state.item!.id, isFav);
      // 重新加载详情以更新状态
      await load(state.item!.id);
    } catch (_) {}
  }
}

final detailProvider =
    StateNotifierProvider<DetailNotifier, DetailState>((ref) {
  return DetailNotifier(ref.watch(embyRepositoryProvider));
});
