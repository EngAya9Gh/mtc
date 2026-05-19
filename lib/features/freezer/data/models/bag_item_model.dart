import 'package:freezed_annotation/freezed_annotation.dart';

part 'bag_item_model.freezed.dart';
part 'bag_item_model.g.dart';

@freezed
abstract class BagItemModel with _$BagItemModel {
  const factory BagItemModel({
    int? id,
    @JsonKey(name: 'bag_code') required String bagCode,
    @JsonKey(name: 'temperature_type') required String temperatureType,
  }) = _BagItemModel;

  factory BagItemModel.fromJson(Map<String, dynamic> json) =>
      _$BagItemModelFromJson(json);
}
