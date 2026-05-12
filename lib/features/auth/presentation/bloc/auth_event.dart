import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String username,
    required String password,
  }) = LoginRequested;

  const factory AuthEvent.loginWithMobileRequested({
    required String mobile,
    required String password,
  }) = LoginWithMobileRequested;

  const factory AuthEvent.logoutRequested() = LogoutRequested;
}
