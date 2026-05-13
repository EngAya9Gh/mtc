import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<TaskListResponse> getTasks(int driverId, String status);
  Future<void> confirmTasks(List<int> taskIds);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient _apiClient;

  TaskRemoteDataSourceImpl(this._apiClient);

  @override
  Future<TaskListResponse> getTasks(int driverId, String status) async {
    final response = await _apiClient.post(
      EndPoints.tasks,
      data: {
        'driver_id': driverId,
        'status': status,
      },
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Unknown error occurred');
    }
    if (json['data'] == null) {
      json['data'] = [];
    }

    return TaskListResponse.fromJson(json);
  }

  @override
  Future<void> confirmTasks(List<int> taskIds) async {
    await _apiClient.post(
      EndPoints.confirmTasks,
      data: {
        'task_ids': taskIds,
      },
    );
  }
}
