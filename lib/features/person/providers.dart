import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/emby_repository.dart';
import '../../core/api/models/emby_models.dart';
import '../../core/providers.dart';

/// 演员详情页状态
class PersonDetailState {
  final bool isLoading;
  final MediaItem? person;
  final List<MediaItem> works;
  final int totalWorksCount;
  final String? error;

  const PersonDetailState({
    this.isLoading = false,
    this.person,
    this.works = const [],
    this.totalWorksCount = 0,
    this.error,
  });

  PersonDetailState copyWith({
    bool? isLoading,
    MediaItem? person,
    List<MediaItem>? works,
    int? totalWorksCount,
    String? error,
  }) {
    return PersonDetailState(
      isLoading: isLoading ?? this.isLoading,
      person: person ?? this.person,
      works: works ?? this.works,
      totalWorksCount: totalWorksCount ?? this.totalWorksCount,
      error: error,
    );
  }
}

class PersonDetailNotifier extends StateNotifier<PersonDetailState> {
  PersonDetailNotifier(this._repo) : super(const PersonDetailState());

  final EmbyRepository _repo;

  /// 加载演员详情 + 参演作品
  Future<void> load(String personId) async {
    state = const PersonDetailState(isLoading: true);
    try {
      final results = await Future.wait([
        _repo.getItemDetail(personId),
        _repo.getPersonWorks(personId),
      ]);

      final person = results[0] as MediaItem;
      final worksResult = results[1] as ItemsResult;

      state = state.copyWith(
        isLoading: false,
        person: person,
        works: worksResult.items,
        totalWorksCount: worksResult.totalRecordCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  /// 切换收藏
  Future<void> toggleFavorite() async {
    if (state.person == null) return;
    final isFav = state.person!.userData?.isFavorite ?? false;
    try {
      await _repo.toggleFavorite(state.person!.id, isFav);
      await load(state.person!.id);
    } catch (_) {}
  }
}

final personDetailProvider =
    StateNotifierProvider<PersonDetailNotifier, PersonDetailState>((ref) {
  return PersonDetailNotifier(ref.watch(embyRepositoryProvider));
});
