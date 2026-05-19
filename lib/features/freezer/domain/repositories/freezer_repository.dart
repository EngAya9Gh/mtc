import '../../data/models/bag_item_model.dart';

abstract class FreezerRepository {
  Future<List<BagItemModel>> getTaskBags(int taskId);
  Future<void> submitAllSamples({
    required int taskId,
    required String containerBarcode,
    required List<String> bagCodes,
  });
  Future<void> closeFreezer(int taskId);
}
