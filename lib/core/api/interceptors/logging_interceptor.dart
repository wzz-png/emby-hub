import 'package:dio/dio.dart';

/// 日志拦截器（仅 Debug 模式）
class AppLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final uri = options.uri;
    // ignore: avoid_print
    print('[$method] $uri');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode;
    final uri = response.requestOptions.uri;
    // ignore: avoid_print
    print('[RES $statusCode] $uri');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode ?? 'N/A';
    final uri = err.requestOptions.uri;
    // ignore: avoid_print
    print('[ERR $statusCode] $uri: ${err.message}');
    handler.next(err);
  }
}
