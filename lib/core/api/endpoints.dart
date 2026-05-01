/// Emby API 端点常量
class Endpoints {
  Endpoints._();

  // ── 认证 ────────────────────────────────────────────

  /// 服务器公开信息（无需认证）
  static const systemInfoPublic = '/System/Info/Public';

  /// 公开用户列表（头像选择）
  static const usersPublic = '/Users/Public';

  /// 用户名密码登录
  static const authenticateByName = '/Users/AuthenticateByName';

  // ── 用户 ────────────────────────────────────────────

  /// 用户信息
  static String user(String userId) => '/Users/$userId';

  /// 用户视图（媒体库列表）
  static String userViews(String userId) => '/Users/$userId/Views';

  /// 用户媒体项列表
  static String userItems(String userId) => '/Users/$userId/Items';

  /// 最新内容
  static String userLatestItems(String userId) =>
      '/Users/$userId/Items/Latest';

  // ── 媒体 ────────────────────────────────────────────

  /// 单个媒体项详情
  static String item(String userId, String itemId) =>
      '/Users/$userId/Items/$itemId';

  /// 相似推荐
  static String similarItems(String itemId) => '/Items/$itemId/Similar';

  /// 媒体项图片
  static String itemImage(String itemId, String imageType) =>
      '/Items/$itemId/Images/$imageType';

  // ── 剧集 ────────────────────────────────────────────

  /// 下一集
  static String nextUp(String userId) => '/Shows/NextUp';

  /// 季列表
  static String seasons(String seriesId) => '/Shows/$seriesId/Seasons';

  /// 集列表
  static String episodes(String seriesId) => '/Shows/$seriesId/Episodes';

  // ── 播放 ────────────────────────────────────────────

  /// 获取播放信息（媒体源 URL）
  static String playbackInfo(String itemId) => '/Items/$itemId/PlaybackInfo';

  /// 视频流（直接播放）
  static String videoStream(String itemId) => '/Videos/$itemId/stream';

  /// 上报播放开始
  static const playingStart = '/Sessions/Playing';

  /// 上报播放进度
  static const playingProgress = '/Sessions/Playing/Progress';

  /// 上报播放停止
  static const playingStopped = '/Sessions/Playing/Stopped';

  // ── 搜索 ────────────────────────────────────────────

  /// 搜索（通过 userItems + searchTerm 参数实现）

  // ── 收藏 ────────────────────────────────────────────

  /// 添加收藏
  static String addFavorite(String userId, String itemId) =>
      '/Users/$userId/FavoriteItems/$itemId';

  /// 取消收藏
  static String removeFavorite(String userId, String itemId) =>
      '/Users/$userId/FavoriteItems/$itemId';

  // ── 直播 ────────────────────────────────────────────

  static const liveTvChannels = '/LiveTv/Channels';
  static const liveTvPrograms = '/LiveTv/Programs';
}
