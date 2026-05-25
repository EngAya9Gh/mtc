import '../../domain/repositories/car_inspection_repository.dart';
import '../data_sources/car_inspection_remote_data_source.dart';
import '../models/car_images_response_model.dart';

class CarInspectionRepositoryImpl implements CarInspectionRepository {
  final CarInspectionRemoteDataSource _remoteDataSource;

  CarInspectionRepositoryImpl(this._remoteDataSource);

  @override
  Future<CarImagesResponseModel> getCarImages(int carId) {
    return _remoteDataSource.getCarImages(carId);
  }

  @override
  Future<void> submitCarImages({
    required int driverId,
    required int carId,
    required Map<String, List<int>> imagesBytes,
    required List<int> signatureBytes,
  }) {
    return _remoteDataSource.submitCarImages(
      driverId: driverId,
      carId: carId,
      imagesBytes: imagesBytes,
      signatureBytes: signatureBytes,
    );
  }
}
