import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../../../../data/providers/user_info_provider.dart';

abstract class ReleaseCarState {}
class ReleaseCarInitial extends ReleaseCarState {}
class ReleaseCarLoading extends ReleaseCarState {}
class ReleaseCarSuccess extends ReleaseCarState {}
class ReleaseCarFailure extends ReleaseCarState {
  final String error;
  ReleaseCarFailure(this.error);
}

class ReleaseCarCubit extends Cubit<ReleaseCarState> {
  final ApiClient _apiClient;

  ReleaseCarCubit(this._apiClient) : super(ReleaseCarInitial());

  Future<void> releaseCar() async {
    emit(ReleaseCarLoading());
    try {
      final driverId = UserInfo().userId;
      final carId = UserInfo().loginInfo?.car?.id;

      if (driverId == null || carId == null) {
        emit(ReleaseCarFailure('بيانات السائق أو السيارة مفقودة'));
        return;
      }

      final response = await _apiClient.post(
        EndPoints.releaseCar,
        data: {
          'driver_id': driverId,
          'car_id': carId,
        },
      );

      final json = response.data as Map<String, dynamic>;
      if (json['status'] == false) {
        emit(ReleaseCarFailure(json['message'] ?? 'فشل في إخلاء السيارة'));
      } else {
        emit(ReleaseCarSuccess());
      }
    } catch (e) {
      emit(ReleaseCarFailure('حدث خطأ في الخادم أثناء محاولة إخلاء السيارة. يرجى المحاولة لاحقاً.'));
    }
  }
}
