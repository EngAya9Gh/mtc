import '../../data/models/client_task_model.dart';

abstract class SamplesPullOutRepository {
  Future<List<ClientTaskModel>> getInFreezerTasks(int driverId);
  Future<Map<String, dynamic>> removeBagsFromContainer({
    required List<int> taskIds,
    required List<String> bagCodes,
    required String containerId,
  });
  Future<void> closeInFreezerTasks(List<int> taskIds);
}
