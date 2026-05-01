import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:video_player/video_player.dart';

import 'player_backend.dart';
import 'player_state.dart';

/// MDK 播放器后端 (基于 fvp / libmdk)
///
/// 使用 Flutter video_player + fvp 插件，全平台硬解码支持。
/// 在 Web 端自动降级为 HTML5 Video。
class MdkPlayerBackend implements PlayerBackend {
  MdkPlayerBackend() {
    // 注册 fvp 作为 video_player 的底层实现
    fvp.registerWith(options: {
      'video.decoders': ['auto'],
    });
  }

  VideoPlayerController? _controller;
  Timer? _pollTimer;

  @override
  PlayerEngine get engine => PlayerEngine.mdk;

  final _stateController = StreamController<PlayerState>.broadcast();
  @override
  Stream<PlayerState> get stateStream => _stateController.stream;

  PlayerState _state = const PlayerState();
  @override
  PlayerState get state => _state;

  void _update(PlayerState Function(PlayerState) fn) {
    _state = fn(_state);
    _stateController.add(_state);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final c = _controller;
      if (c == null || !c.value.isInitialized) return;

      final v = c.value;
      _update((s) => s.copyWith(
            isPlaying: v.isPlaying,
            isBuffering: v.isBuffering,
            position: v.position,
            duration: v.duration,
            volume: v.volume * 100.0,
            speed: v.playbackSpeed,
            isCompleted: v.isCompleted,
          ));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget buildVideoWidget({Color fill = const Color(0xFF000000)}) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Container(
        color: fill,
        child: const Center(
          child: Text('MDK 初始化中...', style: TextStyle(color: Color(0xB3FFFFFF))),
        ),
      );
    }
    return Container(
      color: fill,
      child: Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: VideoPlayer(c),
        ),
      ),
    );
  }

  @override
  Future<void> open(String url, {Map<String, String>? httpHeaders}) async {
    _update((_) => const PlayerState());
    _stopPolling();

    // 释放旧控制器
    await _controller?.dispose();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: httpHeaders ?? {},
    );
    await _controller!.initialize();
    _startPolling();
    await _controller!.play();
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> playOrPause() async {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
  }

  @override
  Future<void> stop() async {
    _stopPolling();
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
    _update((_) => const PlayerState());
  }

  @override
  Future<void> seek(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _controller?.setVolume((volume / 100.0).clamp(0.0, 1.0));
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed.clamp(0.25, 4.0));
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    // video_player 不直接支持字幕轨道切换
    // fvp 扩展提供了 setSubtitleTracks，但需要通过 FVPControllerExtensions
    final c = _controller;
    if (c == null) return;
    try {
      if (index < 0) {
        c.setSubtitleTracks([]);
      } else {
        c.setSubtitleTracks([index]);
      }
    } catch (_) {
      // 不支持的平台或未初始化
    }
  }

  @override
  Future<void> setAudioTrack(int index) async {
    final c = _controller;
    if (c == null) return;
    try {
      c.setAudioTracks([index]);
    } catch (_) {
      // 不支持的平台或未初始化
    }
  }

  @override
  List<TrackInfo> get subtitleTracks {
    final c = _controller;
    if (c == null) return [];
    try {
      final info = c.getMediaInfo();
      if (info == null) return [];
      // Web 端 MediaInfo 是空 dummy 类，用 dynamic 绕过静态检查
      final dynamic dynInfo = info;
      final List? subs = dynInfo.subtitle as List?;
      if (subs == null || subs.isEmpty) return [];
      return List.generate(subs.length, (i) {
        final dynamic s = subs[i];
        return TrackInfo(
          index: i,
          title: s.codec.codec as String,
          language: s.metadata['language'] as String?,
          codec: s.codec.codec as String,
        );
      });
    } catch (_) {
      return [];
    }
  }

  @override
  List<TrackInfo> get audioTracks {
    final c = _controller;
    if (c == null) return [];
    try {
      final info = c.getMediaInfo();
      if (info == null) return [];
      final dynamic dynInfo = info;
      final List? audios = dynInfo.audio as List?;
      if (audios == null || audios.isEmpty) return [];
      return List.generate(audios.length, (i) {
        final dynamic a = audios[i];
        return TrackInfo(
          index: i,
          title: a.codec.codec as String,
          language: a.metadata['language'] as String?,
          codec: a.codec.codec as String,
        );
      });
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    _stopPolling();
    await _controller?.dispose();
    _controller = null;
    await _stateController.close();
  }
}
