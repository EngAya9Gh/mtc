import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../models/login_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/providers/user_info_provider.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SharedPreferences _sharedPreferences;

  AuthRepositoryImpl(this._remoteDataSource, this._sharedPreferences);

  @override
  Future<LoginResponse> login(String username, String password, String fcmToken) async {
    final response = await _remoteDataSource.login(username, password, fcmToken);
    if (response.status && response.data != null) {
      await _sharedPreferences.setString('token', response.data!.token);
    }
    return response;
  }

  @override
  Future<LoginResponse> loginWithMobile(String mobile, String password, String fcmToken) async {
    final response = await _remoteDataSource.loginWithMobile(mobile, password, fcmToken);
    if (response.status && response.data != null) {
      await _sharedPreferences.setString('token', response.data!.token);
    }
    return response;
  }

  @override
  Future<Map<String, String>> getTerms() async {
    final response = await _remoteDataSource.getTerms();
    if (response['status'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      return {
        'arabicLink': data['arabicLink']?.toString() ?? '',
        'englishLink': data['englishLink']?.toString() ?? '',
      };
    }
    return {};
  }

  @override
  Future<bool> acceptTerms(String filePath) async {
    final driverId = UserInfo().userId;
    if (driverId == null) return false;
    
    final success = await _remoteDataSource.acceptTerms(driverId, filePath);
    if (success) {
      await _sharedPreferences.setBool('KEY_IS_ACCEPT_TERMS', true);
    }
    return success;
  }
}
