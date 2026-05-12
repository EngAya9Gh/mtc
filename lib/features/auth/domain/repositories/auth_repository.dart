import '../../data/models/login_model.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String username, String password);
  Future<LoginResponse> loginWithMobile(String mobile, String password);
}
