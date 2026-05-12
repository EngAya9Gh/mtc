import 'package:freezed_annotation/freezed_annotation.dart';

part 'terms_state.freezed.dart';

@freezed
class TermsState with _$TermsState {
  const factory TermsState.initial() = Initial;
  const factory TermsState.loading() = Loading;
  const factory TermsState.loaded({required String arabicLink, required String englishLink}) = Loaded;
  const factory TermsState.submitting() = Submitting;
  const factory TermsState.success() = Success;
  const factory TermsState.error({required String message}) = Error;
}
