import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/emby_repository.dart';
import '../../core/api/models/emby_models.dart';
import '../../core/providers.dart';
import '../../core/utils/debouncer.dart';

/// 搜索状态
class SearchState {
  final bool isLoading;
  final String query;
  final List<MediaItem> results;
  final List<String> history;
  final String? error;

  const SearchState({
    this.isLoading = false,
    this.query = '',
    this.results = const [],
    this.history = const [],
    this.error,
  });

  SearchState copyWith({
    bool? isLoading,
    String? query,
    List<MediaItem>? results,
    List<String>? history,
    String? error,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      results: results ?? this.results,
      history: history ?? this.history,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._repo) : super(const SearchState());

  final EmbyRepository _repo;
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  /// 搜索（带防抖）
  void search(String query) {
    state = state.copyWith(query: query);

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    _debouncer.call(() => _doSearch(query.trim()));
  }

  Future<void> _doSearch(String term) async {
    try {
      final result = await _repo.search(term);
      // 如果搜索词已经变化，忽略结果
      if (state.query.trim() != term) return;

      state = state.copyWith(
        isLoading: false,
        results: result.items,
      );

      // 添加到搜索历史
      if (result.items.isNotEmpty) {
        _addToHistory(term);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  void _addToHistory(String term) {
    final history = [...state.history];
    history.remove(term);
    history.insert(0, term);
    if (history.length > 20) history.removeLast();
    state = state.copyWith(history: history);
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(embyRepositoryProvider));
});
