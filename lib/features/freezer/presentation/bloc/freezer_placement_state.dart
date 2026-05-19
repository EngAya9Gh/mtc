import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/bag_item_model.dart';

part 'freezer_placement_state.freezed.dart';

@freezed
class FreezerPlacementState with _$FreezerPlacementState {
  const factory FreezerPlacementState.initial() = _Initial;
  const factory FreezerPlacementState.loading(String message) = _Loading;
  const factory FreezerPlacementState.error(String message) = _Error;
  const factory FreezerPlacementState.success(String message) = _Success;
  const factory FreezerPlacementState.closeFreezerSuccess() = _CloseFreezerSuccess;
  
  const factory FreezerPlacementState.placementState({
    required List<BagItemModel> originalBags,
    required List<BagItemModel> remainingRoomBags,
    required List<BagItemModel> remainingRefBags,
    required List<BagItemModel> remainingFrzBags,
    
    // Scan details
    required String? selectedContainerType, // "ROOM" | "REF" | "FRZ"
    required String? selectedContainerQrCode, // e.g. "5-container"
    required bool isContainerValidated,
    
    // UI details
    required bool isContainerScanMode, // true if scanning container, false if scanning bags
    required List<String> savedCategories, // e.g. ["ROOM"]
    required bool allFinished,
    @Default(false) bool isSaving,
  }) = PlacementState;
}
