/// 统一播放状态模型
class PlayerState {
  const PlayerState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.speed = 1.0,
    this.isCompleted = false,
    this.currentMediaId,
    this.playlist = const [],
    this.currentIndex = 0,
  });

  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final bool isCompleted;
  final String? currentMediaId;
  final List<String> playlist;
  final int currentIndex;

  double get progress =>
      duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;

  PlayerState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    bool? isCompleted,
    String? currentMediaId,
    List<String>? playlist,
    int? currentIndex,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      isCompleted: isCompleted ?? this.isCompleted,
      currentMediaId: currentMediaId ?? this.currentMediaId,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
