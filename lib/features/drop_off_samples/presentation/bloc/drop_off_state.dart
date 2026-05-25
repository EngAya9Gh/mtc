import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../samples_pull_out/data/models/client_task_model.dart';

part 'drop_off_state.freezed.dart';

@freezed
class DropOffState with _$DropOffState {
  const factory DropOffState.initial() = _Initial;
  const factory DropOffState.loading(String message) = _Loading;
  const factory DropOffState.error(String message) = _Error;
  const factory DropOffState.success(String message) = _Success;
  
  // State for destination cards
  const factory DropOffState.tasksLoaded({
    required List<ClientTaskModel> tasks,
  }) = _TasksLoaded;

  // State for local bag scanning
  const factory DropOffState.scanningBags({
    required ClientTaskModel selectedTask,
    required List<SampleSummaryModel> remainingBags,
    required List<SampleSummaryModel> scannedBags,
    required bool allBagsScanned,
  }) = _ScanningBags;

  // State for signature screen
  const factory DropOffState.signatureReady({
    required ClientTaskModel selectedTask,
    required List<SampleSummaryModel> scannedBags,
    required bool isSubmitting,
  }) = _SignatureReady;

  const factory DropOffState.locationCheckSuccess() = _LocationCheckSuccess;
  const factory DropOffState.closeTasksSuccess() = _CloseTasksSuccess;
}
