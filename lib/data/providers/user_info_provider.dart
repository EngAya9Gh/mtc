import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/network/api_client.dart';
import '../../features/auth/data/models/login_model.dart';

class UserInfo {
  static final UserInfo _instance = UserInfo._internal();
  factory UserInfo() => _instance;
  UserInfo._internal();

  LoginData? loginInfo;
  bool hasRefreshed = false;

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

  Future<void> refreshProfile({bool force = false}) async {
    if (loginInfo == null) return;
    if (hasRefreshed && !force) return;
    try {
      final sharedPrefs = GetIt.instance<SharedPreferences>();
      final apiClient = GetIt.instance<ApiClient>();
      
      final response = await apiClient.post(
        'driver/profile',
        data: {'driver_id': userId},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = response.data as Map<String, dynamic>;
        final responseData = jsonResponse['data'] ?? jsonResponse;
        
        if (responseData != null) {
          final updatedLoginInfo = loginInfo!.copyWith(
            name: responseData['name']?.toString() ?? loginInfo?.name,
            mobile: responseData['mobile']?.toString() ?? loginInfo?.mobile,
            car: responseData['car'] != null 
                ? CarData.fromJson(responseData['car']) 
                : loginInfo?.car,
          );
          
          loginInfo = updatedLoginInfo;
          await sharedPrefs.setString('user_info', jsonEncode(updatedLoginInfo.toJson()));
          hasRefreshed = true;
          print('UserInfo profile refreshed successfully in background: ${loginInfo?.name}');
        }
      }
    } catch (e) {
      print('Failed to refresh UserInfo profile in background: $e');
    }
  }

  void logout(SharedPreferences prefs) {
    loginInfo = null;
    boxCount = null;
    sampleCount = null;
    hasRefreshed = false;
    prefs.remove('user_info');
    prefs.remove('token');
  }
}
