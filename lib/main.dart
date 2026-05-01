import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // 启用边到边显示
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 平台初始化
  await Bootstrap.init();

  runApp(
    const ProviderScope(
      child: EmbyHubApp(),
    ),
  );
}
