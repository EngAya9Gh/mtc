// removed dart:io
import '../../../samples_pull_out/data/models/client_task_model.dart';

abstract class DropOffRepository {
  Future<List<ClientTaskModel>> getDropOffTasks(int driverId);
  Future<void> checkDropOffLocation({
    required List<int> taskIds,
    required int toLocationId,
    String takasiNumber = '',
  });
  Future<void> closeDropOffTasks(List<int> taskIds, List<int>? signatureBytes);
}
