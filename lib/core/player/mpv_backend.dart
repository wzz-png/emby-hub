import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import 'player_backend.dart';
import 'player_state.dart';

/// MPV 播放器后端 (media_kit)
///
/// 默认推荐内核，全格式硬解码支持。
class MpvPlayerBackend implements PlayerBackend {
  MpvPlayerBackend() {
    _init();
  }

  late final mk.Player _player;
  late final mkv.VideoController _videoController;
  mk.Player get nativePlayer => _player;

  @override
  PlayerEngine get engine => PlayerEngine.mpv;

  final _stateController = StreamController<PlayerState>.broadcast();
  @override
  Stream<PlayerState> get stateStream => _stateController.stream;

  PlayerState _state = const PlayerState();
  @override
  PlayerState get state => _state;

  final List<StreamSubscription> _subs = [];

  void _init() {
    _player = mk.Player(
      configuration: const mk.PlayerConfiguration(
        bufferSize: 150 * 1024 * 1024,
      ),
    );

    // 创建视频渲染控制器
    _videoController = mkv.VideoController(_player);

    // MPV 原生属性配置（Web 平台不支持）
    if (!kIsWeb && _player.platform is mk.NativePlayer) {
      try {
        // 使用 dynamic 避免 Web 端 stub 类型的编译错误
        final dynamic native = _player.platform;
        native.setProperty('hwdec', 'auto');
        native.setProperty('sub-auto', 'fuzzy');
        native.setProperty('cache', 'yes');
        native.setProperty('demuxer-max-bytes', '150MiB');
        native.setProperty('demuxer-readahead-secs', '60');
      } catch (_) {
        // 不支持原生属性的平台，静默忽略
      }
    }

    _subs.addAll([
      _player.stream.playing.listen((v) {
        _update((s) => s.copyWith(isPlaying: v));
      }),
      _player.stream.buffering.listen((v) {
        _update((s) => s.copyWith(isBuffering: v));
      }),
      _player.stream.position.listen((v) {
        _update((s) => s.copyWith(position: v));
      }),
      _player.stream.duration.listen((v) {
        _update((s) => s.copyWith(duration: v));
      }),
      _player.stream.volume.listen((v) {
        _update((s) => s.copyWith(volume: v));
      }),
      _player.stream.rate.listen((v) {
        _update((s) => s.copyWith(speed: v));
      }),
      _player.stream.completed.listen((v) {
        _update((s) => s.copyWith(isCompleted: v));
      }),
    ]);
  }

  void _update(PlayerState Function(PlayerState) fn) {
    _state = fn(_state);
    _stateController.add(_state);
  }

  @override
  Widget buildVideoWidget({Color fill = const Color(0xFF000000)}) {
    return mkv.Video(
      controller: _videoController,
      fill: fill,
    );
  }

  @override
  Future<void> open(String url, {Map<String, String>? httpHeaders}) async {
    _update((_) => const PlayerState());
    await _player.open(mk.Media(url, httpHeaders: httpHeaders));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _update((_) => const PlayerState());
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 100.0));

  @override
  Future<void> setSpeed(double speed) =>
      _player.setRate(speed.clamp(0.25, 4.0));

  @override
  Future<void> setSubtitleTrack(int index) async {
    final tracks = _player.state.tracks.subtitle;
    if (index < 0 || index >= tracks.length) {
      await _player.setSubtitleTrack(mk.SubtitleTrack.no());
    } else {
      await _player.setSubtitleTrack(tracks[index]);
    }
  }

  @override
  Future<void> setAudioTrack(int index) async {
    final tracks = _player.state.tracks.audio;
    if (index >= 0 && index < tracks.length) {
      await _player.setAudioTrack(tracks[index]);
    }
  }

  @override
  List<TrackInfo> get subtitleTracks {
    return _player.state.tracks.subtitle.map((t) {
      return TrackInfo(
        index: _player.state.tracks.subtitle.indexOf(t),
        title: t.title ?? t.language ?? 'Track ${t.id}',
        language: t.language,
      );
    }).toList();
  }

  @override
  List<TrackInfo> get audioTracks {
    return _player.state.tracks.audio.map((t) {
      return TrackInfo(
        index: _player.state.tracks.audio.indexOf(t),
        title: t.title ?? t.language ?? 'Track ${t.id}',
        language: t.language,
      );
    }).toList();
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _stateController.close();
    await _player.dispose();
  }
}
