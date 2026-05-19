import '../../domain/repositories/freezer_repository.dart';
import '../data_sources/freezer_remote_data_source.dart';
import '../models/bag_item_model.dart';

class FreezerRepositoryImpl implements FreezerRepository {
  final FreezerRemoteDataSource _remoteDataSource;

  FreezerRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<BagItemModel>> getTaskBags(int taskId) {
    return _remoteDataSource.getTaskBags(taskId);
  }

  @override
  Future<void> submitAllSamples({
    required int taskId,
    required String containerBarcode,
    required List<String> bagCodes,
  }) {
    return _remoteDataSource.submitAllSamples(
      taskId: taskId,
      containerBarcode: containerBarcode,
      bagCodes: bagCodes,
    );
  }

  @override
  Future<void> closeFreezer(int taskId) {
    return _remoteDataSource.closeFreezer(taskId);
  }
}
