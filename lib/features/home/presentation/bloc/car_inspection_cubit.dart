import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../data/providers/user_info_provider.dart';
import 'car_inspection_state.dart';

class CarInspectionCubit extends Cubit<CarInspectionState> {
  final ApiClient _apiClient;

  CarInspectionCubit(this._apiClient) : super(const CarInspectionState.initial());

  Future<void> uploadCarImages({
    required Uint8List signatureBytes,
    required Map<String, XFile> images,
  }) async {
    emit(const CarInspectionState.loading());

    try {
      final driverId = UserInfo().userId;
      final carId = UserInfo().loginInfo?.car?.id;

      if (driverId == null || carId == null) {
        emit(const CarInspectionState.error('Driver ID or Car ID is missing.'));
        return;
      }

      final Map<String, dynamic> formDataMap = {
        'driver_id': driverId,
        'car_id': carId,
        'signature': MultipartFile.fromBytes(signatureBytes, filename: 'signature.png'),
      };

      // Add images
      for (var entry in images.entries) {
        final bytes = await entry.value.readAsBytes();
        final key = _getImageKey(entry.key);
        formDataMap[key] = MultipartFile.fromBytes(bytes, filename: '${entry.key}.jpg');
      }

      final formData = FormData.fromMap(formDataMap);
      final response = await _apiClient.post(
        'driver/car/images',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.data['status'] == true) {
        emit(const CarInspectionState.success());
      } else {
        emit(CarInspectionState.error(response.data['message'] ?? 'Upload failed'));
      }
    } on DioException catch (e) {
      emit(CarInspectionState.error(e.response?.data?['message'] ?? e.message ?? 'Network error'));
    } catch (e, stack) {
      print('❌ Unexpected Error in CarInspectionCubit: $e');
      print('STACKTRACE: $stack');
      emit(CarInspectionState.error(e.toString()));
    }
  }

  String _getImageKey(String key) {
    switch (key) {
      case 'front': return 'image1';
      case 'back': return 'image2';
      case 'right': return 'image3';
      case 'left': return 'image4';
      case 'inside1': return 'image5';
      case 'inside2': return 'image6';
      default: return key;
    }
  }
}
