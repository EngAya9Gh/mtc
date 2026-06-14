import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/freezer_repository.dart';
import '../../data/models/bag_item_model.dart';
import 'freezer_placement_state.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../../auth/data/models/login_model.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/services/network/api_client.dart';

class FreezerPlacementCubit extends Cubit<FreezerPlacementState> {
  final FreezerRepository _freezerRepository;

  FreezerPlacementCubit(this._freezerRepository) : super(const FreezerPlacementState.initial());

  Future<void> loadBags(int taskId) async {
    emit(const FreezerPlacementState.loading('Loading bags...'));
    try {
      final bags = await _freezerRepository.getTaskBags(taskId);
      print('DEBUG: loadBags fetched ${bags.length} bags.');
      for (var b in bags) {
        print('DEBUG: bag code: ${b.bagCode}, temp type: ${b.temperatureType}');
      }
      
      // Remove duplicate bags locally by bagCode
      final uniqueBagsMap = <String, BagItemModel>{};
      for (var bag in bags) {
        uniqueBagsMap[bag.bagCode] = bag;
      }
      final uniqueBags = uniqueBagsMap.values.toList();
      print('DEBUG: uniqueBags count: ${uniqueBags.length}');

      final roomBags = uniqueBags.where((b) => _isTempTypeMatch(b.temperatureType, 'ROOM')).toList();
      final refBags = uniqueBags.where((b) => _isTempTypeMatch(b.temperatureType, 'REF')).toList();
      final frzBags = uniqueBags.where((b) => _isTempTypeMatch(b.temperatureType, 'FRZ')).toList();

      print('DEBUG: roomBags: ${roomBags.length}, refBags: ${refBags.length}, frzBags: ${frzBags.length}');

      String? initialTempType;
      if (roomBags.isNotEmpty) {
        initialTempType = 'ROOM';
      } else if (refBags.isNotEmpty) {
        initialTempType = 'REF';
      } else if (frzBags.isNotEmpty) {
        initialTempType = 'FRZ';
      }

      emit(FreezerPlacementState.placementState(
        originalBags: uniqueBags,
        remainingRoomBags: roomBags,
        remainingRefBags: refBags,
        remainingFrzBags: frzBags,
        selectedContainerType: initialTempType,
        selectedContainerQrCode: null,
        isContainerValidated: false,
        isContainerScanMode: true,
        savedCategories: const [],
        allFinished: false,
      ));
    } catch (e) {
      print('DEBUG: loadBags exception: $e');
      emit(FreezerPlacementState.error(e.toString()));
    }
  }

  bool validateContainer(String qrCode) {
    final currentState = state;
    if (currentState is! PlacementState) return false;

    if (qrCode.trim().isEmpty) return false;

    final targetTemp = currentState.selectedContainerType;
    if (targetTemp == null) return false;

    final containers = UserInfo().loginInfo?.car?.containers ?? [];
    ContainerData? matchedContainer;
    
    if (containers.isNotEmpty) {
      final scanned = qrCode.trim().toLowerCase();
      for (var c in containers) {
        if (c.imei?.trim().toLowerCase() == scanned || c.id.toString() == scanned) {
          matchedContainer = c;
          break;
        }
      }
    }

    if (matchedContainer == null) {
      emit(FreezerPlacementState.error('الحاوية غير موجودة أو غير مسجلة في عهدتك'));
      emit(currentState);
      return false;
    }

    final cType = (matchedContainer.type ?? '').toUpperCase();
    bool isValidTemp = false;
    if (targetTemp == 'ROOM' && (cType.contains('ROOM') || cType == 'RT')) isValidTemp = true;
    if (targetTemp == 'REF' && (cType.contains('REF') || cType.contains('REFRIG'))) isValidTemp = true;
    if (targetTemp == 'FRZ' && (cType.contains('FRZ') || cType.contains('FREEZ') || cType.contains('FROZEN'))) isValidTemp = true;

    if (!isValidTemp) {
      emit(FreezerPlacementState.error('الحاوية الممسوحة ($cType) لا تتطابق مع نوع العينات المطلوبة ($targetTemp)'));
      emit(currentState);
      return false;
    }

    emit(currentState.copyWith(
      selectedContainerQrCode: qrCode,
      isContainerValidated: true,
    ));
    return true;
  }

  void resetContainerScan() {
    final currentState = state;
    if (currentState is! PlacementState) return;

    emit(currentState.copyWith(
      selectedContainerQrCode: null,
      isContainerValidated: false,
      isContainerScanMode: true,
    ));
  }

  void saveContainer() {
    final currentState = state;
    if (currentState is! PlacementState) return;

    emit(currentState.copyWith(
      isContainerScanMode: false,
    ));
  }

  bool scanBag(String bagBarcode) {
    final currentState = state;
    if (currentState is! PlacementState) return false;

    final currentTemp = currentState.selectedContainerType;
    if (currentTemp == null) return false;

    List<BagItemModel> activeBags = [];
    if (currentTemp == 'ROOM') {
      activeBags = List.from(currentState.remainingRoomBags);
    } else if (currentTemp == 'REF') {
      activeBags = List.from(currentState.remainingRefBags);
    } else if (currentTemp == 'FRZ') {
      activeBags = List.from(currentState.remainingFrzBags);
    }

    final index = activeBags.indexWhere((b) => b.bagCode.trim() == bagBarcode.trim());
    if (index != -1) {
      activeBags.removeAt(index);
      
      if (currentTemp == 'ROOM') {
        emit(currentState.copyWith(remainingRoomBags: activeBags));
      } else if (currentTemp == 'REF') {
        emit(currentState.copyWith(remainingRefBags: activeBags));
      } else if (currentTemp == 'FRZ') {
        emit(currentState.copyWith(remainingFrzBags: activeBags));
      }
      return true;
    }

    return false;
  }

  Future<void> saveBags(int taskId) async {
    final currentState = state;
    if (currentState is! PlacementState) return;

    final currentTemp = currentState.selectedContainerType;
    final qrCode = currentState.selectedContainerQrCode;
    if (currentTemp == null || qrCode == null) return;

    // Get scanned bags for this temp: original bags of this temp that are NOT in remaining
    final originalForTemp = currentState.originalBags
        .where((b) => _isTempTypeMatch(b.temperatureType, currentTemp))
        .map((b) => b.bagCode)
        .toList();

    final remainingForTemp = (currentTemp == 'ROOM'
            ? currentState.remainingRoomBags
            : currentTemp == 'REF'
                ? currentState.remainingRefBags
                : currentState.remainingFrzBags)
        .map((b) => b.bagCode)
        .toSet();

    final scannedBagCodes = originalForTemp.where((code) => !remainingForTemp.contains(code)).toList();

    if (scannedBagCodes.isEmpty) {
      emit(const FreezerPlacementState.error('No bags scanned for this container.'));
      emit(currentState); // restore state
      return;
    }

    emit(currentState.copyWith(isSaving: true));

    try {
      await _freezerRepository.submitAllSamples(
        taskId: taskId,
        containerBarcode: qrCode,
        bagCodes: scannedBagCodes,
      );

      // Add currentTemp to saved categories
      final updatedSaved = List<String>.from(currentState.savedCategories);
      if (!updatedSaved.contains(currentTemp)) {
        updatedSaved.add(currentTemp);
      }

      // Check which categories are required
      final hasRoom = currentState.originalBags.any((b) => _isTempTypeMatch(b.temperatureType, 'ROOM'));
      final hasRef = currentState.originalBags.any((b) => _isTempTypeMatch(b.temperatureType, 'REF'));
      final hasFrz = currentState.originalBags.any((b) => _isTempTypeMatch(b.temperatureType, 'FRZ'));

      final roomFinished = !hasRoom || updatedSaved.contains('ROOM');
      final refFinished = !hasRef || updatedSaved.contains('REF');
      final frzFinished = !hasFrz || updatedSaved.contains('FRZ');

      final allFinished = roomFinished && refFinished && frzFinished;

      if (!allFinished) {
        // Find next required category that is not yet saved
        String? nextTemp;
        if (hasRoom && !updatedSaved.contains('ROOM')) {
          nextTemp = 'ROOM';
        } else if (hasRef && !updatedSaved.contains('REF')) {
          nextTemp = 'REF';
        } else if (hasFrz && !updatedSaved.contains('FRZ')) {
          nextTemp = 'FRZ';
        }

        emit(currentState.copyWith(
          savedCategories: updatedSaved,
          selectedContainerType: nextTemp,
          selectedContainerQrCode: null,
          isContainerValidated: false,
          isContainerScanMode: true,
          allFinished: false,
          isSaving: false,
        ));
      } else {
        // All categories saved! Completed.
        emit(const FreezerPlacementState.success('All bags saved successfully. You can now close containers.'));
        emit(currentState.copyWith(
          savedCategories: updatedSaved,
          selectedContainerType: null,
          selectedContainerQrCode: null,
          isContainerValidated: false,
          isContainerScanMode: false,
          allFinished: true,
          isSaving: false,
        ));
      }
    } catch (e) {
      emit(FreezerPlacementState.error('Save failed: $e'));
      // Reload the bags to previous state (reloadTheBags):
      // Restore remaining lists to their original state for this category
      final originalForTempObjects = currentState.originalBags
          .where((b) => _isTempTypeMatch(b.temperatureType, currentTemp))
          .toList();

      if (currentTemp == 'ROOM') {
        emit(currentState.copyWith(
          remainingRoomBags: originalForTempObjects,
          selectedContainerQrCode: null,
          isContainerValidated: false,
          isContainerScanMode: true,
          isSaving: false,
        ));
      } else if (currentTemp == 'REF') {
        emit(currentState.copyWith(
          remainingRefBags: originalForTempObjects,
          selectedContainerQrCode: null,
          isContainerValidated: false,
          isContainerScanMode: true,
          isSaving: false,
        ));
      } else if (currentTemp == 'FRZ') {
        emit(currentState.copyWith(
          remainingFrzBags: originalForTempObjects,
          selectedContainerQrCode: null,
          isContainerValidated: false,
          isContainerScanMode: true,
          isSaving: false,
        ));
      }
    }
  }

  Future<void> closeFreezers(int taskId) async {
    emit(const FreezerPlacementState.loading('Closing containers...'));
    try {
      await _freezerRepository.closeFreezer(taskId);
      emit(const FreezerPlacementState.closeFreezerSuccess());
    } catch (e) {
      emit(FreezerPlacementState.error('Close failed: $e'));
      // Restore placementState state
      final currentState = state;
      if (currentState is PlacementState) {
        emit(currentState);
      }
    }
  }

  bool _isTempTypeMatch(String bTemp, String targetTemp) {
    final t = bTemp.trim().toUpperCase();
    if (targetTemp == 'ROOM') {
      return t == 'ROOM' ||
          t == 'ROOM TEMPERATURE' ||
          t == 'ROOM_TEMPERATURE' ||
          t == 'RT' ||
          t == 'R.T' ||
          t == 'NORMAL' ||
          t.contains('ROOM') ||
          t.contains('RT');
    } else if (targetTemp == 'REF') {
      return t == 'REFRIGERATE' ||
          t == 'REF' ||
          t == 'REFRIGERATOR' ||
          t == 'COLD' ||
          t == 'COOL' ||
          t.contains('REF') ||
          t.contains('REFRIG');
    } else if (targetTemp == 'FRZ') {
      return t == 'FROZEN' ||
          t == 'FRZ' ||
          t == 'FREEZER' ||
          t.contains('FRZ') ||
          t.contains('FREEZ') ||
          t.contains('FROZ');
    }
    return false;
  }
}
