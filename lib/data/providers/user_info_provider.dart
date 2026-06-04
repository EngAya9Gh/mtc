import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> init(SharedPreferences prefs) async {
    final userInfoStr = prefs.getString('user_info');
    if (userInfoStr != null) {
      try {
        loginInfo = LoginData.fromJson(jsonDecode(userInfoStr));
      } catch (e) {
        prefs.remove('user_info');
      }
    }
  }

  void logout(SharedPreferences prefs) {
    loginInfo = null;
    boxCount = null;
    sampleCount = null;
    prefs.remove('user_info');
    prefs.remove('token');
  }
}
