import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/client_task_model.dart';

abstract class SamplesPullOutRemoteDataSource {
  Future<List<ClientTaskModel>> getInFreezerTasks(int driverId);
  Future<void> removeBagFromContainer({
    required int taskId,
    required String bagCode,
    required String containerId,
  });
  Future<void> closeInFreezerTasks(List<int> taskIds);
}

class SamplesPullOutRemoteDataSourceImpl implements SamplesPullOutRemoteDataSource {
  final ApiClient _apiClient;

  SamplesPullOutRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<ClientTaskModel>> getInFreezerTasks(int driverId) async {
    final response = await _apiClient.post(
      EndPoints.clientTasks,
      data: {
        'driver_id': driverId,
        'status': 'IN_FREEZER',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to get tasks');
    }
    
    if (json['data'] == null) {
      return [];
    }

    try {
      final dataList = json['data'] as List;
      return dataList.map((e) => ClientTaskModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e, stackTrace) {
      print('=== ERROR PARSING TASKS ===');
      print(e.toString());
      print(stackTrace.toString());
      rethrow;
    }
  }

  @override
  Future<void> removeBagFromContainer({
    required int taskId,
    required String bagCode,
    required String containerId,
  }) async {
    final response = await _apiClient.post(
      EndPoints.removeBagFromContainer,
      data: {
        'task_id': taskId,
        'bag_code': bagCode,
        'container_id': containerId,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to remove bag');
    }
  }

  @override
  Future<void> closeInFreezerTasks(List<int> taskIds) async {
    final response = await _apiClient.post(
      EndPoints.freezerOut,
      data: {'task_id': taskIds},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to close tasks');
    }
  }
}
