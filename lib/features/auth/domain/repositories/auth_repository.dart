import '../../data/models/login_model.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String username, String password, String fcmToken);
  Future<LoginResponse> loginWithMobile(String mobile, String password, String fcmToken);
  Future<Map<String, String>> getTerms();
  Future<bool> acceptTerms(String filePath);
}
