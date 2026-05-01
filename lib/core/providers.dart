import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/emby_client.dart';
import 'api/emby_repository.dart';
import 'player/player_manager.dart';
import 'player/player_backend.dart';

/// Emby 客户端 Provider
final embyClientProvider = Provider<EmbyClient>((ref) {
  return EmbyClient.instance;
});

/// Emby 仓库 Provider
final embyRepositoryProvider = Provider<EmbyRepository>((ref) {
  return EmbyRepository(ref.watch(embyClientProvider));
});

/// 播放器管理器 Provider
final playerManagerProvider = Provider<PlayerManager>((ref) {
  return PlayerManager.instance;
});

/// 当前播放器内核 Provider
final currentEngineProvider = StateProvider<PlayerEngine>((ref) {
  return PlayerEngine.mpv;
});
