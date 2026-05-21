import '../../../freezer/data/models/bag_item_model.dart';
import '../../../medical_tasks/data/models/task_model.dart';
import '../../domain/repositories/samples_pull_out_repository.dart';
import '../data_sources/samples_pull_out_remote_data_source.dart';
import '../models/client_task_model.dart';

class SamplesPullOutRepositoryImpl implements SamplesPullOutRepository {
  final SamplesPullOutRemoteDataSource _remoteDataSource;

  SamplesPullOutRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ClientTaskModel>> getInFreezerTasks(int driverId) {
    return _remoteDataSource.getInFreezerTasks(driverId);
  }

  @override
  Future<void> removeBagFromContainer({
    required int taskId,
    required String bagCode,
    required String containerId,
  }) {
    return _remoteDataSource.removeBagFromContainer(
      taskId: taskId,
      bagCode: bagCode,
      containerId: containerId,
    );
  }

  @override
  Future<void> closeInFreezerTasks(List<int> taskIds) {
    return _remoteDataSource.closeInFreezerTasks(taskIds);
  }
}
