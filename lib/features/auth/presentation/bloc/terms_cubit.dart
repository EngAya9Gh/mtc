import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'terms_state.dart';
import 'dart:io';

class TermsCubit extends Cubit<TermsState> {
  final AuthRepository _authRepository;

  TermsCubit(this._authRepository) : super(const TermsState.initial());

  Future<void> getTerms() async {
    emit(const TermsState.loading());
    try {
      final terms = await _authRepository.getTerms();
      emit(TermsState.loaded(
        arabicLink: terms['arabicLink'] ?? '',
        englishLink: terms['englishLink'] ?? '',
      ));
    } catch (e) {
      emit(TermsState.error(message: e.toString()));
    }
  }

  Future<void> acceptTerms(File signatureFile) async {
    emit(const TermsState.submitting());
    try {
      final success = await _authRepository.acceptTerms(signatureFile.path);
      if (success) {
        emit(const TermsState.success());
      } else {
        emit(const TermsState.error(message: 'Failed to accept terms'));
      }
    } catch (e) {
      emit(TermsState.error(message: e.toString()));
    }
  }
}
