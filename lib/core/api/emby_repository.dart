import 'emby_client.dart';
import 'endpoints.dart';
import 'models/emby_models.dart';

/// Emby 数据仓库
///
/// 封装所有 Emby API 调用，返回类型安全的模型对象。
class EmbyRepository {
  EmbyRepository(this._client);

  final EmbyClient _client;

  // ── 认证 ────────────────────────────────────────────

  /// 验证服务器地址，获取服务器信息
  Future<ServerInfo> getServerInfo() async {
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.systemInfoPublic,
    );
    return ServerInfo.fromJson(response.data!);
  }

  /// 获取公开用户列表
  Future<List<EmbyUser>> getPublicUsers() async {
    final response = await _client.get<List<dynamic>>(
      Endpoints.usersPublic,
    );
    return response.data!
        .map((e) => EmbyUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 用户名密码登录
  Future<AuthResult> login(String username, String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      Endpoints.authenticateByName,
      data: {
        'Username': username,
        'Pw': password,
      },
    );
    return AuthResult.fromJson(response.data!);
  }

  // ── 首页数据 ────────────────────────────────────────

  /// 获取用户视图（媒体库列表）
  Future<List<MediaItem>> getUserViews() async {
    final userId = _client.userId!;
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.userViews(userId),
    );
    return ItemsResult.fromJson(response.data!).items;
  }

  /// 获取继续观看
  Future<List<MediaItem>> getResumeItems({int limit = 12}) async {
    final userId = _client.userId!;
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.userItems(userId),
      queryParameters: {
        'Filters': 'IsResumable',
        'SortBy': 'DatePlayed',
        'SortOrder': 'Descending',
        'Recursive': true,
        'IncludeItemTypes': 'Movie,Episode',
        'Limit': limit,
        'Fields': 'Overview,PrimaryImageAspectRatio,BasicSyncInfo',
        'ImageTypeLimit': 1,
        'EnableImageTypes': 'Primary,Backdrop,Thumb',
      },
    );
    return ItemsResult.fromJson(response.data!).items;
  }

  /// 获取下一集
  Future<List<MediaItem>> getNextUp({int limit = 12}) async {
    final userId = _client.userId!;
    final response = await _client.get<Map<String, dynamic>>(
      '/Shows/NextUp',
      queryParameters: {
        'UserId': userId,
        'Limit': limit,
        'Fields': 'Overview,PrimaryImageAspectRatio',
        'ImageTypeLimit': 1,
        'EnableImageTypes': 'Primary,Backdrop,Thumb',
      },
    );
    return ItemsResult.fromJson(response.data!).items;
  }

  /// 获取最新内容
  Future<List<MediaItem>> getLatestItems({
    String? parentId,
    String includeItemTypes = 'Movie',
    int limit = 16,
  }) async {
    final userId = _client.userId!;
    final response = await _client.get<List<dynamic>>(
      Endpoints.userLatestItems(userId),
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        'IncludeItemTypes': includeItemTypes,
        'Limit': limit,
        'Fields': 'Overview,PrimaryImageAspectRatio',
        'ImageTypeLimit': 1,
        'EnableImageTypes': 'Primary,Backdrop,Thumb',
      },
    );
    return response.data!
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 媒体库浏览 ──────────────────────────────────────

  /// 获取媒体列表（分页）
  Future<ItemsResult> getItems({
    String? parentId,
    String? includeItemTypes,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    int startIndex = 0,
    int limit = 50,
    String? genres,
    String? years,
    String? filters,
    String? searchTerm,
    String? personIds,
  }) async {
    final userId = _client.userId!;
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.userItems(userId),
      queryParameters: {
        'Recursive': true,
        'SortBy': sortBy,
        'SortOrder': sortOrder,
        'StartIndex': startIndex,
        'Limit': limit,
        'Fields':
            'Overview,PrimaryImageAspectRatio,Genres,CommunityRating,RunTimeTicks',
        'ImageTypeLimit': 1,
        'EnableImageTypes': 'Primary,Backdrop',
        if (parentId != null) 'ParentId': parentId,
        if (includeItemTypes != null) 'IncludeItemTypes': includeItemTypes,
        if (genres != null) 'Genres': genres,
        if (years != null) 'Years': years,
        if (filters != null) 'Filters': filters,
        if (searchTerm != null) 'SearchTerm': searchTerm,
        if (personIds != null) 'PersonIds': personIds,
      },
    );
    return ItemsResult.fromJson(response.data!);
  }

  // ── 详情 ────────────────────────────────────────────

  /// 获取媒体项详情
  Future<MediaItem> getItemDetail(String itemId) async {
    final userId = _client.userId!;
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.item(userId, itemId),
      queryParameters: {
        'Fields':
            'Overview,Genres,People,Studios,CommunityRating,OfficialRating,'
                'RunTimeTicks,MediaSources,MediaStreams,Chapters',
      },
    );
    return MediaItem.fromJson(response.data!);
  }

  /// 获取相似推荐
  Future<List<MediaItem>> getSimilarItems(String itemId,
      {int limit = 12}) async {
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.similarItems(itemId),
      queryParameters: {
        'Limit': limit,
        'Fields': 'PrimaryImageAspectRatio',
        'UserId': _client.userId,
      },
    );
    return ItemsResult.fromJson(response.data!).items;
  }

  /// 获取剧季列表
  Future<List<SeasonInfo>> getSeasons(String seriesId) async {
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.seasons(seriesId),
      queryParameters: {
        'UserId': _client.userId,
        'Fields': 'BasicSyncInfo',
      },
    );
    return (response.data!['Items'] as List<dynamic>?)
            ?.map((e) => SeasonInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  /// 获取剧集列表
  Future<List<MediaItem>> getEpisodes(
    String seriesId, {
    required String seasonId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      Endpoints.episodes(seriesId),
      queryParameters: {
        'SeasonId': seasonId,
        'UserId': _client.userId,
        'Fields': 'Overview,PrimaryImageAspectRatio,MediaSources',
        'ImageTypeLimit': 1,
        'EnableImageTypes': 'Primary,Thumb',
      },
    );
    return ItemsResult.fromJson(response.data!).items;
  }

  // ── 播放 ────────────────────────────────────────────

  /// 获取播放信息
  Future<PlaybackInfoResult> getPlaybackInfo(String itemId) async {
    final response = await _client.post<Map<String, dynamic>>(
      Endpoints.playbackInfo(itemId),
      queryParameters: {
        'UserId': _client.userId,
      },
      data: {
        'DeviceProfile': _buildDeviceProfile(),
      },
    );
    return PlaybackInfoResult.fromJson(response.data!);
  }

  /// 构建直接播放 URL
  String getDirectStreamUrl(String itemId, String mediaSourceId) {
    final baseUrl = _client.serverUrl;
    final token = _client.authorizationHeader;
    return '$baseUrl/emby${Endpoints.videoStream(itemId)}'
        '?Static=true'
        '&MediaSourceId=$mediaSourceId'
        '&api_key=${Uri.encodeComponent(token)}';
  }

  /// 上报播放开始
  Future<void> reportPlaybackStart(String itemId, {int? positionTicks}) async {
    await _client.post(
      Endpoints.playingStart,
      data: {
        'ItemId': itemId,
        'PlaySessionId': DateTime.now().millisecondsSinceEpoch.toString(),
        if (positionTicks != null) 'PositionTicks': positionTicks,
      },
    );
  }

  /// 上报播放进度
  Future<void> reportPlaybackProgress(
    String itemId, {
    required int positionTicks,
    bool isPaused = false,
  }) async {
    await _client.post(
      Endpoints.playingProgress,
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'IsPaused': isPaused,
      },
    );
  }

  /// 上报播放停止
  Future<void> reportPlaybackStopped(
    String itemId, {
    required int positionTicks,
  }) async {
    await _client.post(
      Endpoints.playingStopped,
      data: {
        'ItemId': itemId,
        'PositionTicks': positionTicks,
      },
    );
  }

  // ── 收藏 ────────────────────────────────────────────

  /// 切换收藏状态
  Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    final userId = _client.userId!;
    if (isFavorite) {
      await _client.delete(Endpoints.removeFavorite(userId, itemId));
    } else {
      await _client.post(Endpoints.addFavorite(userId, itemId));
    }
  }

  // ── 演员 ────────────────────────────────────────────

  /// 获取某演员的参演作品
  Future<ItemsResult> getPersonWorks(String personId,
      {int limit = 50}) {
    return getItems(
      personIds: personId,
      includeItemTypes: 'Movie,Series',
      sortBy: 'PremiereDate',
      sortOrder: 'Descending',
      limit: limit,
    );
  }

  /// 获取用户收藏的影片
  Future<ItemsResult> getFavoriteItems({int limit = 100}) {
    return getItems(
      filters: 'IsFavorite',
      includeItemTypes: 'Movie,Series',
      sortBy: 'SortName',
      limit: limit,
    );
  }

  /// 获取用户收藏的演员
  Future<ItemsResult> getFavoritePersons({int limit = 100}) {
    return getItems(
      filters: 'IsFavorite',
      includeItemTypes: 'Person',
      sortBy: 'SortName',
      limit: limit,
    );
  }

  // ── 搜索 ────────────────────────────────────────────

  /// 搜索媒体
  Future<ItemsResult> search(
    String term, {
    int limit = 20,
    String includeItemTypes =
        'Movie,Series,Episode,Audio,MusicAlbum,Person',
  }) async {
    return getItems(
      searchTerm: term,
      includeItemTypes: includeItemTypes,
      limit: limit,
      sortBy: 'SortName',
    );
  }

  // ── 内部 ────────────────────────────────────────────

  Map<String, dynamic> _buildDeviceProfile() {
    return {
      'MaxStreamingBitrate': 120000000,
      'MaxStaticBitrate': 100000000,
      'MusicStreamingTranscodingBitrate': 384000,
      'DirectPlayProfiles': [
        {
          'Container':
              'mp4,mkv,webm,avi,mov,wmv,m4v,ts,mpegts,flv,rmvb,rm,3gp',
          'Type': 'Video',
        },
        {
          'Container': 'mp3,flac,aac,ogg,wav,wma,m4a,opus,ape,alac',
          'Type': 'Audio',
        },
      ],
      'TranscodingProfiles': [
        {
          'Container': 'ts',
          'Type': 'Video',
          'VideoCodec': 'h264',
          'AudioCodec': 'aac',
          'Protocol': 'hls',
        },
        {
          'Container': 'mp3',
          'Type': 'Audio',
          'AudioCodec': 'mp3',
        },
      ],
    };
  }
}
