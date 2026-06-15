// removed dart:io
import '../../../samples_pull_out/data/models/client_task_model.dart';
import '../../domain/repositories/drop_off_repository.dart';
import '../data_sources/drop_off_remote_data_source.dart';

class DropOffRepositoryImpl implements DropOffRepository {
  final DropOffRemoteDataSource _remoteDataSource;

  DropOffRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ClientTaskModel>> getDropOffTasks(int driverId) async {
    return await _remoteDataSource.getDropOffTasks(driverId);
  }

  @override
  Future<void> checkDropOffLocation({
    required List<int> taskIds,
    required int toLocationId,
    String takasiNumber = '',
  }) async {
    return await _remoteDataSource.checkDropOffLocation(
      taskIds: taskIds,
      toLocationId: toLocationId,
      takasiNumber: takasiNumber,
    );
  }

  @override
  Future<void> confirmToLocation(int driverId, int toLocationId, List<int> taskIds, double lat, double lng) async {
    return await _remoteDataSource.confirmToLocation(driverId, toLocationId, taskIds, lat, lng);
  }

  @override
  Future<void> closeDropOffTasks(List<int> taskIds, List<int>? signatureBytes) async {
    return await _remoteDataSource.closeDropOffTasks(taskIds, signatureBytes);
  }
}
