import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Emby API 客户端
///
/// 封装 Dio 实现 Emby REST API 通信，处理认证头、
/// 错误映射和请求/响应拦截。
class EmbyClient {
  EmbyClient._();

  static EmbyClient? _instance;
  static EmbyClient get instance => _instance ??= EmbyClient._();

  late Dio _dio;

  String? _serverUrl;
  String? _accessToken;
  String? _userId;

  String? get serverUrl => _serverUrl;
  String? get userId => _userId;
  bool get isAuthenticated => _accessToken != null && _userId != null;

  /// 配置客户端连接到指定服务器
  void configure({
    required String serverUrl,
    String? accessToken,
    String? userId,
  }) {
    _serverUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    _accessToken = accessToken;
    _userId = userId;

    _dio = Dio(BaseOptions(
      baseUrl: '$_serverUrl/emby',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 拦截器链
    _dio.interceptors.addAll([
      AuthInterceptor(this),
      if (kDebugMode) AppLoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  /// 更新访问令牌（登录后调用）
  void setAuth({required String token, required String userId}) {
    _accessToken = token;
    _userId = userId;
  }

  /// 清除认证信息
  void clearAuth() {
    _accessToken = null;
    _userId = null;
  }

  /// 获取 Emby 授权头
  String get authorizationHeader {
    final parts = <String>[
      'MediaBrowser Client="Emby Hub"',
      'Device="${_deviceName}"',
      'DeviceId="flutter_${_deviceId}"',
      'Version="1.0.0"',
    ];
    if (_accessToken != null) {
      parts.add('Token="$_accessToken"');
    }
    return parts.join(', ');
  }

  String get _deviceName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }

  String get _deviceId {
    // 简化版 — 实际应使用 uuid 包生成并持久化
    return '${_deviceName}_emby_hub';
  }

  /// 构建图片 URL
  String imageUrl(
    String itemId, {
    String imageType = 'Primary',
    int? maxWidth,
    int? quality,
    String? tag,
  }) {
    final params = <String, String>{};
    if (maxWidth != null) params['maxWidth'] = maxWidth.toString();
    if (quality != null) params['quality'] = quality.toString();
    if (tag != null) params['tag'] = tag;

    final query =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final base =
        '$_serverUrl/emby${Endpoints.itemImage(itemId, imageType)}';
    return query.isNotEmpty ? '$base?$query' : base;
  }

  // ── HTTP 方法 ───────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
