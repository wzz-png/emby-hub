/// 应用全局常量
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const appName = 'Emby Hub';

  /// 应用版本
  static const appVersion = '1.0.0';

  /// 分页大小
  static const pageSize = 50;

  /// 图片缓存大小上限（字节）
  static const imageCacheMaxSize = 500 * 1024 * 1024; // 500 MB

  /// 图片缓存过期天数
  static const imageCacheStaleDays = 7;

  /// 播放进度上报间隔
  static const playbackReportInterval = Duration(seconds: 10);

  /// 搜索防抖延迟
  static const searchDebounceDelay = Duration(milliseconds: 300);

  /// 控件自动隐藏延迟（播放器）
  static const controlsAutoHideDelay = Duration(seconds: 3);

  /// 快进/快退步长
  static const seekStepDuration = Duration(seconds: 10);

  /// 最小桌面窗口尺寸
  static const minWindowWidth = 900.0;
  static const minWindowHeight = 600.0;
}
