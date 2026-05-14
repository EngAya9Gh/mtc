import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../data/providers/user_info_provider.dart';

part 'schedule_cubit.freezed.dart';
part 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ApiClient _apiClient;

  ScheduleCubit(this._apiClient) : super(const ScheduleState.initial());

  Future<void> getSchedule() async {
    emit(const ScheduleState.loading());
    try {
      final now = DateTime.now();
      final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      final dayName = days[now.weekday % 7];

      final response = await _apiClient.post(
        'driver-schedule',
        data: {
          'driver_id': UserInfo().loginInfo?.id,
          'day_of_week': dayName,
        },
      );

      if (response.data['status'] == true) {
        final List data = response.data['data'] ?? [];
        emit(ScheduleState.success(data));
      } else {
        emit(ScheduleState.error(response.data['message'] ?? 'Failed to load schedule'));
      }
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  Future<void> acceptAll() async {
    emit(const ScheduleState.loading());
    try {
      final response = await _apiClient.post(
        'driver/schedule/acceptall',
        data: {
          'driver_id': UserInfo().loginInfo?.id,
          'car_id': UserInfo().carInfo?.id,
        },
      );

      if (response.data['status'] == true) {
        await getSchedule(); // Refresh list
      } else {
        emit(ScheduleState.error(response.data['message'] ?? 'Failed to accept schedule'));
      }
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }
}
