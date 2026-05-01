import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/providers.dart';
import 'router.dart';

/// Emby Hub 根 Widget
class EmbyHubApp extends ConsumerStatefulWidget {
  const EmbyHubApp({super.key});

  @override
  ConsumerState<EmbyHubApp> createState() => _EmbyHubAppState();
}

class _EmbyHubAppState extends ConsumerState<EmbyHubApp> {
  @override
  void initState() {
    super.initState();
    // 启动时尝试恢复登录状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).tryRestoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Emby Hub',
      debugShowCheckedModeBanner: false,

      // 主题
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      // 路由
      routerConfig: appRouter,
    );
  }
}
