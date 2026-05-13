import '../../data/models/task_model.dart';

abstract class TaskRepository {
  Future<TaskListResponse> getTasks(int driverId, String status);
  Future<void> confirmTasks(List<int> taskIds);
}
