import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/swap_task_model.dart';
import '../../../../features/samples_pull_out/data/models/client_task_model.dart';

part 'swap_tasks_state.freezed.dart';

@freezed
class SwapTasksState with _$SwapTasksState {
  const factory SwapTasksState.initial() = _Initial;
  const factory SwapTasksState.loading(String message) = _Loading;
  const factory SwapTasksState.loaded({required List<SwapTaskModel> tasks}) = _Loaded;
  const factory SwapTasksState.error(String message) = _Error;

  // For scanning mode
  const factory SwapTasksState.scanningBags({
    required SwapTaskModel selectedTask,
    required List<SampleSummaryModel> remainingBags,
    required List<SampleSummaryModel> scannedBags,
    required bool allBagsScanned,
  }) = _ScanningBags;

  const factory SwapTasksState.actionSuccess(String message) = _ActionSuccess;
}
