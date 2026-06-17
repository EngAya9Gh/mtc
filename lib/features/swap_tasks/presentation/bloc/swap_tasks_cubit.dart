import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/swap_tasks_repository.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../data/models/swap_task_model.dart';
import '../../../../features/samples_pull_out/data/models/client_task_model.dart';
import 'swap_tasks_state.dart';

class SwapTasksCubit extends Cubit<SwapTasksState> {
  final SwapTasksRepository _repository;

  SwapTasksCubit(this._repository) : super(const SwapTasksState.initial());

  Future<void> getSwapTasks() async {
    emit(const SwapTasksState.loading('جاري تحميل مهام التبادل...'));
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) {
        emit(const SwapTasksState.error('لم يتم العثور على بيانات السائق'));
        return;
      }

      final tasks = await _repository.getSwapTasks(driverId);
      emit(SwapTasksState.loaded(tasks: tasks));
    } catch (e) {
      emit(SwapTasksState.error(e.toString()));
    }
  }

  Future<void> acceptAllTasks(List<SwapTaskModel> tasks) async {
    emit(const SwapTasksState.loading('جاري قبول المهام...'));
    try {
      final taskIds = tasks.map((t) => t.id).toList();
      await _repository.acceptAllSwapTasks(taskIds);
      
      // Refresh the list after success
      emit(const SwapTasksState.actionSuccess('تم قبول جميع المهام بنجاح'));
      getSwapTasks();
    } catch (e) {
      emit(SwapTasksState.error(e.toString()));
      getSwapTasks(); // restore the list
    }
  }

  Future<void> rejectTask(int swapId) async {
    emit(const SwapTasksState.loading('جاري رفض المهمة...'));
    try {
      await _repository.rejectSwapTask(swapId);
      emit(const SwapTasksState.actionSuccess('تم رفض المهمة بنجاح'));
      getSwapTasks();
    } catch (e) {
      emit(SwapTasksState.error(e.toString()));
      getSwapTasks(); // restore the list
    }
  }

  void proceedToScanBags(SwapTaskModel selectedTask) {
    final List<SampleSummaryModel> allBags = selectedTask.bags;

    // Remove duplicates by bagCode
    final Map<String, SampleSummaryModel> uniqueBagsMap = {};
    for (var bag in allBags) {
      uniqueBagsMap[bag.bagCode] = bag;
    }

    emit(SwapTasksState.scanningBags(
      selectedTask: selectedTask,
      remainingBags: uniqueBagsMap.values.toList(),
      scannedBags: const [],
      allBagsScanned: uniqueBagsMap.isEmpty,
    ));
  }

  void scanBagToAccept(String bagCode) {
    state.maybeWhen(
      scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) {
        final index = remainingBags.indexWhere((bag) => bag.bagCode.toLowerCase() == bagCode.toLowerCase());
        
        if (index >= 0) {
          final matchedBag = remainingBags[index];
          final updatedRemaining = List<SampleSummaryModel>.from(remainingBags)..removeAt(index);
          final updatedScanned = List<SampleSummaryModel>.from(scannedBags)..add(matchedBag);
          
          emit(SwapTasksState.scanningBags(
            selectedTask: selectedTask,
            remainingBags: updatedRemaining,
            scannedBags: updatedScanned,
            allBagsScanned: updatedRemaining.isEmpty,
          ));
        } else {
          // Bag not found or already scanned
          emit(const SwapTasksState.error('عذراً، هذا الكيس غير مطلوب لهذه المهمة أو تم مسحه بالفعل.'));
          // Restore the scanning state
          emit(SwapTasksState.scanningBags(
            selectedTask: selectedTask,
            remainingBags: remainingBags,
            scannedBags: scannedBags,
            allBagsScanned: allBagsScanned,
          ));
        }
      },
      orElse: () {},
    );
  }

  Future<void> submitSwapAcceptance() async {
    await state.maybeWhen(
      scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) async {

        emit(const SwapTasksState.loading('جاري تأكيد استلام المهمة...'));

        try {
          // The API expects swap_ids. Since a selectedTask is a SwapTaskModel, its id is the swapId.
          await _repository.acceptSwapTask([selectedTask.id]);
          emit(const SwapTasksState.actionSuccess('تم تأكيد استلام المهمة بنجاح!'));
        } catch (e) {
          emit(SwapTasksState.error(e.toString()));
          // Restore scanning bags state so they can try again
          emit(SwapTasksState.scanningBags(
            selectedTask: selectedTask,
            remainingBags: remainingBags,
            scannedBags: scannedBags,
            allBagsScanned: allBagsScanned,
          ));
        }
      },
      orElse: () async {},
    );
  }
}
