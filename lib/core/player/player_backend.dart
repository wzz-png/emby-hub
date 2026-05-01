import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'player_state.dart';

/// 播放器内核类型
enum PlayerEngine {
  /// MPV (media_kit) — 全格式硬解，推荐
  mpv,

  /// MDK (libmdk / fvp) — 全平台硬解码
  mdk,

  /// VLC — 老牌开源播放器
  vlc,
}

extension PlayerEngineExt on PlayerEngine {
  String get displayName {
    switch (this) {
      case PlayerEngine.mpv:
        return 'MPV';
      case PlayerEngine.mdk:
        return 'MDK';
      case PlayerEngine.vlc:
        return 'VLC';
    }
  }

  String get description {
    switch (this) {
      case PlayerEngine.mpv:
        return '全格式硬解码，推荐使用';
      case PlayerEngine.mdk:
        return '全平台硬解码 (libmdk)';
      case PlayerEngine.vlc:
        return '开源播放器，仅限移动端';
    }
  }

  /// 当前平台是否支持该引擎
  bool get isAvailableOnCurrentPlatform {
    switch (this) {
      case PlayerEngine.mpv:
        return true;
      case PlayerEngine.mdk:
        return !kIsWeb;
      case PlayerEngine.vlc:
        return !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
             defaultTargetPlatform == TargetPlatform.android);
    }
  }
}

/// 播放器内核抽象接口
///
/// 所有播放器实现必须遵循此接口，
/// 使得上层 UI 无需关心底层内核差异。
abstract class PlayerBackend {
  /// 内核类型
  PlayerEngine get engine;

  /// 状态流
  Stream<PlayerState> get stateStream;

  /// 当前状态
  PlayerState get state;

  /// 构建视频渲染 Widget
  ///
  /// 各引擎返回自己的原生视频控件，UI 层无需知道底层实现。
  Widget buildVideoWidget({Color fill = const Color(0xFF000000)});

  /// 打开并播放媒体
  Future<void> open(String url, {Map<String, String>? httpHeaders});

  /// 播放
  Future<void> play();

  /// 暂停
  Future<void> pause();

  /// 播放/暂停切换
  Future<void> playOrPause();

  /// 停止
  Future<void> stop();

  /// 跳转到指定位置
  Future<void> seek(Duration position);

  /// 设置音量 (0.0 ~ 100.0)
  Future<void> setVolume(double volume);

  /// 设置播放速度
  Future<void> setSpeed(double speed);

  /// 设置字幕轨道索引 (-1 禁用)
  Future<void> setSubtitleTrack(int index);

  /// 设置音频轨道索引
  Future<void> setAudioTrack(int index);

  /// 获取可用字幕轨道
  List<TrackInfo> get subtitleTracks;

  /// 获取可用音频轨道
  List<TrackInfo> get audioTracks;

  /// 释放资源
  Future<void> dispose();
}

/// 轨道信息
class TrackInfo {
  final int index;
  final String title;
  final String? language;
  final String? codec;

  const TrackInfo({
    required this.index,
    required this.title,
    this.language,
    this.codec,
  });
}
