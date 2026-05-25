import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../../samples_pull_out/data/models/client_task_model.dart';
import '../../domain/repositories/drop_off_repository.dart';
import 'drop_off_state.dart';

class DropOffCubit extends Cubit<DropOffState> {
  final DropOffRepository _repository;

  int? _scannedLocationId;

  DropOffCubit(this._repository) : super(const DropOffState.initial());

  Future<void> getDropOffTasks() async {
    emit(const DropOffState.loading('جاري تحميل مهام التسليم...'));
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) {
        emit(const DropOffState.error('لم يتم العثور على بيانات السائق'));
        return;
      }

      final tasks = await _repository.getDropOffTasks(driverId);
      emit(DropOffState.tasksLoaded(tasks: tasks));
    } catch (e) {
      emit(DropOffState.error(e.toString()));
    }
  }

  void proceedToScanBags(ClientTaskModel selectedTask) {
    // Extract all bags from the tasks inside the selected group
    final List<SampleSummaryModel> allBags = [];
    if (selectedTask.tasks != null) {
      for (var taskItem in selectedTask.tasks!) {
        if (taskItem.samplesSummary != null) {
          allBags.addAll(taskItem.samplesSummary!);
        }
      }
    }

    // Remove duplicates by bagCode
    final Map<String, SampleSummaryModel> uniqueBagsMap = {};
    for (var bag in allBags) {
      uniqueBagsMap[bag.bagCode] = bag;
    }

    emit(DropOffState.scanningBags(
      selectedTask: selectedTask,
      remainingBags: uniqueBagsMap.values.toList(),
      scannedBags: const [],
      allBagsScanned: uniqueBagsMap.isEmpty,
    ));
  }

  Future<void> checkLocation(ClientTaskModel selectedTask, String scannedLocationBarcode) async {
    emit(const DropOffState.loading('جاري التحقق من الموقع...'));
    try {
      final parts = scannedLocationBarcode.split('-');
      if (parts.length != 2 || parts[1].toLowerCase() != 'location') {
        throw Exception('رمز الموقع غير صالح');
      }
      
      final locationId = int.tryParse(parts[0]);
      if (locationId == null) {
        throw Exception('رقم الموقع غير صالح');
      }

      List<int> taskIds = selectedTask.tasks?.map((t) => t.id).toList() ?? [];
      await _repository.checkDropOffLocation(
        taskIds: taskIds,
        toLocationId: locationId,
      );

      // Save the location ID globally if needed
      _scannedLocationId = locationId;

      emit(const DropOffState.locationCheckSuccess());
    } catch (e) {
      emit(DropOffState.error(e.toString()));
    }
  }

  Future<void> checkTaskToken(ClientTaskModel selectedTask, String scannedToken) async {
    emit(const DropOffState.loading('جاري التحقق من التوكن...'));
    try {
      final locationId = _scannedLocationId ?? 0;

      List<int> taskIds = selectedTask.tasks?.map((t) => t.id).toList() ?? [];
      await _repository.checkDropOffLocation(
        taskIds: taskIds,
        toLocationId: locationId,
        takasiNumber: scannedToken,
      );

      emit(const DropOffState.locationCheckSuccess());
    } catch (e) {
      emit(DropOffState.error(e.toString()));
    }
  }

  void scanBagToDeliver(String bagCode) {
    state.maybeWhen(
      scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) {
        final index = remainingBags.indexWhere((bag) => bag.bagCode.toLowerCase() == bagCode.toLowerCase());
        
        if (index >= 0) {
          final matchedBag = remainingBags[index];
          final updatedRemaining = List<SampleSummaryModel>.from(remainingBags)..removeAt(index);
          final updatedScanned = List<SampleSummaryModel>.from(scannedBags)..add(matchedBag);
          
          emit(DropOffState.scanningBags(
            selectedTask: selectedTask,
            remainingBags: updatedRemaining,
            scannedBags: updatedScanned,
            allBagsScanned: updatedRemaining.isEmpty,
          ));
        } else {
          // If the bag code is not in remaining bags, it might have been already scanned or it's invalid
          emit(const DropOffState.error('عذراً، هذا الكيس غير مطلوب لهذه الوجهة أو تم مسحه بالفعل.'));
          // Restore the scanning state
          emit(DropOffState.scanningBags(
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

  void proceedToSignature() {
    state.maybeWhen(
      scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) {
        if (allBagsScanned) {
          emit(DropOffState.signatureReady(
            selectedTask: selectedTask,
            scannedBags: scannedBags,
            isSubmitting: false,
          ));
        }
      },
      orElse: () {},
    );
  }

  Future<void> submitDropOffTasks(List<int>? signatureBytes) async {
    await state.maybeWhen(
      signatureReady: (selectedTask, scannedBags, isSubmitting) async {
        emit(DropOffState.signatureReady(
          selectedTask: selectedTask,
          scannedBags: scannedBags,
          isSubmitting: true,
        ));

        // Extract task IDs from the grouped tasks
        List<int> taskIds = [];
        if (selectedTask.tasks != null) {
          taskIds = selectedTask.tasks!.map((t) => t.id).toList();
        }

        try {
          await _repository.closeDropOffTasks(taskIds, signatureBytes);
          emit(const DropOffState.closeTasksSuccess());
        } catch (e) {
          emit(DropOffState.error(e.toString()));
          emit(DropOffState.signatureReady(
            selectedTask: selectedTask,
            scannedBags: scannedBags,
            isSubmitting: false,
          ));
        }
      },
      orElse: () async {},
    );
  }
}
