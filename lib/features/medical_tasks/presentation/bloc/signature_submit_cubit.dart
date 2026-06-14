import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/network/api_client.dart';
import 'signature_submit_state.dart';

class SignatureSubmitCubit extends Cubit<SignatureSubmitState> {
  final ApiClient _apiClient;

  SignatureSubmitCubit(this._apiClient) : super(const SignatureSubmitState.initial());

  Future<void> fetchSamples(int taskId) async {
    print('🔍 [SignatureSubmitCubit] Fetching samples for task: $taskId');
    emit(const SignatureSubmitState.loading());
    try {
      final response = await _apiClient.post(
        'samples/list',
        data: {'task_id': taskId},
      );

      if (response.data['status'] == true) {
        final List samples = response.data['data'] ?? [];
        print('✅ [SignatureSubmitCubit] Samples loaded: ${samples.length}');
        emit(SignatureSubmitState.samplesLoaded(samples));
      } else {
        print('⚠️ [SignatureSubmitCubit] Failed to fetch samples: ${response.data['message']}');
        emit(SignatureSubmitState.error(response.data['message'] ?? 'Failed to fetch samples'));
      }
    } on DioException catch (e) {
      print('❌ [SignatureSubmitCubit] DioException: ${e.message}');
      emit(SignatureSubmitState.error('Network Error: ${e.message}'));
    } catch (e) {
      print('❌ [SignatureSubmitCubit] Unexpected Error: $e');
      emit(SignatureSubmitState.error(e.toString()));
    }
  }

  Future<void> submitTask({
    required int taskId,
    required bool isCollection, // true for task/collect, false for task/close
    int? boxCount,
    int? sampleCount,
    String? otp,
    double? taskLat,
    double? taskLng,
  }) async {
    print('🚀 [SignatureSubmitCubit] Submitting task: $taskId, isCollection: $isCollection');
    emit(const SignatureSubmitState.loading());
    try {
      final endpoint = isCollection ? 'task/collect' : 'task/close';

      double finalLat = 0.0;
      double finalLng = 0.0;

      if (_apiClient.isDebugMode && taskLat != null && taskLng != null) {
        finalLat = taskLat;
        finalLng = taskLng;
      } else {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          finalLat = position.latitude;
          finalLng = position.longitude;
        } catch (e) {
          print('⚠️ [SignatureSubmitCubit] Could not get location: $e');
        }
      }
      
      final Map<String, dynamic> body = {
        'task_id': taskId,
        'lat': finalLat,
        'lng': finalLng,
      };
      
      if (isCollection) {
        if (boxCount != null) body['box_count'] = boxCount;
        if (sampleCount != null) body['sample_count'] = sampleCount;
      } else {
        if (otp != null) body['deliver_confirmationCode'] = otp;
      }

      final response = await _apiClient.post(endpoint, data: body);

      if (response.data['status'] == true) {
        print('✅ [SignatureSubmitCubit] Task submitted successfully');
        emit(const SignatureSubmitState.success());
      } else {
        print('⚠️ [SignatureSubmitCubit] Submission failed: ${response.data['message']}');
        emit(SignatureSubmitState.error(response.data['message'] ?? 'Failed to submit task'));
      }
    } on DioException catch (e) {
      print('❌ [SignatureSubmitCubit] DioException: ${e.message}');
      emit(SignatureSubmitState.error('Network Error: ${e.message}'));
    } catch (e) {
      print('❌ [SignatureSubmitCubit] Unexpected Error: $e');
      emit(SignatureSubmitState.error(e.toString()));
    }
  }
}
