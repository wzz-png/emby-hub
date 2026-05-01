import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/emby_repository.dart';
import '../../core/api/models/emby_models.dart';
import '../../core/providers.dart';

/// 收藏页状态
class FavoritesState {
  final bool isLoading;
  final List<MediaItem> favoriteItems;
  final List<MediaItem> favoritePersons;
  final int selectedTab;
  final String? error;

  const FavoritesState({
    this.isLoading = false,
    this.favoriteItems = const [],
    this.favoritePersons = const [],
    this.selectedTab = 0,
    this.error,
  });

  FavoritesState copyWith({
    bool? isLoading,
    List<MediaItem>? favoriteItems,
    List<MediaItem>? favoritePersons,
    int? selectedTab,
    String? error,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      favoriteItems: favoriteItems ?? this.favoriteItems,
      favoritePersons: favoritePersons ?? this.favoritePersons,
      selectedTab: selectedTab ?? this.selectedTab,
      error: error,
    );
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._repo) : super(const FavoritesState());

  final EmbyRepository _repo;

  /// 并行加载收藏影片 + 收藏演员
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.getFavoriteItems(),
        _repo.getFavoritePersons(),
      ]);

      final items = (results[0] as ItemsResult).items;
      final persons = (results[1] as ItemsResult).items;

      state = state.copyWith(
        isLoading: false,
        favoriteItems: items,
        favoritePersons: persons,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  /// 切换 Tab
  void switchTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  /// 下拉刷新
  Future<void> refresh() => loadAll();
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier(ref.watch(embyRepositoryProvider));
});
