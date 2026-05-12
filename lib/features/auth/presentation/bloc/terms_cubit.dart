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
      // Mocking for now as per plan
      emit(const TermsState.loaded(
        arabicLink: 'https://gosample.com/terms_ar.pdf',
        englishLink: 'https://gosample.com/terms_en.pdf',
      ));
    } catch (e) {
      emit(TermsState.error(message: e.toString()));
    }
  }

  Future<void> acceptTerms(File signatureFile) async {
    emit(const TermsState.submitting());
    try {
      // Logic to call repository for accept terms
      // final success = await _authRepository.acceptTerms(signatureFile);
      emit(const TermsState.success());
    } catch (e) {
      emit(TermsState.error(message: e.toString()));
    }
  }
}
