import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
abstract class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    @JsonKey(name: 'txtName', defaultValue: '') String? txtName,
    @JsonKey(name: 'txtCity', defaultValue: '') String? txtCity,
    @JsonKey(name: 'txtEmail', defaultValue: '') String? txtEmail,
    @JsonKey(name: 'txtMobileNumber', defaultValue: '') String? txtMobileNumber,
    @JsonKey(name: 'txtUserName', defaultValue: '') String? txtUserName,
    @JsonKey(name: 'txtDriverID', defaultValue: '') String? txtDriverID,
    @JsonKey(name: 'txtModel', defaultValue: '') String? txtModel,
    @JsonKey(name: 'txtColor', defaultValue: '') String? txtColor,
    @JsonKey(name: 'txtDescription', defaultValue: '') String? txtDescription,
    @JsonKey(name: 'txtCarNumber', defaultValue: '') String? txtCarNumber,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}
