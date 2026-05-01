import 'dart:async';

import 'player_backend.dart';
import 'player_state.dart';
import 'mpv_backend.dart';
import 'mdk_backend.dart';
import 'vlc_backend_stub.dart'
    if (dart.library.io) 'vlc_backend.dart';

/// 统一播放器管理器
///
/// 管理当前活跃的播放器后端，支持运行时切换内核。
/// 应用层通过此类与播放器交互，无需关心底层实现。
class PlayerManager {
  PlayerManager._();

  static final instance = PlayerManager._();

  PlayerBackend? _backend;
  PlayerEngine _currentEngine = PlayerEngine.mpv;

  /// 当前播放器后端
  PlayerBackend get backend {
    _backend ??= _createBackend(_currentEngine);
    return _backend!;
  }

  /// 当前内核类型
  PlayerEngine get currentEngine => _currentEngine;

  /// 状态流（代理当前后端）
  Stream<PlayerState> get stateStream => backend.stateStream;

  /// 当前状态
  PlayerState get state => backend.state;

  /// 切换播放器内核
  ///
  /// 会停止当前播放并释放旧后端资源。
  Future<void> switchEngine(PlayerEngine engine) async {
    if (engine == _currentEngine && _backend != null) return;

    // 停止并释放旧后端
    if (_backend != null) {
      await _backend!.stop();
      await _backend!.dispose();
      _backend = null;
    }

    _currentEngine = engine;
    _backend = _createBackend(engine);
  }

  /// 创建播放器后端实例
  PlayerBackend _createBackend(PlayerEngine engine) {
    switch (engine) {
      case PlayerEngine.mpv:
        return MpvPlayerBackend();
      case PlayerEngine.mdk:
        return MdkPlayerBackend();
      case PlayerEngine.vlc:
        try {
          return VlcPlayerBackend();
        } catch (_) {
          // 不支持的平台降级到 MPV
          return MpvPlayerBackend();
        }
    }
  }

  // ── 播放控制代理 ──────────────────────────────────

  Future<void> open(String url, {Map<String, String>? httpHeaders}) =>
      backend.open(url, httpHeaders: httpHeaders);

  Future<void> play() => backend.play();
  Future<void> pause() => backend.pause();
  Future<void> playOrPause() => backend.playOrPause();
  Future<void> stop() => backend.stop();
  Future<void> seek(Duration position) => backend.seek(position);

  Future<void> seekRelative(Duration offset) async {
    final target = state.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > state.duration ? state.duration : target);
    await seek(clamped);
  }

  Future<void> setVolume(double volume) => backend.setVolume(volume);
  Future<void> setSpeed(double speed) => backend.setSpeed(speed);
  Future<void> setSubtitleTrack(int index) => backend.setSubtitleTrack(index);
  Future<void> setAudioTrack(int index) => backend.setAudioTrack(index);

  List<TrackInfo> get subtitleTracks => backend.subtitleTracks;
  List<TrackInfo> get audioTracks => backend.audioTracks;

  /// 释放所有资源
  Future<void> dispose() async {
    await _backend?.dispose();
    _backend = null;
  }
}
