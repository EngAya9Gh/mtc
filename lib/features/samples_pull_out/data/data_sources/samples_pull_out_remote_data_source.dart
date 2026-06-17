import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/client_task_model.dart';

abstract class SamplesPullOutRemoteDataSource {
  Future<List<ClientTaskModel>> getInFreezerTasks(int driverId);
  Future<Map<String, dynamic>> removeBagsFromContainer({
    required List<int> taskIds,
    required List<String> bagCodes,
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
  Future<Map<String, dynamic>> removeBagsFromContainer({
    required List<int> taskIds,
    required List<String> bagCodes,
    required String containerId,
  }) async {
    final response = await _apiClient.post(
      EndPoints.removeBagFromContainer,
      data: {
        'task_id': taskIds,
        'bag_code': bagCodes,
        'container_id': containerId,
      },
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to remove bags');
    }
    
    return json['data'] as Map<String, dynamic>? ?? {};
  }

  @override
  Future<void> closeInFreezerTasks(List<int> taskIds) async {
    final response = await _apiClient.post(
      EndPoints.freezerOut,
      data: FormData.fromMap({
        'task_id': taskIds.map((id) => id.toString()).toList(),
      }),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to close tasks');
    }
  }
}
