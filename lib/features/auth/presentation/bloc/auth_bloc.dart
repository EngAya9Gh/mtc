import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../../../data/providers/user_info_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/services/notifications/notification_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SharedPreferences _sharedPreferences;
  final NotificationService _notificationService;

  AuthBloc(this._authRepository, this._sharedPreferences, this._notificationService) : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LoginWithMobileRequested>(_onLoginWithMobileRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final fcmToken = await _notificationService.getToken() ?? 'no_token';
      final response = await _authRepository.login(event.username, event.password, fcmToken);
      if (response.status && response.data != null) {
        await _sharedPreferences.setString('token', response.data!.token);
        UserInfo().loginInfo = response.data;
        emit(AuthState.authenticated(data: response.data!));
      } else {
        emit(AuthState.error(message: response.message));
      }
    } catch (e, stack) {
      print('❌ Login Exception: $e');
      print('STACKTRACE: $stack');
      emit(AuthState.error(message: e.toString()));
    }
  }

  Future<void> _onLoginWithMobileRequested(
    LoginWithMobileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final fcmToken = await _notificationService.getToken() ?? 'no_token';
      final response = await _authRepository.loginWithMobile(event.mobile, event.password, fcmToken);
      if (response.status && response.data != null) {
        await _sharedPreferences.setString('token', response.data!.token);
        UserInfo().loginInfo = response.data;
        emit(AuthState.authenticated(data: response.data!));
      } else {
        emit(AuthState.error(message: response.message));
      }
    } catch (e, stack) {
      print('❌ Mobile Login Exception: $e');
      print('STACKTRACE: $stack');
      emit(AuthState.error(message: e.toString()));
    }
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState.unauthenticated());
  }
}
