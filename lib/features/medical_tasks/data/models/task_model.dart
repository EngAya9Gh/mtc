import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
abstract class MedicalTask with _$MedicalTask {
  const factory MedicalTask({
    required int id,
    @JsonKey(name: 'client_english_name') required String clientName,
    @JsonKey(name: 'from_location_name') required String fromLocationName,
    @JsonKey(name: 'to_location_name') required String toLocationName,
    @JsonKey(name: 'dateString') required String date,
    @JsonKey(name: 'timeString') required String time,
    required String status,
    @JsonKey(name: 'confirmed_received_by_driver') required int confirmedByDriver,
    @JsonKey(name: 'is_swap') @Default(0) int isSwap,
  }) = _MedicalTask;

  factory MedicalTask.fromJson(Map<String, dynamic> json) =>
      _$MedicalTaskFromJson(json);
}

@freezed
abstract class TaskListResponse with _$TaskListResponse {
  const factory TaskListResponse({
    required bool status,
    required List<MedicalTask> data,
    String? message,
  }) = _TaskListResponse;

  factory TaskListResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskListResponseFromJson(json);
}
