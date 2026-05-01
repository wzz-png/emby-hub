import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/emby_client.dart';
import '../../core/api/emby_repository.dart';
import '../../core/api/models/emby_models.dart';
import '../../core/providers.dart';

/// 认证状态
enum AuthStatus { initial, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final EmbyUser? user;
  final ServerInfo? serverInfo;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.serverInfo,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    EmbyUser? user,
    ServerInfo? serverInfo,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      serverInfo: serverInfo ?? this.serverInfo,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._client, this._repo) : super(const AuthState());

  final EmbyClient _client;
  final EmbyRepository _repo;

  static const _storage = FlutterSecureStorage();
  static const _keyServerUrl = 'emby_server_url';
  static const _keyAccessToken = 'emby_access_token';
  static const _keyUserId = 'emby_user_id';

  /// 启动时尝试恢复登录状态
  Future<void> tryRestoreSession() async {
    try {
      final serverUrl = await _storage.read(key: _keyServerUrl);
      final accessToken = await _storage.read(key: _keyAccessToken);
      final userId = await _storage.read(key: _keyUserId);

      if (serverUrl == null || accessToken == null || userId == null) return;

      // 配置客户端
      _client.configure(
        serverUrl: serverUrl,
        accessToken: accessToken,
        userId: userId,
      );

      // 验证 token 是否仍有效
      state = state.copyWith(status: AuthStatus.loading);
      final serverInfo = await _repo.getServerInfo();

      // 获取用户信息
      EmbyUser? user;
      try {
        final publicUsers = await _repo.getPublicUsers();
        user = publicUsers.where((u) => u.id == userId).firstOrNull;
      } catch (_) {}

      state = state.copyWith(
        status: AuthStatus.authenticated,
        serverInfo: serverInfo,
        user: user,
      );
    } catch (_) {
      // token 过期或服务器不可达，清除存储
      await _clearStorage();
      _client.clearAuth();
      state = const AuthState();
    }
  }

  /// 连接服务器
  Future<bool> connectServer(String url) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      _client.configure(serverUrl: url);
      final serverInfo = await _repo.getServerInfo();
      state = state.copyWith(
        status: AuthStatus.initial,
        serverInfo: serverInfo,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: '无法连接到服务器: $e',
      );
      return false;
    }
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final result = await _repo.login(username, password);
      _client.setAuth(token: result.accessToken, userId: result.user.id);

      // 持久化凭据
      await _storage.write(key: _keyServerUrl, value: _client.serverUrl);
      await _storage.write(key: _keyAccessToken, value: result.accessToken);
      await _storage.write(key: _keyUserId, value: result.user.id);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: '登录失败: $e',
      );
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    _client.clearAuth();
    await _clearStorage();
    state = const AuthState();
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _keyServerUrl);
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyUserId);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(embyClientProvider),
    ref.watch(embyRepositoryProvider),
  );
});

/// 是否已认证
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});
