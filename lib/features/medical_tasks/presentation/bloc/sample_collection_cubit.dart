import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/network/api_client.dart';
import 'sample_collection_state.dart';

class SampleCollectionCubit extends Cubit<SampleCollectionState> {
  final ApiClient _apiClient;

  SampleCollectionCubit(this._apiClient) : super(const SampleCollectionState.initial());

  Future<void> saveSamplesSequentially({
    required int taskId,
    required int locationId,
    required List<Map<String, String>> scannedSamples,
    required String bagCode,
  }) async {
    // List of containers to process
    final containers = ['ROOM', 'REFRIGERATE', 'FROZEN'];

    for (String container in containers) {
      // Filter barcodes for this container
      final barcodes = scannedSamples
          .where((s) => s['temp'] == container)
          .map((s) => s['barcode'])
          .toList();

      if (barcodes.isNotEmpty) {
        emit(SampleCollectionState.loading('Uploading $container samples...'));
        try {
          // Get the sample type from the first sample in this batch (since they are filtered by combination in UI)
          final sampleType = scannedSamples.isNotEmpty ? (scannedSamples.first['type'] ?? '') : '';

          final response = await _apiClient.post(
            'samples/add',
            data: {
              'task_id': taskId,
              'location_id': locationId,
              'barcode_ids': barcodes,
              'temperature_type': container,
              'bag_code': bagCode,
              'sample_type': sampleType,
            },
          );

          if (response.data['status'] != true) {
            emit(SampleCollectionState.error('Failed to upload $container: ${response.data['message']}'));
            return; // Stop on failure as per logic (no rollback)
          }
        } on DioException catch (e) {
          emit(SampleCollectionState.error('Network Error during $container upload: ${e.message}'));
          return;
        } catch (e) {
          emit(SampleCollectionState.error('Error during $container upload: $e'));
          return;
        }
      }
    }

    emit(const SampleCollectionState.success('All samples uploaded successfully!'));
  }

  Future<void> reportNoSamples(int taskId) async {
    emit(const SampleCollectionState.loading('Reporting no samples...'));
    try {
      final response = await _apiClient.post(
        'task/nosamples',
        data: {'task_id': taskId},
      );

      if (response.data['status'] == true) {
        emit(const SampleCollectionState.success('No samples reported successfully.'));
      } else {
        emit(SampleCollectionState.error(response.data['message'] ?? 'Failed to report no samples.'));
      }
    } on DioException catch (e) {
      emit(SampleCollectionState.error('Network error: ${e.message}'));
    } catch (e) {
      emit(SampleCollectionState.error(e.toString()));
    }
  }

  Future<void> saveBoxTask({
    required int taskId,
    required int locationId,
    required List<Map<String, String>> scannedSamples,
    required int boxCount,
    required int sampleCount,
  }) async {
    final containers = ['ROOM', 'REFRIGERATE', 'FROZEN'];

    for (String container in containers) {
      final barcodes = scannedSamples
          .where((s) => s['temp'] == container)
          .map((s) => s['barcode'] as String)
          .toList();

      if (barcodes.isNotEmpty) {
        emit(SampleCollectionState.loading('Uploading $container box samples...'));
        try {
          final matchingSample = scannedSamples.firstWhere(
            (s) => s['temp'] == container,
            orElse: () => <String, String>{},
          );
          final sampleType = matchingSample['type'] ?? 'Tubes';

          final response = await _apiClient.post(
            'samples/box/add',
            data: {
              'task_id': taskId,
              'location_id': locationId,
              'barcode_ids': barcodes,
              'temperature_type': container,
              'box_count': boxCount,
              'sample_count': sampleCount,
              'sample_type': sampleType,
            },
          );

          if (response.data['status'] != true) {
            emit(SampleCollectionState.error('Failed to upload $container box: ${response.data['message']}'));
            return;
          }
        } on DioException catch (e) {
          emit(SampleCollectionState.error('Network Error during $container box upload: ${e.message}'));
          return;
        } catch (e) {
          emit(SampleCollectionState.error('Error during $container box upload: $e'));
          return;
        }
      }
    }

    emit(const SampleCollectionState.success('All boxes uploaded successfully!'));
  }
}
