import 'package:dio/dio.dart';

/// 错误拦截器
///
/// 将 DioException 映射为应用级别的错误类型。
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _mapToAppException(err);
    handler.next(appException);
  }

  DioException _mapToAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: err.requestOptions,
          error: '连接超时，请检查网络和服务器地址',
          type: err.type,
          response: err.response,
        );

      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: err.requestOptions,
          error: '无法连接到服务器',
          type: err.type,
          response: err.response,
        );

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        String message;
        switch (statusCode) {
          case 401:
            message = '认证失败，请重新登录';
            break;
          case 403:
            message = '权限不足';
            break;
          case 404:
            message = '资源不存在';
            break;
          case 500:
            message = '服务器内部错误';
            break;
          default:
            message = '请求失败 ($statusCode)';
        }
        return DioException(
          requestOptions: err.requestOptions,
          error: message,
          type: err.type,
          response: err.response,
        );

      default:
        return err;
    }
  }
}
