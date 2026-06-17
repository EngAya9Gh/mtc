import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/client_task_model.dart';

part 'pull_out_state.freezed.dart';

@freezed
class PullOutState with _$PullOutState {
  const factory PullOutState.initial() = _Initial;
  const factory PullOutState.loading(String message) = _Loading;
  const factory PullOutState.error(String message) = _Error;
  const factory PullOutState.success(String message) = _Success;
  const factory PullOutState.closeTasksSuccess() = _CloseTasksSuccess;

  const factory PullOutState.tasksLoaded({
    required List<ClientTaskModel> tasks,
  }) = _TasksLoaded;

  const factory PullOutState.pullOutState({
    required ClientTaskModel selectedTask,
    required List<SampleSummaryModel> allDestinationBags,
    required List<SampleSummaryModel> currentContainerBags,
    @Default([]) List<SampleSummaryModel> scannedBagsToRemove,
    String? scannedContainerId,
    String? scannedContainerType,
    required bool isContainerValidated,
    required bool isContainerScanMode,
    required bool allFinished,
    required bool hasBagsInOtherContainers,
    required bool isRemoving,
  }) = _PullOutStateData;
}
