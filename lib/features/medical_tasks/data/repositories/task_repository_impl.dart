import '../../domain/repositories/task_repository.dart';
import '../data_sources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepositoryImpl(this._remoteDataSource);

  @override
  Future<TaskListResponse> getTasks(int driverId, String status) {
    return _remoteDataSource.getTasks(driverId, status);
  }

  @override
  Future<void> confirmTasks(List<int> taskIds) {
    return _remoteDataSource.confirmTasks(taskIds);
  }
}
