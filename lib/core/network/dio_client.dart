import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class DioClient {
  static const String baseUrl = 'https://clarity-api-2dpy.onrender.com';

  static Dio get instance {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(dio));
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  _AuthInterceptor(this.dio);

  // Tự động đính token vào mỗi request
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // Nếu nhận 401 → thử refresh token → retry request cũ
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) return handler.next(err);

      try {
        final res = await Dio().post(
          '${DioClient.baseUrl}/api/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        final newAccessToken = res.data['accessToken'];
        await TokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
        );
        // Retry request cũ với token mới
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retried = await dio.fetch(err.requestOptions);
        return handler.resolve(retried);
      } catch (_) {
        await TokenStorage.clearTokens();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}