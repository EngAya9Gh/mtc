import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/providers/user_info_provider.dart';
import '../../navigation/app_router.dart';

class ApiInterceptor extends Interceptor {
  final SharedPreferences sharedPreferences;

  ApiInterceptor(this.sharedPreferences);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = sharedPreferences.getString('token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    final lang = sharedPreferences.getString('app_language') ?? 'ar';
    options.headers['Accept-Language'] = lang;
    super.onRequest(options, handler);
  }

  void _handleLogout() {
    UserInfo().logout(sharedPreferences);
    AppRouter.router.go(AppRouter.login);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle global errors like 401 Unauthorized
    if (err.response?.statusCode == 401) {
      final token = sharedPreferences.getString('token');
      if (token != null) {
        try {
          final dio = Dio();
          final baseUrl = err.requestOptions.baseUrl;
          final response = await dio.post(
            '${baseUrl}driver/refresh',
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            ),
          );

          if (response.statusCode == 200 && response.data['status'] == true) {
            final newToken = response.data['data']['token'];
            await sharedPreferences.setString('token', newToken);

            // Retry the original request
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          } else {
             _handleLogout();
             return handler.reject(err);
          }
        } catch (e) {
          // Refresh failed, proceed to logout (clear token)
          _handleLogout();
          return handler.reject(err);
        }
      } else {
        _handleLogout();
        return handler.reject(err);
      }
    }
    super.onError(err, handler);
  }
}
