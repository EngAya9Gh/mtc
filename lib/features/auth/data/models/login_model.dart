import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../medical_tasks/data/models/task_model.dart';
import '../../../../core/utils/parser_utils.dart';

part 'login_model.freezed.dart';
part 'login_model.g.dart';

@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required bool status,
    required String message,
    LoginData? data,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
abstract class LoginData with _$LoginData {
  const factory LoginData({
    @JsonKey(name: 'api_token') required String token,
    @JsonKey(fromJson: _toIntRequired) required int id,
    String? name,
    String? mobile,
    @JsonKey(name: 'fcm_token') String? fcmToken,
    String? language,
    bool? termAccepted,
    bool? hasNotification,
    @JsonKey(name: 'latestTask') MedicalTask? latestTask,
    CarData? car,
  }) = _LoginData;

  factory LoginData.fromJson(Map<String, dynamic> json) =>
      _$LoginDataFromJson(json);
}

@freezed
abstract class CarData with _$CarData {
  const factory CarData({
    @JsonKey(fromJson: _toIntRequired) required int id,
    @JsonKey(name: 'plate_number') String? plateNumber,
    String? imei,
    String? model,
    String? color,
    @JsonKey(name: 'contact_person') String? contactPerson,
    @JsonKey(fromJson: ParserUtils.toInt) int? status,
  }) = _CarData;

  factory CarData.fromJson(Map<String, dynamic> json) =>
      _$CarDataFromJson(json);
}

int _toIntRequired(dynamic val) => ParserUtils.toInt(val) ?? 0;
