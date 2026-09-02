import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/swap_tasks_repository.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../data/models/swap_task_model.dart';
import '../../../../features/samples_pull_out/data/models/client_task_model.dart';
import 'swap_tasks_state.dart';

class SwapTasksCubit extends Cubit<SwapTasksState> {
  final SwapTasksRepository _repository;

  String? _lastInvalidBagCode;
  DateTime? _lastInvalidScanTime;

  bool _isRecentInvalidScan(String bagCode) {
    final now = DateTime.now();
    if (_lastInvalidBagCode == bagCode && _lastInvalidScanTime != null) {
      if (now.difference(_lastInvalidScanTime!).inSeconds < 2) {
        return true;
      }
    }
    _lastInvalidBagCode = bagCode;
    _lastInvalidScanTime = now;
    return false;
  }

  SwapTasksCubit(this._repository) : super(const SwapTasksState.initial());

  Future<void> getSwapTasks() async {
    if (!isClosed) emit(const SwapTasksState.loading(AppStrings.loadingSwapTasks));
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) {
        if (!isClosed) emit(const SwapTasksState.error(AppStrings.driverDataNotFound));
        return;
      }

      final tasks = await _repository.getSwapTasks(driverId);
      if (!isClosed) emit(SwapTasksState.loaded(tasks: tasks));
    } catch (e) {
      if (!isClosed) emit(SwapTasksState.error(e.toString()));
    }
  }

  Future<void> acceptAllTasks(List<SwapTaskModel> tasks) async {
    if (!isClosed) emit(const SwapTasksState.loading(AppStrings.acceptingTasks));
    try {
      final taskIds = tasks.map((t) => t.id).toList();
      await _repository.acceptAllSwapTasks(taskIds);
      
      // Refresh the list after success
      if (!isClosed) emit(const SwapTasksState.actionSuccess('all_tasks_accepted'));
      getSwapTasks();
    } catch (e) {
      if (!isClosed) emit(SwapTasksState.error(e.toString()));
      getSwapTasks(); // restore the list
    }
  }

  Future<void> rejectTask(int swapId) async {
    if (!isClosed) emit(const SwapTasksState.loading(AppStrings.rejectingTask));
    try {
      await _repository.rejectSwapTask(swapId);
      if (!isClosed) emit(const SwapTasksState.actionSuccess('task_rejected'));
      getSwapTasks();
    } catch (e) {
      if (!isClosed) emit(SwapTasksState.error(e.toString()));
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
          // If the bag code is already scanned, silently ignore it
          final isAlreadyScanned = scannedBags.any((bag) => bag.bagCode.toLowerCase() == bagCode.toLowerCase());
          if (!isAlreadyScanned) {
            if (!_isRecentInvalidScan(bagCode)) {
              emit(const SwapTasksState.error('bag_not_required_swap'));
              // Restore the scanning state
              emit(SwapTasksState.scanningBags(
                selectedTask: selectedTask,
                remainingBags: remainingBags,
                scannedBags: scannedBags,
                allBagsScanned: allBagsScanned,
              ));
            }
          }
        }
      },
      orElse: () {},
    );
  }

  Future<void> submitSwapAcceptance() async {
    await state.maybeWhen(
      scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) async {

        if (!isClosed) emit(const SwapTasksState.loading(AppStrings.confirmingTaskReceipt));

        try {
          // The API expects swap_ids. Since a selectedTask is a SwapTaskModel, its id is the swapId.
          await _repository.acceptSwapTask([selectedTask.id]);
          if (!isClosed) emit(const SwapTasksState.actionSuccess('task_receipt_confirmed'));
        } catch (e) {
          if (!isClosed) emit(SwapTasksState.error(e.toString()));
          // Restore scanning bags state so they can try again
          if (!isClosed) emit(SwapTasksState.scanningBags(
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
