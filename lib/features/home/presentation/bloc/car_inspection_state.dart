import 'package:freezed_annotation/freezed_annotation.dart';

part 'car_inspection_state.freezed.dart';

@freezed
class CarInspectionState with _$CarInspectionState {
  const factory CarInspectionState.initial() = _Initial;
  const factory CarInspectionState.loading() = _Loading;
  const factory CarInspectionState.success() = _Success;
  const factory CarInspectionState.error(String message) = _Error;
}
