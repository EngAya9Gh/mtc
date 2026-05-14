import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_map_state.freezed.dart';

@freezed
class TaskMapState with _$TaskMapState {
  const factory TaskMapState.initial() = _Initial;
  const factory TaskMapState.loading() = _Loading;
  const factory TaskMapState.success(String message) = _Success;
  const factory TaskMapState.error(String message) = _Error;
}
