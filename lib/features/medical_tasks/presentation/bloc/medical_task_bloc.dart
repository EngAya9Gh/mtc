import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/task_repository.dart';
import 'medical_task_event.dart';
import 'medical_task_state.dart';

class MedicalTaskBloc extends Bloc<MedicalTaskEvent, MedicalTaskState> {
  final TaskRepository _taskRepository;

  MedicalTaskBloc(this._taskRepository) : super(const MedicalTaskState.initial()) {
    on<GetTasks>(_onGetTasks);
    on<ConfirmTasks>(_onConfirmTasks);
  }

  Future<void> _onGetTasks(
    GetTasks event,
    Emitter<MedicalTaskState> emit,
  ) async {
    emit(const MedicalTaskState.loading());
    try {
      final response = await _taskRepository.getTasks(event.driverId, event.status);
      if (response.status) {
        emit(MedicalTaskState.success(tasks: response.data));
      } else {
        emit(MedicalTaskState.error(message: response.message ?? 'Unknown error'));
      }
    } catch (e) {
      emit(MedicalTaskState.error(message: e.toString()));
    }
  }

  Future<void> _onConfirmTasks(
    ConfirmTasks event,
    Emitter<MedicalTaskState> emit,
  ) async {
    emit(const MedicalTaskState.loading());
    try {
      await _taskRepository.confirmTasks(event.taskIds);
      add(MedicalTaskEvent.getTasks(driverId: event.driverId, status: event.status));
    } catch (e) {
      emit(MedicalTaskState.error(message: e.toString()));
    }
  }
}
