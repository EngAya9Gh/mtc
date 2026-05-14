import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/parser_utils.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
abstract class MedicalTask with _$MedicalTask {
  const factory MedicalTask({
    @JsonKey(fromJson: _toIntRequired) required int id,
    @JsonKey(name: 'client_english_name') required String clientName,
    @JsonKey(name: 'from_location_name') required String fromLocationName,
    @JsonKey(name: 'to_location_name') required String toLocationName,
    @JsonKey(name: 'dateString') String? date,
    @JsonKey(name: 'timeString') String? time,
    @JsonKey(name: 'pickup_time') String? pickupTime,
    required String status,
    @JsonKey(name: 'confirmed_received_by_driver', fromJson: _toIntRequired) required int confirmedByDriver,
    @JsonKey(name: 'is_swap', fromJson: _toIntRequired) @Default(0) int isSwap,
    @JsonKey(name: 'from_location', fromJson: ParserUtils.toInt) int? fromLocation,
    @JsonKey(name: 'to_location', fromJson: ParserUtils.toInt) int? toLocation,
    @JsonKey(name: 'from_location_lat', fromJson: ParserUtils.toDouble) double? fromLocationLat,
    @JsonKey(name: 'from_location_lng', fromJson: ParserUtils.toDouble) double? fromLocationLng,
    @JsonKey(name: 'to_location_lat', fromJson: ParserUtils.toDouble) double? toLocationLat,
    @JsonKey(name: 'to_location_lng', fromJson: ParserUtils.toDouble) double? toLocationLng,
    @JsonKey(name: 'driver_confirm_from_location', fromJson: ParserUtils.toInt) int? driverConfirmFromLocation,
    @JsonKey(name: 'driver_start_date') String? driverStartDate,
    @JsonKey(name: 'task_type') String? taskType,
    @JsonKey(name: 'box_count', fromJson: ParserUtils.toInt) int? boxCount,
    @JsonKey(name: 'sample_count', fromJson: ParserUtils.toInt) int? sampleCount,
    String? otp,
  }) = _MedicalTask;

  factory MedicalTask.fromJson(Map<String, dynamic> json) =>
      _$MedicalTaskFromJson(json);
}

int _toIntRequired(dynamic val) => ParserUtils.toInt(val) ?? 0;


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
