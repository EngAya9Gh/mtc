import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../data/providers/user_info_provider.dart';

part 'notifications_cubit.freezed.dart';
part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final ApiClient _apiClient;

  NotificationsCubit(this._apiClient) : super(const NotificationsState.initial());

  Future<void> getNotifications() async {
    emit(const NotificationsState.loading());
    try {
      final response = await _apiClient.post(
        'driver/notifications',
        data: {'driver_id': UserInfo().loginInfo?.id},
      );

      if (response.data['status'] == true) {
        final List data = response.data['data'] ?? [];
        emit(NotificationsState.success(data));
      } else {
        emit(NotificationsState.error(response.data['message'] ?? 'Failed to load notifications'));
      }
    } catch (e) {
      emit(NotificationsState.error(e.toString()));
    }
  }
}
