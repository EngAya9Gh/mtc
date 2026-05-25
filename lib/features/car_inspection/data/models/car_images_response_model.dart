import 'package:freezed_annotation/freezed_annotation.dart';

part 'car_images_response_model.freezed.dart';
part 'car_images_response_model.g.dart';

@freezed
abstract class CarImagesResponseModel with _$CarImagesResponseModel {
  const factory CarImagesResponseModel({
    CarImageItemModel? signature,
    CarImagesMapModel? images,
  }) = _CarImagesResponseModel;

  factory CarImagesResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CarImagesResponseModelFromJson(json);
}

@freezed
abstract class CarImagesMapModel with _$CarImagesMapModel {
  const factory CarImagesMapModel({
    @JsonKey(name: 'image_front') CarImageItemModel? imageFront,
    @JsonKey(name: 'image_back') CarImageItemModel? imageBack,
    @JsonKey(name: 'image_right') CarImageItemModel? imageRight,
    @JsonKey(name: 'image_left') CarImageItemModel? imageLeft,
    @JsonKey(name: 'image_inside1') CarImageItemModel? imageInside1,
    @JsonKey(name: 'image_inside2') CarImageItemModel? imageInside2,
    @Default([]) @JsonKey(name: 'other_images') List<CarImageItemModel> otherImages,
  }) = _CarImagesMapModel;

  factory CarImagesMapModel.fromJson(Map<String, dynamic> json) =>
      _$CarImagesMapModelFromJson(json);
}

@freezed
abstract class CarImageItemModel with _$CarImageItemModel {
  const factory CarImageItemModel({
    required int id,
    required String url,
  }) = _CarImageItemModel;

  factory CarImageItemModel.fromJson(Map<String, dynamic> json) =>
      _$CarImageItemModelFromJson(json);
}
