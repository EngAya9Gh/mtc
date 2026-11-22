import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/parser_utils.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
abstract class MedicalTask with _$MedicalTask {
  const MedicalTask._();

  const factory MedicalTask({
    @JsonKey(fromJson: _toIntRequired) required int id,
    @JsonKey(name: 'client_english_name') String? clientName,
    @JsonKey(name: 'client_arabic_name') String? clientArabicName,
    @JsonKey(name: 'from_location_name') required String fromLocationName,
    @JsonKey(name: 'from_location_arabic_name') String? fromLocationArabicName,
    @JsonKey(name: 'from_location_english_name') String? fromLocationEnglishName,
    @JsonKey(name: 'to_location_name') required String toLocationName,
    @JsonKey(name: 'to_location_arabic_name') String? toLocationArabicName,
    @JsonKey(name: 'to_location_english_name') String? toLocationEnglishName,
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

  // Tries the current language, then the other one; null means the task has no client name.
  String? localizedClientName(bool isArabic) =>
      ParserUtils.pickLocalized(isArabic, arabic: clientArabicName, english: clientName) ??
      ParserUtils.pickLocalized(!isArabic, arabic: clientArabicName, english: clientName);

  String localizedFromLocation(bool isArabic) =>
      ParserUtils.pickLocalized(isArabic, arabic: fromLocationArabicName, english: fromLocationEnglishName) ??
      fromLocationName;

  String localizedToLocation(bool isArabic) =>
      ParserUtils.pickLocalized(isArabic, arabic: toLocationArabicName, english: toLocationEnglishName) ??
      toLocationName;

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
