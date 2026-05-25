import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/car_images_response_model.dart';

abstract class CarInspectionRemoteDataSource {
  Future<CarImagesResponseModel> getCarImages(int carId);
  Future<void> submitCarImages({
    required int driverId,
    required int carId,
    required Map<String, List<int>> imagesBytes,
    required List<int> signatureBytes,
  });
}

class CarInspectionRemoteDataSourceImpl implements CarInspectionRemoteDataSource {
  final ApiClient _apiClient;

  CarInspectionRemoteDataSourceImpl(this._apiClient);

  @override
  Future<CarImagesResponseModel> getCarImages(int carId) async {
    try {
      final response = await _apiClient.get(
        EndPoints.carImages,
        queryParameters: {'car_id': carId},
      );
      
      final json = response.data as Map<String, dynamic>;
      if (json['status'] == true && json['data'] != null) {
        // Temporary fix: Replace localhost URLs with test server URLs due to backend .env misconfiguration
        var dataStr = jsonEncode(json['data']).replaceAll('http://localhost:8000', 'https://test.gosample.com');
        return CarImagesResponseModel.fromJson(jsonDecode(dataStr));
      } else {
        return const CarImagesResponseModel();
      }
    } catch (e) {
      throw Exception('فشل في جلب الصور السابقة: $e');
    }
  }

  @override
  Future<void> submitCarImages({
    required int driverId,
    required int carId,
    required Map<String, List<int>> imagesBytes,
    required List<int> signatureBytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'driver_id': driverId.toString(),
        'car_id': carId.toString(),
      });

      if (signatureBytes.isNotEmpty) {
        formData.files.add(MapEntry(
          'signature',
          MultipartFile.fromBytes(signatureBytes, filename: 'signature.png', contentType: MediaType('image', 'png')),
        ));
      }

      final keyMap = {
        'front': 'image_front',
        'back': 'image_back',
        'right': 'image_right',
        'left': 'image_left',
        'inside1': 'image_inside1',
        'inside2': 'image_inside2',
      };

      for (var entry in imagesBytes.entries) {
        final backendKey = keyMap[entry.key] ?? 'images[]';
        formData.files.add(MapEntry(
          backendKey,
          MultipartFile.fromBytes(entry.value, filename: '${entry.key}.jpg', contentType: MediaType('image', 'jpeg')),
        ));
      }

      final response = await _apiClient.post(
        EndPoints.carImages,
        data: formData,
      );

      final json = response.data as Map<String, dynamic>;
      if (json['status'] == false) {
        throw Exception(json['message'] ?? 'فشل في رفع الصور');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال بالخادم: $e');
    }
  }
}
