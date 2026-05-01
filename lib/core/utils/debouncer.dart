import 'dart:async';

/// 防抖器
///
/// 用于搜索输入等场景，在指定延迟后执行回调。
class Debouncer {
  Debouncer({required this.delay});

  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
