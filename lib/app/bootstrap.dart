import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import 'desktop_window_stub.dart'
    if (dart.library.io) 'desktop_window.dart';

/// 应用引导初始化
///
/// 在 runApp() 之前调用，完成所有平台相关的初始化工作。
class Bootstrap {
  Bootstrap._();

  static Future<void> init() async {
    // media_kit (MPV) 初始化
    MediaKit.ensureInitialized();

    // 桌面端窗口管理
    if (_isDesktop) {
      await initDesktopWindow();
    }
  }

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.linux);
}
