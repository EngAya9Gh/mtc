import 'package:freezed_annotation/freezed_annotation.dart';

part 'signature_submit_state.freezed.dart';

@freezed
class SignatureSubmitState with _$SignatureSubmitState {
  const factory SignatureSubmitState.initial() = _Initial;
  const factory SignatureSubmitState.loading() = _Loading;
  const factory SignatureSubmitState.samplesLoaded(List<dynamic> samples) = _SamplesLoaded;
  const factory SignatureSubmitState.success() = _Success;
  const factory SignatureSubmitState.error(String message) = _Error;
}
