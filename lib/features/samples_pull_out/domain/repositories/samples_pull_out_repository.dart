import '../../data/models/client_task_model.dart';

abstract class SamplesPullOutRepository {
  Future<List<ClientTaskModel>> getInFreezerTasks(int driverId);
  Future<void> removeBagFromContainer({
    required int taskId,
    required String bagCode,
    required String containerId,
  });
  Future<void> closeInFreezerTasks(List<int> taskIds);
}
