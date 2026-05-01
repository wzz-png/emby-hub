import 'package:dio/dio.dart';

import '../emby_client.dart';

/// 认证拦截器
///
/// 自动注入 X-Emby-Authorization 头到每个请求。
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._client);

  final EmbyClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Emby-Authorization'] = _client.authorizationHeader;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token 过期或无效 — 可在此触发重新登录流程
      _client.clearAuth();
    }
    handler.next(err);
  }
}
