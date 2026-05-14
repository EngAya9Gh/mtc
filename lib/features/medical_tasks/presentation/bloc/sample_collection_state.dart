import 'package:freezed_annotation/freezed_annotation.dart';

part 'sample_collection_state.freezed.dart';

@freezed
class SampleCollectionState with _$SampleCollectionState {
  const factory SampleCollectionState.initial() = _Initial;
  const factory SampleCollectionState.loading(String message) = _Loading;
  const factory SampleCollectionState.success(String message) = _Success;
  const factory SampleCollectionState.error(String message) = _Error;
}
