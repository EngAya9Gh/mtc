// removed dart:io
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../../../samples_pull_out/data/models/client_task_model.dart';

abstract class DropOffRemoteDataSource {
  Future<List<ClientTaskModel>> getDropOffTasks(int driverId);
  Future<void> checkDropOffLocation({
    required List<int> taskIds,
    required int toLocationId,
    String takasiNumber = '',
  });
  Future<void> confirmToLocation(int driverId, int toLocationId, List<int> taskIds, double lat, double lng);
  Future<void> closeDropOffTasks(List<int> taskIds, List<int>? signatureBytes);
}

class DropOffRemoteDataSourceImpl implements DropOffRemoteDataSource {
  final ApiClient _apiClient;

  DropOffRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<ClientTaskModel>> getDropOffTasks(int driverId) async {
    final response = await _apiClient.post(
      EndPoints.clientTasks,
      data: {
        'driver_id': driverId,
        'status': 'OUT_FREEZER',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to get drop off tasks');
    }

    if (json['data'] == null) {
      return [];
    }

    try {
      final dataList = json['data'] as List;
      return dataList.map((e) => ClientTaskModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e, stackTrace) {
      print('=== ERROR PARSING DROP OFF TASKS ===');
      print(e.toString());
      print(stackTrace.toString());
      rethrow;
    }
  }

  @override
  Future<void> checkDropOffLocation({
    required List<int> taskIds,
    required int toLocationId,
    String takasiNumber = '',
  }) async {
    final response = await _apiClient.post(
      EndPoints.checkTasksLocation,
      data: {
        'tasks': taskIds,
        'to_location': toLocationId,
        'takasi_number': takasiNumber,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to check location');
    }
  }

  @override
  Future<void> confirmToLocation(int driverId, int toLocationId, List<int> taskIds, double lat, double lng) async {
    final response = await _apiClient.post(
      EndPoints.confirmToLocation,
      data: jsonEncode({
        'driver_id': driverId,
        'to_location': toLocationId,
        'task_ids': taskIds,
        'lat': lat,
        'lng': lng,
      }),
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to confirm location');
    }
  }

  @override
  Future<void> closeDropOffTasks(List<int> taskIds, List<int>? signatureBytes) async {
    // Determine the path based on EndPoints, it was checked and it is 'tasks/close'
    
    // Create FormData for Multipart request
    final formData = FormData();
    
    // The server expects 'tasks' to be a JSON string like "[301, 302]"
    formData.fields.add(MapEntry('tasks', jsonEncode(taskIds)));
    
    if (signatureBytes != null) {
      formData.files.add(
        MapEntry(
          'signature', // Adjust field name if backend requires something else
          MultipartFile.fromBytes(
            signatureBytes,
            filename: 'signature_${DateTime.now().millisecondsSinceEpoch}.png',
          ),
        ),
      );
    }

    final response = await _apiClient.post(
      EndPoints.closeDeliveryTasks,
      data: formData,
      // Dio automatically sets the correct Multipart boundary when using FormData
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to close drop off tasks');
    }
  }
}
