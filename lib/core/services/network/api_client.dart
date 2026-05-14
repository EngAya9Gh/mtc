import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../utils/end_points.dart';
import 'api_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio, SharedPreferences sharedPreferences) {
    _dio.interceptors.add(ApiInterceptor(sharedPreferences));
    if (kDebugMode) {
      _dio.interceptors.add(CustomLogInterceptor());
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    print('🌐 [API GET] Path: $path');
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    print('🌐 [API POST] Path: $path');
    if (data != null) print('📦 [API POST] Data: $data');
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    print('🌐 [API PUT] Path: $path');
    if (data != null) print('📦 [API PUT] Data: $data');
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    print('🌐 [API DELETE] Path: $path');
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

class CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('\n==================== API REQUEST ====================');
    print('➡️ METHOD: ${options.method}');
    print('🌐 URL: ${options.uri}');
    print('🏷️ HEADERS:');
    options.headers.forEach((key, value) => print('   $key: $value'));
    if (options.data != null) {
      print('📦 BODY:');
      if (options.data is FormData) {
        print('   FormData: ${(options.data as FormData).fields}');
        print('   Files: ${(options.data as FormData).files.map((e) => e.key).toList()}');
      } else {
        print(options.data.toString());
      }
    }
    print('=====================================================\n');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('\n==================== API RESPONSE ===================');
    print('⬅️ STATUS: ${response.statusCode}');
    print('🌐 URL: ${response.requestOptions.uri}');
    print('📦 RESPONSE DATA:');
    print(response.data.toString());
    print('=====================================================\n');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('\n==================== API ERROR ======================');
    print('❌ STATUS: ${err.response?.statusCode}');
    print('🌐 URL: ${err.requestOptions.uri}');
    print('🛑 ERROR MESSAGE: ${err.message}');
    if (err.response?.data != null) {
      print('📦 ERROR DATA:');
      print(err.response?.data.toString());
    }
    print('=====================================================\n');
    super.onError(err, handler);
  }
}
