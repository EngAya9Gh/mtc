import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../features/samples_pull_out/data/models/client_task_model.dart';

part 'swap_task_model.freezed.dart';
part 'swap_task_model.g.dart';

@freezed
abstract class SwapTaskModel with _$SwapTaskModel {
  const SwapTaskModel._();

  const factory SwapTaskModel({
    @JsonKey(name: 'swaps') @Default([]) List<int> swaps,
    @JsonKey(name: 'driver_name') String? swapUserName,
    @JsonKey(name: 'from_location_name') String? fromLocationName,
    @JsonKey(name: 'to_location_name') String? toLocationName,
    @JsonKey(name: 'task_status') String? taskStatus,
    @JsonKey(name: 'bags') @Default([]) List<SampleSummaryModel> bags,
  }) = _SwapTaskModel;

  int get id => swaps.isNotEmpty ? swaps.first : 0;
  
  int get taskId {
    if (bags.isNotEmpty && bags.first.taskId != null) {
      return bags.first.taskId!;
    }
    return 0;
  }

  factory SwapTaskModel.fromJson(Map<String, dynamic> json) =>
      _$SwapTaskModelFromJson(json);
}
