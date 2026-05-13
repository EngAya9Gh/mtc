import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/task_model.dart';

part 'medical_task_state.freezed.dart';

@freezed
class MedicalTaskState with _$MedicalTaskState {
  const factory MedicalTaskState.initial() = Initial;
  const factory MedicalTaskState.loading() = Loading;
  const factory MedicalTaskState.success({required List<MedicalTask> tasks}) = Success;
  const factory MedicalTaskState.error({required String message}) = Error;
}
