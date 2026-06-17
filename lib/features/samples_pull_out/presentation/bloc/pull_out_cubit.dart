import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/samples_pull_out_repository.dart';
import 'pull_out_state.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../data/models/client_task_model.dart';

class PullOutCubit extends Cubit<PullOutState> {
  final SamplesPullOutRepository _repository;

  PullOutCubit(this._repository) : super(const PullOutState.initial());

  ClientTaskModel? _selectedTask;
  List<SampleSummaryModel> _allDestinationBags = [];
  List<SampleSummaryModel> _currentContainerBags = [];
  List<SampleSummaryModel> _scannedBagsToRemove = [];
  String? _scannedContainerId;
  String? _scannedContainerType;
  bool _isContainerValidated = false;
  bool _isContainerScanMode = true;

  void loadTasks() async {
    emit(const PullOutState.loading('جاري جلب المهام...'));
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) {
        emit(const PullOutState.error('بيانات السائق غير متوفرة'));
        return;
      }
      final tasks = await _repository.getInFreezerTasks(driverId);
      emit(PullOutState.tasksLoaded(tasks: tasks));
    } catch (e, stackTrace) {
      print('=== ERROR IN loadTasks ===');
      print(e.toString());
      print(stackTrace.toString());
      emit(PullOutState.error(e.toString()));
    }
  }

  void selectTask(ClientTaskModel task) {
    _selectedTask = task;
    _scannedContainerId = null;
    _scannedContainerType = null;
    _isContainerValidated = false;
    _isContainerScanMode = true;
    _allDestinationBags = [];
    _currentContainerBags = [];
    _scannedBagsToRemove = [];

    // Build bag list using bag ID for deduplication to avoid losing bags in containers
    // A bag with the same bagCode can appear with containerId=null AND with a real containerId
    // We must keep ALL entries by their unique ID so we don't miss bags still in containers
    final Map<int, SampleSummaryModel> seenBagIds = {};
    for (var groupedTask in task.tasks) {
      for (var bag in groupedTask.samplesSummary) {
        seenBagIds[bag.id] = bag;
      }
    }
    _allDestinationBags = seenBagIds.values.toList();

    _emitCurrentState();
  }

  void validateContainer(String barcode) {
    if (_selectedTask == null) return;
    
    // Example barcode: "12-container"
    final parts = barcode.split('-');
    if (parts.length < 2 || parts[1].toLowerCase() != 'container') {
      emit(const PullOutState.error('باركود الحاوية غير صالح. يجب أن ينتهي بـ -container'));
      _emitCurrentState();
      return;
    }

    final String extractedIdStr = parts[0];
    final int? extractedId = int.tryParse(extractedIdStr);
    
    if (extractedId == null) {
      emit(const PullOutState.error('رقم الحاوية غير صحيح.'));
      _emitCurrentState();
      return;
    }

    final matchedBags = _allDestinationBags.where((b) => b.containerId == extractedId).toList();
    if (matchedBags.isEmpty) {
      final containers = UserInfo().carInfo?.containers;
      final matchedContainer = containers?.where((c) => c.id == extractedId).toList();
      String containerName = extractedIdStr;
      if (matchedContainer != null && matchedContainer.isNotEmpty) {
        containerName = '${matchedContainer.first.type ?? "ROOM"} #$extractedIdStr';
      }
      emit(PullOutState.error('الحاوية ($containerName) لا تحتوي على أكياس لهذه الوجهة!'));
      _emitCurrentState();
      return;
    }

    final containers = UserInfo().carInfo?.containers;
    if (containers == null || containers.isEmpty) {
      emit(const PullOutState.error('لا توجد حاويات مسجلة لسيارتك. يرجى تحديث البيانات.'));
      _emitCurrentState();
      return;
    }

    final matched = containers.where((c) => c.id == extractedId).toList();
    if (matched.isEmpty) {
      // If it has bags, we allow it for testing/flexibility, but log a warning
      print('=== WARNING: Scanned container $extractedId is not registered in car containers, but contains bags for this task! ===');
    }

    _scannedContainerId = extractedIdStr;
    _scannedContainerType = matched.isNotEmpty 
        ? (matched.first.type ?? 'ROOM')
        : (matchedBags.isNotEmpty ? matchedBags.first.temperatureType : 'ROOM');
    _isContainerValidated = true;

    emit(const PullOutState.success('تم التحقق من الحاوية بنجاح!'));
    _emitCurrentState();
  }

  void proceedToBags() {
    if (!_isContainerValidated || _selectedTask == null) return;
    if (_scannedContainerId == null) return;
    
    _isContainerScanMode = false;
    
    final int containerId = int.parse(_scannedContainerId!);
    _currentContainerBags = _allDestinationBags.where((b) => b.containerId == containerId).toList();
    
    _emitCurrentState();
  }

  void scanBagToRemove(String bagCode) {
    if (_selectedTask == null || _scannedContainerId == null) return;

    final matchingBags = _currentContainerBags.where((b) => b.bagCode == bagCode).toList();
    if (matchingBags.isEmpty) {
      emit(const PullOutState.error('هذا الكيس غير موجود في هذه الحاوية!'));
      _emitCurrentState();
      return;
    }
    
    // Check if already scanned
    if (_scannedBagsToRemove.any((b) => b.bagCode == bagCode)) {
      emit(const PullOutState.error('تم مسح هذا الكيس مسبقاً!'));
      _emitCurrentState();
      return;
    }

    _scannedBagsToRemove.add(matchingBags.first);
    _emitCurrentState();
  }

  void confirmRemoveBags() async {
    if (_selectedTask == null || _scannedContainerId == null || _scannedBagsToRemove.isEmpty) return;

    _emitCurrentState(isRemoving: true);

    try {
      final uniqueTaskIds = _scannedBagsToRemove.map((b) => b.taskId ?? 0).where((id) => id != 0).toSet().toList();
      final bagCodes = _scannedBagsToRemove.map((b) => b.bagCode ?? '').where((c) => c.isNotEmpty).toList();

      final response = await _repository.removeBagsFromContainer(
        taskIds: uniqueTaskIds,
        bagCodes: bagCodes,
        containerId: _scannedContainerId!,
      );

      final removedBagsRaw = response['removed_bags'] as List<dynamic>? ?? [];
      final removedBags = removedBagsRaw.map((e) => e.toString()).toList();
      final failedBagsRaw = response['failed_bags'] as List<dynamic>? ?? [];
      final failedBags = failedBagsRaw.map((e) => e.toString()).toList();

      for (final code in removedBags) {
        final containerId = int.tryParse(_scannedContainerId ?? '');
        _currentContainerBags.removeWhere((b) => b.bagCode == code);
        _allDestinationBags.removeWhere((b) => b.bagCode == code && b.containerId == containerId);
      }
      
      _scannedBagsToRemove.clear();

      String msg = 'تم الإرسال والتأكيد بنجاح!';
      if (failedBags.isNotEmpty) {
        msg += '\nفشل إزالة بعض الأكياس: ${failedBags.join(", ")}';
      }

      emit(PullOutState.success(msg));
      _emitCurrentState();
    } catch (e, stackTrace) {
      print('=== ERROR IN confirmRemoveBags ===');
      print(e.toString());
      print(stackTrace.toString());
      emit(PullOutState.error(e.toString()));
      _emitCurrentState();
    }
  }

  void resetContainerScan() {
    _scannedContainerId = null;
    _scannedContainerType = null;
    _isContainerValidated = false;
    _isContainerScanMode = true;
    _currentContainerBags = [];
    _scannedBagsToRemove = [];
    _emitCurrentState();
  }

  void closeTasks() async {
    if (_selectedTask == null) return;

    final bagsInContainers = _allDestinationBags.where((b) => b.containerId != null).toList();
    if (bagsInContainers.isNotEmpty) {
      emit(const PullOutState.error('يرجى سحب جميع الأكياس من كافة الحاويات قبل إغلاق المهام.'));
      _emitCurrentState();
      return;
    }

    emit(const PullOutState.loading('جاري إغلاق المهام...'));
    try {
      // The destination card has multiple taskIds associated with it
      await _repository.closeInFreezerTasks(_selectedTask!.taskIds);
      emit(const PullOutState.closeTasksSuccess());
    } catch (e, stackTrace) {
      print('=== ERROR IN closeTasks ===');
      print(e.toString());
      print(stackTrace.toString());
      emit(PullOutState.error(e.toString()));
      _emitCurrentState();
    }
  }

  void _emitCurrentState({bool isRemoving = false}) {
    if (_selectedTask == null) return;
    
    final allFinished = _allDestinationBags.where((b) => b.containerId != null).isEmpty;
    final hasBagsInOtherContainers = !allFinished && _currentContainerBags.isEmpty;

    emit(PullOutState.pullOutState(
      selectedTask: _selectedTask!,
      allDestinationBags: List.from(_allDestinationBags),
      currentContainerBags: List.from(_currentContainerBags),
      scannedBagsToRemove: List.from(_scannedBagsToRemove),
      scannedContainerId: _scannedContainerId,
      scannedContainerType: _scannedContainerType,
      isContainerValidated: _isContainerValidated,
      isContainerScanMode: _isContainerScanMode,
      allFinished: allFinished,
      hasBagsInOtherContainers: hasBagsInOtherContainers,
      isRemoving: isRemoving,
    ));
  }
}
