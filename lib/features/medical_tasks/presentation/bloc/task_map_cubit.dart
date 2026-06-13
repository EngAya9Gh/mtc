import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../data/providers/user_info_provider.dart';
import 'task_map_state.dart';

class TaskMapCubit extends Cubit<TaskMapState> {
  final ApiClient _apiClient;

  TaskMapCubit(this._apiClient) : super(const TaskMapState.initial());

  Future<void> confirmLocation({
    required int taskId,
    required int locationId,
    required double lat,
    required double lng,
    double? fromLocationLat,
    double? fromLocationLng,
  }) async {
    emit(const TaskMapState.loading());
    try {
      final driverId = UserInfo().userId;
      
      double finalLat = lat;
      double finalLng = lng;
      if (_apiClient.isDebugMode && fromLocationLat != null && fromLocationLng != null) {
        finalLat = fromLocationLat;
        finalLng = fromLocationLng;
        print('🔧 debugBaseUrl Mode: Overriding confirmLocation coordinates to target: ($finalLat, $finalLng)');
      }

      final response = await _apiClient.post(
        'driver/task/fromlocation/confirm',
        data: {
          'task_id': taskId,
          'driver_id': driverId,
          'from_location': locationId,
          'lat': finalLat,
          'lng': finalLng,
        },
      );

      if (response.data['status'] == true) {
        emit(const TaskMapState.success('Location confirmed successfully'));
      } else {
        emit(TaskMapState.error(response.data['message'] ?? 'Failed to confirm location'));
      }
    } on DioException catch (e) {
      print('❌ DioException in confirmLocation: ${e.message}');
      emit(TaskMapState.error('Network Error: ${e.message}'));
    } catch (e, stack) {
      print('❌ Unexpected Error in confirmLocation: $e');
      print('STACKTRACE: $stack');
      emit(TaskMapState.error(e.toString()));
    }
  }

  Future<void> startTask({
    required int taskId,
    required double lat,
    required double lng,
    double? fromLocationLat,
    double? fromLocationLng,
  }) async {
    emit(const TaskMapState.loading());
    try {
      final driverId = UserInfo().userId;

      double finalLat = lat;
      double finalLng = lng;
      if (_apiClient.isDebugMode && fromLocationLat != null && fromLocationLng != null) {
        finalLat = fromLocationLat;
        finalLng = fromLocationLng;
        print('🔧 debugBaseUrl Mode: Overriding startTask coordinates to target: ($finalLat, $finalLng)');
      }

      final response = await _apiClient.post(
        'driver/task/start',
        data: {
          'task_id': taskId,
          'driver_id': driverId,
          'lat': finalLat,
          'lng': finalLng,
        },
      );

      if (response.data['status'] == true) {
        emit(const TaskMapState.success('Task started successfully'));
      } else {
        emit(TaskMapState.error(response.data['message'] ?? 'Failed to start task'));
      }
    } on DioException catch (e) {
      print('❌ DioException in startTask: ${e.message}');
      emit(TaskMapState.error('Network Error: ${e.message}'));
    } catch (e, stack) {
      print('❌ Unexpected Error in startTask: $e');
      print('STACKTRACE: $stack');
      emit(TaskMapState.error(e.toString()));
    }
  }
}
