import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/car_inspection_repository.dart';
import '../../data/models/car_images_response_model.dart';

abstract class CarInspectionState {}
class CarInspectionInitial extends CarInspectionState {}
class CarInspectionLoading extends CarInspectionState {}
class CarImagesFetching extends CarInspectionState {}
class CarInspectionSuccess extends CarInspectionState {}
class CarInspectionFailure extends CarInspectionState {
  final String error;
  CarInspectionFailure(this.error);
}
class CarImagesLoaded extends CarInspectionState {
  final CarImagesResponseModel data;
  CarImagesLoaded(this.data);
}

class CarInspectionCubit extends Cubit<CarInspectionState> {
  final CarInspectionRepository _repository;

  CarInspectionCubit(this._repository) : super(CarInspectionInitial());

  Future<void> submitInspection({
    required int driverId,
    required int carId,
    required Map<String, List<int>> imagesBytes,
    required List<int> signatureBytes,
  }) async {
    emit(CarInspectionLoading());
    try {
      await _repository.submitCarImages(
        driverId: driverId,
        carId: carId,
        imagesBytes: imagesBytes,
        signatureBytes: signatureBytes,
      );
      emit(CarInspectionSuccess());
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest')) {
        emit(CarInspectionFailure('خطأ في الشبكة. الرجاء التأكد من اتصالك بالإنترنت.'));
      } else {
        emit(CarInspectionFailure('تعذر رفع صور السيارة، يرجى المحاولة لاحقاً.'));
      }
    }
  }

  Future<void> fetchCarImages(int carId) async {
    emit(CarImagesFetching());
    try {
      final response = await _repository.getCarImages(carId);
      emit(CarImagesLoaded(response));
    } catch (e) {
      emit(CarInspectionFailure(e.toString()));
    }
  }
}
