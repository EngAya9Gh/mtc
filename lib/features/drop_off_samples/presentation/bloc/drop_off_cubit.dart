import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../../samples_pull_out/data/models/client_task_model.dart';
import '../../domain/repositories/drop_off_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/services/background/background_location_service.dart';
import 'drop_off_state.dart';

class DropOffCubit extends Cubit<DropOffState> {
  final DropOffRepository _repository;

  int? _scannedLocationId;

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

  DropOffCubit(this._repository) : super(const DropOffState.initial());

  Future<void> getDropOffTasks() async {
    if (!isClosed) emit(const DropOffState.loading(AppStrings.loadingDropOffTasks));
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) {
        if (!isClosed) emit(const DropOffState.error(AppStrings.driverDataNotFound));
        return;
      }

      final tasks = await _repository.getDropOffTasks(driverId);
      if (!isClosed) emit(DropOffState.tasksLoaded(tasks: tasks));
    } catch (e) {
      if (!isClosed) emit(DropOffState.error(e.toString()));
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
    emit(const DropOffState.loading('verifying_location'));
    try {
      final parts = scannedLocationBarcode.split('-');
      if (parts.length != 2 || parts[1].toLowerCase() != 'location') {
        throw Exception('invalid_location_code');
      }
      
      final locationId = int.tryParse(parts[0]);
      if (locationId == null) {
        throw Exception('invalid_location_number');
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
    emit(const DropOffState.loading('verifying_token'));
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
          // If the bag code is already scanned, silently ignore it
          final isAlreadyScanned = scannedBags.any((bag) => bag.bagCode?.toLowerCase() == bagCode.toLowerCase());
          if (!isAlreadyScanned) {
            if (!_isRecentInvalidScan(bagCode)) {
              emit(const DropOffState.error('bag_not_required'));
              // Restore the scanning state
              emit(DropOffState.scanningBags(
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
          final apiClient = GetIt.instance<ApiClient>();
          double currentLat = 0.0;
          double currentLng = 0.0;

            if (apiClient.isDebugMode) {
              currentLat = selectedTask.toLocationLat ?? 0.0;
              currentLng = selectedTask.toLocationLng ?? 0.0;
            } else {
              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
              if (!serviceEnabled) throw Exception('enable_gps_service');
              
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied) throw Exception('grant_location_permission');
              }
              if (permission == LocationPermission.deniedForever) {
                throw Exception('location_permission_denied_forever');
              }

              try {
                final p = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                  timeLimit: const Duration(seconds: 10),
                );
                currentLat = p.latitude;
                currentLng = p.longitude;
              } catch (e) {
                throw Exception('failed_get_current_location');
              }
            }

            await _repository.closeDropOffTasks(taskIds, signatureBytes, currentLat, currentLng);
            if (!isClosed) emit(const DropOffState.closeTasksSuccess());
          } catch (e) {
            String errorMessage = e.toString();
            if (errorMessage.startsWith('Exception: ')) {
              errorMessage = errorMessage.substring(11);
            }
            if (!isClosed) emit(DropOffState.error(errorMessage));
            if (!isClosed) emit(DropOffState.signatureReady(
              selectedTask: selectedTask,
              scannedBags: scannedBags,
              isSubmitting: false,
            ));
          }
      },
      orElse: () async {},
    );
  }

  Future<void> reachDropOffLocation(ClientTaskModel selectedTask) async {
    if (!isClosed) emit(const DropOffState.loading('confirming_location_arrival'));
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) throw Exception('driver_data_not_found');
      final locationId = selectedTask.toLocation;
      if (locationId == null) throw Exception('unknown_location');

      List<int> taskIds = selectedTask.tasks?.map((t) => t.id).toList() ?? [];
      if (taskIds.isEmpty) taskIds = selectedTask.taskIds ?? [];

      final apiClient = GetIt.instance<ApiClient>();
      double currentLat = 0.0;
      double currentLng = 0.0;

      if (apiClient.isDebugMode) {
        currentLat = selectedTask.toLocationLat ?? 0.0;
        currentLng = selectedTask.toLocationLng ?? 0.0;
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('enable_gps_service');
        
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) throw Exception('grant_location_permission');
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception('location_permission_denied_forever');
        }

        try {
          final p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          currentLat = p.latitude;
          currentLng = p.longitude;
        } catch (e) {
          throw Exception('failed_get_current_location');
        }
      }

      await _repository.confirmToLocation(driverId, locationId, taskIds, currentLat, currentLng);
      
      // Refresh the list to get updated status
      if (!isClosed) emit(const DropOffState.locationCheckSuccess());
      if (!isClosed) getDropOffTasks(); 
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(DropOffState.error(errorMessage));
      getDropOffTasks(); 
    }
  }
}
