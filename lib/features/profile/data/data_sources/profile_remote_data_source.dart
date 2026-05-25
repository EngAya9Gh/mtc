import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile(int driverId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ProfileModel> getProfile(int driverId) async {
    try {
      final response = await _apiClient.post(
        EndPoints.profile,
        data: {'driver_id': driverId},
      );
      
      final jsonResponse = response.data as Map<String, dynamic>;
      
      // We expect the data object or the root object depending on the API structure.
      // Commonly it's inside `data`, so we try both.
      final responseData = jsonResponse['data'] ?? jsonResponse;
      final carData = responseData['car'] ?? {};
      
      final mappedData = {
        'txtName': responseData['name']?.toString() ?? '',
        'txtCity': responseData['city']?.toString() ?? '',
        'txtEmail': responseData['email']?.toString() ?? '',
        'txtMobileNumber': responseData['mobile']?.toString() ?? '',
        'txtUserName': responseData['username']?.toString() ?? '',
        'txtDriverID': carData['driver_id']?.toString() ?? '',
        'txtModel': carData['model']?.toString() ?? '',
        'txtColor': carData['color']?.toString() ?? '',
        'txtDescription': carData['description']?.toString() ?? '',
        'txtCarNumber': carData['plate_number']?.toString() ?? '',
      };
      
      return ProfileModel.fromJson(mappedData);
    } catch (e) {
      throw Exception('فشل في جلب بيانات الملف الشخصي: $e');
    }
  }
}
