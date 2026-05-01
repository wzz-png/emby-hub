/// Emby 服务器信息
class ServerInfo {
  final String id;
  final String serverName;
  final String version;
  final String operatingSystem;

  const ServerInfo({
    required this.id,
    required this.serverName,
    required this.version,
    required this.operatingSystem,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      id: json['Id'] as String? ?? '',
      serverName: json['ServerName'] as String? ?? '',
      version: json['Version'] as String? ?? '',
      operatingSystem: json['OperatingSystem'] as String? ?? '',
    );
  }
}

/// Emby 用户
class EmbyUser {
  final String id;
  final String name;
  final String? primaryImageTag;
  final bool hasPassword;

  const EmbyUser({
    required this.id,
    required this.name,
    this.primaryImageTag,
    this.hasPassword = true,
  });

  factory EmbyUser.fromJson(Map<String, dynamic> json) {
    return EmbyUser(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      primaryImageTag: json['PrimaryImageTag'] as String?,
      hasPassword: json['HasPassword'] as bool? ?? true,
    );
  }
}

/// 认证结果
class AuthResult {
  final String accessToken;
  final EmbyUser user;
  final String serverId;

  const AuthResult({
    required this.accessToken,
    required this.user,
    required this.serverId,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['AccessToken'] as String? ?? '',
      user: EmbyUser.fromJson(json['User'] as Map<String, dynamic>),
      serverId: json['ServerId'] as String? ?? '',
    );
  }
}

/// 媒体项（电影/剧集/音乐等）
class MediaItem {
  final String id;
  final String name;
  final String? sortName;
  final String type; // Movie, Series, Episode, Audio, MusicAlbum, etc.
  final String? overview;
  final int? productionYear;
  final String? officialRating; // PG-13, R, etc.
  final double? communityRating;
  final int? criticRating;
  final int? runTimeTicks;
  final String? seriesId;
  final String? seriesName;
  final int? indexNumber; // Episode number
  final int? parentIndexNumber; // Season number
  final String? status; // Continuing, Ended
  final List<String> genres;
  final String? primaryImageTag;
  final String? backdropImageTag;
  final String? logoImageTag;
  final String? thumbImageTag;
  final Map<String, String>? imageBlurHashes;
  final UserItemData? userData;
  final List<MediaStream>? mediaStreams;
  final List<MediaSource>? mediaSources;
  final List<PersonInfo>? people;

  const MediaItem({
    required this.id,
    required this.name,
    this.sortName,
    required this.type,
    this.overview,
    this.productionYear,
    this.officialRating,
    this.communityRating,
    this.criticRating,
    this.runTimeTicks,
    this.seriesId,
    this.seriesName,
    this.indexNumber,
    this.parentIndexNumber,
    this.status,
    this.genres = const [],
    this.primaryImageTag,
    this.backdropImageTag,
    this.logoImageTag,
    this.thumbImageTag,
    this.imageBlurHashes,
    this.userData,
    this.mediaStreams,
    this.mediaSources,
    this.people,
  });

  bool get isMovie => type == 'Movie';
  bool get isSeries => type == 'Series';
  bool get isEpisode => type == 'Episode';
  bool get isAudio => type == 'Audio';
  bool get isMusicAlbum => type == 'MusicAlbum';

  bool get hasProgress =>
      userData != null &&
      userData!.playbackPositionTicks > 0 &&
      runTimeTicks != null &&
      runTimeTicks! > 0;

  double get progressPercent {
    if (!hasProgress) return 0.0;
    return userData!.playbackPositionTicks / runTimeTicks!;
  }

  String get runtimeDisplay {
    if (runTimeTicks == null) return '';
    final minutes = (runTimeTicks! / 600000000).round();
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}min';
    }
    return '${minutes}min';
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      sortName: json['SortName'] as String?,
      type: json['Type'] as String? ?? '',
      overview: json['Overview'] as String?,
      productionYear: json['ProductionYear'] as int?,
      officialRating: json['OfficialRating'] as String?,
      communityRating: (json['CommunityRating'] as num?)?.toDouble(),
      criticRating: json['CriticRating'] as int?,
      runTimeTicks: json['RunTimeTicks'] as int?,
      seriesId: json['SeriesId'] as String?,
      seriesName: json['SeriesName'] as String?,
      indexNumber: json['IndexNumber'] as int?,
      parentIndexNumber: json['ParentIndexNumber'] as int?,
      status: json['Status'] as String?,
      genres: (json['Genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      primaryImageTag: json['ImageTags']?['Primary'] as String?,
      backdropImageTag: (json['BackdropImageTags'] as List?)?.isNotEmpty == true
          ? (json['BackdropImageTags'] as List).first as String
          : null,
      logoImageTag: json['ImageTags']?['Logo'] as String?,
      thumbImageTag: json['ImageTags']?['Thumb'] as String?,
      userData: json['UserData'] != null
          ? UserItemData.fromJson(json['UserData'] as Map<String, dynamic>)
          : null,
      mediaStreams: (json['MediaStreams'] as List<dynamic>?)
          ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaSources: (json['MediaSources'] as List<dynamic>?)
          ?.map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      people: (json['People'] as List<dynamic>?)
          ?.map((e) => PersonInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 用户对媒体项的数据（播放进度、收藏等）
class UserItemData {
  final int playbackPositionTicks;
  final int playCount;
  final bool isFavorite;
  final bool played;

  const UserItemData({
    this.playbackPositionTicks = 0,
    this.playCount = 0,
    this.isFavorite = false,
    this.played = false,
  });

  factory UserItemData.fromJson(Map<String, dynamic> json) {
    return UserItemData(
      playbackPositionTicks: json['PlaybackPositionTicks'] as int? ?? 0,
      playCount: json['PlayCount'] as int? ?? 0,
      isFavorite: json['IsFavorite'] as bool? ?? false,
      played: json['Played'] as bool? ?? false,
    );
  }
}

/// 人物信息（演员/导演）
class PersonInfo {
  final String id;
  final String name;
  final String? role;
  final String type; // Actor, Director, Writer
  final String? primaryImageTag;

  const PersonInfo({
    required this.id,
    required this.name,
    this.role,
    required this.type,
    this.primaryImageTag,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      role: json['Role'] as String?,
      type: json['Type'] as String? ?? '',
      primaryImageTag: json['PrimaryImageTag'] as String?,
    );
  }
}

/// 媒体流（视频/音频/字幕轨道信息）
class MediaStream {
  final String? codec;
  final String type; // Video, Audio, Subtitle
  final String? language;
  final String? displayTitle;
  final int index;
  final int? width;
  final int? height;
  final int? bitRate;
  final int? channels;

  const MediaStream({
    this.codec,
    required this.type,
    this.language,
    this.displayTitle,
    required this.index,
    this.width,
    this.height,
    this.bitRate,
    this.channels,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) {
    return MediaStream(
      codec: json['Codec'] as String?,
      type: json['Type'] as String? ?? '',
      language: json['Language'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      index: json['Index'] as int? ?? 0,
      width: json['Width'] as int?,
      height: json['Height'] as int?,
      bitRate: json['BitRate'] as int?,
      channels: json['Channels'] as int?,
    );
  }
}

/// 媒体源
class MediaSource {
  final String id;
  final String? name;
  final String? container;
  final int? size;
  final int? bitrate;
  final String? directStreamUrl;
  final String? transcodingUrl;
  final bool supportsDirectStream;
  final bool supportsDirectPlay;
  final bool supportsTranscoding;
  final List<MediaStream> mediaStreams;

  const MediaSource({
    required this.id,
    this.name,
    this.container,
    this.size,
    this.bitrate,
    this.directStreamUrl,
    this.transcodingUrl,
    this.supportsDirectStream = false,
    this.supportsDirectPlay = false,
    this.supportsTranscoding = false,
    this.mediaStreams = const [],
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String?,
      container: json['Container'] as String?,
      size: json['Size'] as int?,
      bitrate: json['Bitrate'] as int?,
      directStreamUrl: json['DirectStreamUrl'] as String?,
      transcodingUrl: json['TranscodingUrl'] as String?,
      supportsDirectStream: json['SupportsDirectStream'] as bool? ?? false,
      supportsDirectPlay: json['SupportsDirectPlay'] as bool? ?? false,
      supportsTranscoding: json['SupportsTranscoding'] as bool? ?? false,
      mediaStreams: (json['MediaStreams'] as List<dynamic>?)
              ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 媒体项列表响应
class ItemsResult {
  final List<MediaItem> items;
  final int totalRecordCount;

  const ItemsResult({
    required this.items,
    required this.totalRecordCount,
  });

  factory ItemsResult.fromJson(Map<String, dynamic> json) {
    return ItemsResult(
      items: (json['Items'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRecordCount: json['TotalRecordCount'] as int? ?? 0,
    );
  }
}

/// 播放信息响应
class PlaybackInfoResult {
  final List<MediaSource> mediaSources;

  const PlaybackInfoResult({
    required this.mediaSources,
  });

  factory PlaybackInfoResult.fromJson(Map<String, dynamic> json) {
    return PlaybackInfoResult(
      mediaSources: (json['MediaSources'] as List<dynamic>?)
              ?.map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 季信息
class SeasonInfo {
  final String id;
  final String name;
  final int indexNumber;
  final String? primaryImageTag;

  const SeasonInfo({
    required this.id,
    required this.name,
    required this.indexNumber,
    this.primaryImageTag,
  });

  factory SeasonInfo.fromJson(Map<String, dynamic> json) {
    return SeasonInfo(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      indexNumber: json['IndexNumber'] as int? ?? 0,
      primaryImageTag: json['ImageTags']?['Primary'] as String?,
    );
  }
}
