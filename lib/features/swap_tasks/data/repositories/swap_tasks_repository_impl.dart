import '../../domain/repositories/swap_tasks_repository.dart';
import '../data_sources/swap_tasks_remote_data_source.dart';
import '../models/swap_task_model.dart';

class SwapTasksRepositoryImpl implements SwapTasksRepository {
  final SwapTasksRemoteDataSource _remoteDataSource;

  SwapTasksRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SwapTaskModel>> getSwapTasks(int driverId) {
    return _remoteDataSource.getSwapTasks(driverId);
  }

  @override
  Future<void> acceptAllSwapTasks(List<int> swapIds) {
    return _remoteDataSource.acceptAllSwapTasks(swapIds);
  }

  @override
  Future<void> rejectSwapTask(int swapId) {
    return _remoteDataSource.rejectSwapTask(swapId);
  }

  @override
  Future<void> acceptSwapTask(List<int> swapIds) {
    return _remoteDataSource.acceptSwapTask(swapIds);
  }
}
