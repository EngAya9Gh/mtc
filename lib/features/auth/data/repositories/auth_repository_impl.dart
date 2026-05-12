import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../models/login_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SharedPreferences _sharedPreferences;

  AuthRepositoryImpl(this._remoteDataSource, this._sharedPreferences);

  @override
  Future<LoginResponse> login(String username, String password) async {
    final response = await _remoteDataSource.login(username, password);
    if (response.status && response.data != null) {
      await _sharedPreferences.setString('token', response.data!.token);
    }
    return response;
  }

  @override
  Future<LoginResponse> loginWithMobile(String mobile, String password) async {
    final response = await _remoteDataSource.loginWithMobile(mobile, password);
    if (response.status && response.data != null) {
      await _sharedPreferences.setString('token', response.data!.token);
    }
    return response;
  }
}
