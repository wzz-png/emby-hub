import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// Emby Hub 根 Widget
class EmbyHubApp extends StatelessWidget {
  const EmbyHubApp({super.key});

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
