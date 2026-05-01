import 'dart:async';

import 'package:flutter/widgets.dart';

import 'player_backend.dart';
import 'player_state.dart';

/// VLC 播放器后端 — Web 平台 stub
///
/// Web 不支持 VLC，此类仅为保证编译通过。
class VlcPlayerBackend implements PlayerBackend {
  VlcPlayerBackend() {
    throw UnsupportedError('VLC 播放器不支持 Web 平台');
  }

  @override
  PlayerEngine get engine => PlayerEngine.vlc;

  @override
  Stream<PlayerState> get stateStream => const Stream.empty();

  @override
  PlayerState get state => const PlayerState();

  @override
  Widget buildVideoWidget({Color fill = const Color(0xFF000000)}) =>
      const SizedBox.shrink();

  @override
  Future<void> open(String url, {Map<String, String>? httpHeaders}) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> playOrPause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setSubtitleTrack(int index) async {}

  @override
  Future<void> setAudioTrack(int index) async {}

  @override
  List<TrackInfo> get subtitleTracks => [];

  @override
  List<TrackInfo> get audioTracks => [];

  @override
  Future<void> dispose() async {}
}
