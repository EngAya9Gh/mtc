import '../../features/auth/data/models/login_model.dart';

class UserInfo {
  static final UserInfo _instance = UserInfo._internal();
  factory UserInfo() => _instance;
  UserInfo._internal();

  LoginData? loginInfo;

  int? boxCount;
  int? sampleCount;

  int? get userId => loginInfo?.id;
  String? get token => loginInfo?.token;
  CarData? get carInfo => loginInfo?.car;
  
  bool get isLoggedIn => loginInfo != null;

  void logout() {
    loginInfo = null;
    boxCount = null;
    sampleCount = null;
  }
}
