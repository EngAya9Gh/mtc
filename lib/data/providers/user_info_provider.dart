import '../../features/auth/data/models/login_model.dart';

class UserInfo {
  static final UserInfo _instance = UserInfo._internal();
  factory UserInfo() => _instance;
  UserInfo._internal();

  LoginData? loginInfo;

  int? get userId => loginInfo?.id;
  String? get token => loginInfo?.token;
  
  bool get isLoggedIn => loginInfo != null;
}
