import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SharedPreferences _sharedPreferences;

  AuthBloc(this._authRepository, this._sharedPreferences) : super(const AuthState.initial()) {
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
      final response = await _authRepository.login(event.username, event.password);
      if (response.status && response.data != null) {
        // Token is already saved in repository implementation
        emit(AuthState.authenticated(data: response.data!));
      } else {
        emit(AuthState.error(message: response.message));
      }
    } catch (e) {
      emit(AuthState.error(message: e.toString()));
    }
  }

  Future<void> _onLoginWithMobileRequested(
    LoginWithMobileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final response = await _authRepository.loginWithMobile(event.mobile, event.password);
      if (response.status && response.data != null) {
        emit(AuthState.authenticated(data: response.data!));
      } else {
        emit(AuthState.error(message: response.message));
      }
    } catch (e) {
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
