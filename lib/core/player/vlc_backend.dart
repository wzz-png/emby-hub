import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'player_backend.dart';
import 'player_state.dart';
import 'mpv_backend.dart';

/// VLC 播放器后端 (flutter_vlc_player)
///
/// 仅支持 iOS / Android。桌面平台自动降级到 MPV。
class VlcPlayerBackend implements PlayerBackend {
  VlcPlayerBackend() {
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (isDesktop) {
      _fallback = MpvPlayerBackend();
    }
  }

  MpvPlayerBackend? _fallback;
  bool get _isFallback => _fallback != null;

  VlcPlayerController? _controller;
  Timer? _pollTimer;

  @override
  PlayerEngine get engine => PlayerEngine.vlc;

  final _stateController = StreamController<PlayerState>.broadcast();
  @override
  Stream<PlayerState> get stateStream =>
      _isFallback ? _fallback!.stateStream : _stateController.stream;

  PlayerState _state = const PlayerState();
  @override
  PlayerState get state => _isFallback ? _fallback!.state : _state;

  void _update(PlayerState Function(PlayerState) fn) {
    _state = fn(_state);
    _stateController.add(_state);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final c = _controller;
      if (c == null) return;
      final v = c.value;
      _update((s) => s.copyWith(
            isPlaying: v.isPlaying,
            isBuffering: v.isBuffering,
            position: v.position,
            duration: v.duration,
            volume: v.volume.toDouble(),
            speed: v.playbackSpeed,
            isCompleted: v.playingState == PlayingState.ended,
          ));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget buildVideoWidget({Color fill = const Color(0xFF000000)}) {
    if (_isFallback) return _fallback!.buildVideoWidget(fill: fill);

    final c = _controller;
    if (c == null) {
      return Container(
        color: fill,
        child: const Center(
          child: Text('VLC 初始化中...', style: TextStyle(color: Color(0xB3FFFFFF))),
        ),
      );
    }
    return Container(
      color: fill,
      child: Center(
        child: VlcPlayer(
          controller: c,
          aspectRatio: 16 / 9,
          placeholder: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> open(String url, {Map<String, String>? httpHeaders}) async {
    if (_isFallback) return _fallback!.open(url, httpHeaders: httpHeaders);

    _update((_) => const PlayerState());
    _stopPolling();

    // VlcPlayerController 是按 URL 创建的，需要释放旧的
    await _disposeController();

    _controller = VlcPlayerController.network(
      url,
      hwAcc: HwAcc.auto,
      autoPlay: true,
      options: VlcPlayerOptions(
        http: VlcHttpOptions([
          if (httpHeaders != null)
            ...httpHeaders.entries.map((e) => ':http-header=${e.key}: ${e.value}'),
        ]),
      ),
    );

    _controller!.addOnInitListener(() async {
      _startPolling();
    });
  }

  Future<void> _disposeController() async {
    _stopPolling();
    try {
      await _controller?.stopRendererScanning();
    } catch (_) {}
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }

  @override
  Future<void> play() async {
    if (_isFallback) return _fallback!.play();
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    if (_isFallback) return _fallback!.pause();
    await _controller?.pause();
  }

  @override
  Future<void> playOrPause() async {
    if (_isFallback) return _fallback!.playOrPause();
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
    if (_isFallback) return _fallback!.stop();
    _stopPolling();
    await _controller?.stop();
    _update((_) => const PlayerState());
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isFallback) return _fallback!.seek(position);
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isFallback) return _fallback!.setVolume(volume);
    await _controller?.setVolume(volume.clamp(0.0, 100.0).toInt());
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isFallback) return _fallback!.setSpeed(speed);
    await _controller?.setPlaybackSpeed(speed.clamp(0.25, 4.0));
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    if (_isFallback) return _fallback!.setSubtitleTrack(index);
    final c = _controller;
    if (c == null) return;
    if (index < 0) {
      await c.setSpuTrack(-1);
    } else {
      final spuTracks = await c.getSpuTracks();
      final keys = spuTracks.keys.toList();
      if (index < keys.length) {
        await c.setSpuTrack(keys[index]);
      }
    }
  }

  @override
  Future<void> setAudioTrack(int index) async {
    if (_isFallback) return _fallback!.setAudioTrack(index);
    final c = _controller;
    if (c == null) return;
    final audioTracks = await c.getAudioTracks();
    final keys = audioTracks.keys.toList();
    if (index >= 0 && index < keys.length) {
      await c.setAudioTrack(keys[index]);
    }
  }

  @override
  List<TrackInfo> get subtitleTracks {
    if (_isFallback) return _fallback!.subtitleTracks;
    // VLC getSpuTracks 是异步的，这里返回缓存或空列表
    return [];
  }

  @override
  List<TrackInfo> get audioTracks {
    if (_isFallback) return _fallback!.audioTracks;
    return [];
  }

  @override
  Future<void> dispose() async {
    if (_isFallback) return _fallback!.dispose();
    await _disposeController();
    await _stateController.close();
  }
}
