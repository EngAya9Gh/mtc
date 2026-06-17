import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/swap_task_model.dart';
import '../../../../data/providers/user_info_provider.dart';
import 'dart:convert';

abstract class SwapTasksRemoteDataSource {
  Future<List<SwapTaskModel>> getSwapTasks(int driverId);
  Future<void> acceptAllSwapTasks(List<int> swapIds);
  Future<void> rejectSwapTask(int swapId);
  Future<void> acceptSwapTask(List<int> swapIds);
}

class SwapTasksRemoteDataSourceImpl implements SwapTasksRemoteDataSource {
  final ApiClient _apiClient;

  SwapTasksRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<SwapTaskModel>> getSwapTasks(int driverId) async {
    try {
      final response = await _apiClient.post(
        EndPoints.swapList,
        data: jsonEncode({'driver_id': driverId}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final jsonResponse = response.data as Map<String, dynamic>;
      
      if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => SwapTaskModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل في جلب مهام التبادل: $e');
    }
  }

  @override
  Future<void> acceptAllSwapTasks(List<int> swapIds) async {
    try {
      final driverId = UserInfo().userId;
      final response = await _apiClient.post(
        EndPoints.acceptAllSwap,
        data: jsonEncode({
          'driver_id': driverId,
          'swaps': swapIds,
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final jsonResponse = response.data as Map<String, dynamic>;
      if (jsonResponse['status'] == false) {
        throw Exception(jsonResponse['message'] ?? 'فشل في قبول كافة المهام');
      }
    } catch (e) {
      throw Exception('فشل في قبول كافة المهام: $e');
    }
  }

  @override
  Future<void> rejectSwapTask(int swapId) async {
    try {
      final driverId = UserInfo().userId;
      final response = await _apiClient.post(
        EndPoints.rejectSwap,
        data: jsonEncode({
          'driver_id': driverId,
          'swap_id': swapId,
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final jsonResponse = response.data as Map<String, dynamic>;
      if (jsonResponse['status'] == false) {
        throw Exception(jsonResponse['message'] ?? 'فشل في رفض المهمة');
      }
    } catch (e) {
      throw Exception('فشل في رفض المهمة: $e');
    }
  }

  @override
  Future<void> acceptSwapTask(List<int> swapIds) async {
    try {
      final driverId = UserInfo().userId;
      final response = await _apiClient.post(
        EndPoints.acceptSwap,
        data: jsonEncode({
          'driver_id': driverId,
          'swap_id': swapIds.first,
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final jsonResponse = response.data as Map<String, dynamic>;
      if (jsonResponse['status'] == false) {
        throw Exception(jsonResponse['message'] ?? 'فشل في تأكيد المهمة');
      }
    } catch (e) {
      throw Exception('فشل في تأكيد المهمة: $e');
    }
  }
}
