import '../../data/models/swap_task_model.dart';

abstract class SwapTasksRepository {
  Future<List<SwapTaskModel>> getSwapTasks(int driverId);
  Future<void> acceptAllSwapTasks(List<int> swapIds);
  Future<void> rejectSwapTask(int swapId);
  Future<void> acceptSwapTask(List<int> swapIds);
}
