import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_task_model.freezed.dart';
part 'client_task_model.g.dart';

@freezed
abstract class ClientTaskModel with _$ClientTaskModel {
  const factory ClientTaskModel({
    @JsonKey(name: 'to_location') int? toLocation,
    String? name,
    @JsonKey(name: 'arabic_name') String? arabicName,
    @JsonKey(name: 'english_name') String? englishName,
    @Default([]) List<GroupedTaskModel> tasks,
    @Default([]) List<int> taskIds,
  }) = _ClientTaskModel;

  factory ClientTaskModel.fromJson(Map<String, dynamic> json) =>
      _$ClientTaskModelFromJson(json);
}

@freezed
abstract class GroupedTaskModel with _$GroupedTaskModel {
  const factory GroupedTaskModel({
    required int id,
    String? status,
    @JsonKey(name: 'samples_summary') @Default([]) List<SampleSummaryModel> samplesSummary,
  }) = _GroupedTaskModel;

  factory GroupedTaskModel.fromJson(Map<String, dynamic> json) =>
      _$GroupedTaskModelFromJson(json);
}

@freezed
abstract class SampleSummaryModel with _$SampleSummaryModel {
  const factory SampleSummaryModel({
    required int id,
    @JsonKey(name: 'barcode_id') String? barcodeId,
    @JsonKey(name: 'bag_code') required String bagCode,
    @JsonKey(name: 'temperature_type') required String temperatureType,
    @JsonKey(name: 'sample_type') String? sampleType,
    @JsonKey(name: 'task_id') int? taskId,
    @JsonKey(name: 'container_id') int? containerId,
  }) = _SampleSummaryModel;

  factory SampleSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$SampleSummaryModelFromJson(json);
}
