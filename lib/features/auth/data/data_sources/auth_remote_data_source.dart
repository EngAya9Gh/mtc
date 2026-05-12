import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/login_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String username, String password);
  Future<LoginResponse> loginWithMobile(String mobile, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<LoginResponse> login(String username, String password) async {
    final response = await _apiClient.post(
      EndPoints.login,
      data: {
        'username': username,
        'password': password,
      },
    );
    return LoginResponse.fromJson(response.data);
  }

  @override
  Future<LoginResponse> loginWithMobile(String mobile, String password) async {
    final response = await _apiClient.post(
      EndPoints.loginWithMobile,
      data: {
        'mobile': mobile,
        'password': password,
      },
    );
    return LoginResponse.fromJson(response.data);
  }
}
