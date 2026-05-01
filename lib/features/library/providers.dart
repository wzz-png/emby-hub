import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/emby_repository.dart';
import '../../core/api/models/emby_models.dart';
import '../../core/providers.dart';

/// 媒体库状态
class LibraryState {
  final bool isLoading;
  final List<MediaItem> items;
  final int totalCount;
  final int currentPage;
  final String sortBy;
  final String sortOrder;
  final String? genre;
  final String itemType;
  final bool hasMore;
  final String? error;

  const LibraryState({
    this.isLoading = false,
    this.items = const [],
    this.totalCount = 0,
    this.currentPage = 0,
    this.sortBy = 'SortName',
    this.sortOrder = 'Ascending',
    this.genre,
    this.itemType = 'Movie',
    this.hasMore = true,
    this.error,
  });

  LibraryState copyWith({
    bool? isLoading,
    List<MediaItem>? items,
    int? totalCount,
    int? currentPage,
    String? sortBy,
    String? sortOrder,
    String? genre,
    String? itemType,
    bool? hasMore,
    String? error,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      genre: genre ?? this.genre,
      itemType: itemType ?? this.itemType,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._repo) : super(const LibraryState());

  final EmbyRepository _repo;
  static const _pageSize = 50;

  /// 加载首页数据（重置）
  Future<void> load({
    String? itemType,
    String? sortBy,
    String? sortOrder,
    String? genre,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 0,
      items: [],
      itemType: itemType ?? state.itemType,
      sortBy: sortBy ?? state.sortBy,
      sortOrder: sortOrder ?? state.sortOrder,
      genre: genre,
    );

    try {
      final result = await _repo.getItems(
        includeItemTypes: state.itemType,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        genres: state.genre,
        startIndex: 0,
        limit: _pageSize,
      );

      state = state.copyWith(
        isLoading: false,
        items: result.items,
        totalCount: result.totalRecordCount,
        hasMore: result.items.length < result.totalRecordCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  /// 加载更多（翻页）
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;

    try {
      final result = await _repo.getItems(
        includeItemTypes: state.itemType,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        genres: state.genre,
        startIndex: nextPage * _pageSize,
        limit: _pageSize,
      );

      final allItems = [...state.items, ...result.items];
      state = state.copyWith(
        isLoading: false,
        items: allItems,
        currentPage: nextPage,
        hasMore: allItems.length < result.totalRecordCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  /// 切换类型
  void setItemType(String type) {
    load(itemType: type);
  }

  /// 设置排序
  void setSort(String sortBy, String sortOrder) {
    load(sortBy: sortBy, sortOrder: sortOrder);
  }

  /// 设置筛选
  void setGenre(String? genre) {
    load(genre: genre);
  }
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(ref.watch(embyRepositoryProvider));
});
