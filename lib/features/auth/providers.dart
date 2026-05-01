import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  void logout() {
    _client.clearAuth();
    state = const AuthState();
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
