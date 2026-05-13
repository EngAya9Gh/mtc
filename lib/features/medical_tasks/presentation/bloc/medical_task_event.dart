import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_task_event.freezed.dart';

@freezed
abstract class MedicalTaskEvent with _$MedicalTaskEvent {
  const factory MedicalTaskEvent.getTasks({
    required int driverId,
    required String status,
  }) = GetTasks;

  const factory MedicalTaskEvent.confirmTasks({
    required List<int> taskIds,
    required int driverId,
    required String status,
  }) = ConfirmTasks;
}
