import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../models/bag_item_model.dart';

abstract class FreezerRemoteDataSource {
  Future<List<BagItemModel>> getTaskBags(int taskId);
  Future<void> submitAllSamples({
    required int taskId,
    required String containerBarcode,
    required List<String> bagCodes,
  });
  Future<void> closeFreezer(int taskId);
}

class FreezerRemoteDataSourceImpl implements FreezerRemoteDataSource {
  final ApiClient _apiClient;

  FreezerRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<BagItemModel>> getTaskBags(int taskId) async {
    final response = await _apiClient.post(
      EndPoints.taskBags,
      data: {'task_id': taskId},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to get bags');
    }

    final data = json['data'];
    List? dataList;
    if (data is Map && data.containsKey('bags')) {
      dataList = data['bags'] as List?;
    } else if (data is List) {
      dataList = data;
    }

    if (dataList == null) {
      return [];
    }

    return dataList.map((e) => BagItemModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<void> submitAllSamples({
    required int taskId,
    required String containerBarcode,
    required List<String> bagCodes,
  }) async {
    final payload = bagCodes.map((code) => {
      'task_id': taskId,
      'container_id': containerBarcode,
      'bag_code': code,
    }).toList();

    final response = await _apiClient.post(
      EndPoints.addContainerBags,
      data: payload,
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to submit samples');
    }
  }

  @override
  Future<void> closeFreezer(int taskId) async {
    final response = await _apiClient.post(
      EndPoints.closeFreezer,
      data: {'task_id': taskId},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] == false) {
      throw Exception(json['message'] ?? 'Failed to close containers');
    }
  }
}
