import '../../data/models/car_images_response_model.dart';

abstract class CarInspectionRepository {
  Future<CarImagesResponseModel> getCarImages(int carId);
  Future<void> submitCarImages({
    required int driverId,
    required int carId,
    required Map<String, List<int>> imagesBytes,
    required List<int> signatureBytes,
  });
}
