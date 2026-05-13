import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/login_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String username, String password, String fcmToken);
  Future<LoginResponse> loginWithMobile(String mobile, String password, String fcmToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<LoginResponse> login(String username, String password, String fcmToken) async {
    print('Sending login request with: username=$username, fcmToken=$fcmToken');
    final response = await _apiClient.post(
      EndPoints.login,
      data: {
        'username': username,
        'password': password,
        'language': 'ar',
        'fcm_token': fcmToken,
        'fcmToken': fcmToken,
      },
    );
    print('Login response: ${response.data}');
    return LoginResponse.fromJson(response.data);
  }

  @override
  Future<LoginResponse> loginWithMobile(String mobile, String password, String fcmToken) async {
    print('Sending mobile login request with: mobile=$mobile, fcmToken=$fcmToken');
    final response = await _apiClient.post(
      EndPoints.loginWithMobile,
      data: {
        'mobile': mobile,
        'password': password,
        'language': 'ar',
   
        'fcmToken': fcmToken,
        'token': fcmToken,
      },
    );
    print('Mobile login response: ${response.data}');
    return LoginResponse.fromJson(response.data);
  }
}
