import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/utils/end_points.dart';
import '../../../../data/providers/user_info_provider.dart';

abstract class EmergencyState {}
class EmergencyInitial extends EmergencyState {}
class EmergencyLoading extends EmergencyState {}
class EmergencySuccess extends EmergencyState {
  final String message;
  EmergencySuccess(this.message);
}
class EmergencyFailure extends EmergencyState {
  final String error;
  EmergencyFailure(this.error);
}

class EmergencyCubit extends Cubit<EmergencyState> {
  final ApiClient _apiClient;

  EmergencyCubit(this._apiClient) : super(EmergencyInitial());

  Future<void> sendEmergencyRequest() async {
    emit(EmergencyLoading());
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) {
        emit(EmergencyFailure('لم يتم العثور على بيانات السائق'));
        return;
      }
      
      final carId = UserInfo().loginInfo?.car?.id ?? 0;

      final response = await _apiClient.post(
        EndPoints.emergency,
        data: {
          'driver_id': driverId,
          'car_id': carId,
        },
      );

      final json = response.data as Map<String, dynamic>;
      if (json['status'] == false) {
        emit(EmergencyFailure(json['message'] ?? 'فشل إرسال طلب الطوارئ'));
      } else {
        emit(EmergencySuccess(json['message'] ?? 'تم إرسال طلب الطوارئ بنجاح'));
      }
    } catch (e) {
      emit(EmergencyFailure(e.toString()));
    }
  }
}
