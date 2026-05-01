/// Duration 格式化扩展
extension DurationExtension on Duration {
  /// 格式化为 HH:MM:SS 或 MM:SS
  String toDisplayString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化为人类可读的时长描述
  String toReadableString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}min';
  }
}

/// Emby Ticks 转换扩展
extension EmbyTicksExtension on int {
  /// Emby 使用 10,000,000 ticks/秒
  Duration toEmbyDuration() {
    return Duration(microseconds: this ~/ 10);
  }
}

extension DurationToTicks on Duration {
  /// 转换为 Emby ticks
  int toEmbyTicks() {
    return inMicroseconds * 10;
  }
}
