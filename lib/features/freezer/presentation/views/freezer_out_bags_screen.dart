import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../medical_tasks/data/models/task_model.dart';
import '../bloc/freezer_placement_cubit.dart';
import '../bloc/freezer_placement_state.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../data/models/bag_item_model.dart';
import '../../../../core/common/widgets/app_scanner_screen.dart';

class FreezerOutBagsScreen extends StatelessWidget {
  final MedicalTask task;

  const FreezerOutBagsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FreezerPlacementCubit>()..loadBags(task.id),
      child: _FreezerOutBagsScreenView(task: task),
    );
  }
}

class _FreezerOutBagsScreenView extends StatefulWidget {
  final MedicalTask task;

  const _FreezerOutBagsScreenView({required this.task});

  @override
  State<_FreezerOutBagsScreenView> createState() => _FreezerOutBagsScreenViewState();
}

class _FreezerOutBagsScreenViewState extends State<_FreezerOutBagsScreenView> {
  final TextEditingController _containerController = TextEditingController();
  final TextEditingController _bagController = TextEditingController();

  @override
  void dispose() {
    _containerController.dispose();
    _bagController.dispose();
    super.dispose();
  }

  void _onSimulateContainerScan(String currentTemp) async {
    final String? scannedBarcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppScannerScreen()),
    );
    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      setState(() {
        _containerController.text = scannedBarcode;
      });
      if (mounted) {
        context.read<FreezerPlacementCubit>().validateContainer(scannedBarcode);
      }
    }
  }

  void _onSimulateBagScan(List<BagItemModel> remainingBags) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppScannerScreen(multiScan: true, allowDuplicates: true, title: 'Scan Bags to Freezer')),
    );
    if (result is List<String> && result.isNotEmpty) {
      for (final code in result) {
        if (mounted) {
          context.read<FreezerPlacementCubit>().scanBag(code);
        }
      }
    } else if (result is String && result.isNotEmpty) {
      setState(() {
        _bagController.text = result;
      });
      if (mounted) {
        context.read<FreezerPlacementCubit>().scanBag(result);
      }
    }
  }

  void _onManualContainerSubmit() {
    final code = _containerController.text.trim();
    if (code.isNotEmpty) {
      context.read<FreezerPlacementCubit>().validateContainer(code);
    }
  }

  void _onManualBagSubmit() {
    final code = _bagController.text.trim();
    if (code.isNotEmpty) {
      final success = context.read<FreezerPlacementCubit>().scanBag(code);
      if (success) {
        _bagController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              AppLocalizations.of(context).isArabic 
                  ? 'تم مسح الكيس بنجاح' 
                  : 'Bag scanned successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              AppLocalizations.of(context).isArabic 
                  ? 'خطأ: الكيس لا ينتمي لفئة الحرارة النشطة' 
                  : 'Error: Bag does not belong to active temperature category',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Safe memory clear upon back press if needed
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: AppText(isArabic ? 'وضع العينات في الحاوية' : 'Samples Placement'),
          centerTitle: true,
          leading: IconButton(
            icon: AnimatedRotation(
              turns: isArabic ? 0.5 : 0.0,
              duration: Duration.zero,
              child: const Icon(Icons.arrow_back),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocConsumer<FreezerPlacementCubit, FreezerPlacementState>(
          listener: (context, state) {
            state.whenOrNull(
              success: (msg) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText(msg), backgroundColor: Colors.green),
                );
              },
              error: (err) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText(err), backgroundColor: Colors.red),
                );
              },
              closeFreezerSuccess: () {
                context.go(AppRouter.taskStatus, extra: {
                  'isSuccess': true,
                  'message': isArabic 
                      ? 'تم إغلاق وتأكيد كافة حاويات المهمة بنجاح.' 
                      : 'All task containers closed and confirmed successfully.',
                  'taskId': widget.task.id,
                });
              },
            );
          },
          builder: (context, state) {
            return state.maybeWhen(
              loading: (msg) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLoader(),
                    const SizedBox(height: 16),
                    AppText(msg),
                  ],
                ),
              ),
              error: (msg) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      AppText(msg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      AppElevatedButton(
                        text: isArabic ? 'إعادة المحاولة' : 'RETRY',
                        onPressed: () => context.read<FreezerPlacementCubit>().loadBags(widget.task.id),
                      )
                    ],
                  ),
                ),
              ),
              placementState: (
                originalBags,
                remainingRoomBags,
                remainingRefBags,
                remainingFrzBags,
                selectedContainerType,
                selectedContainerQrCode,
                isContainerValidated,
                isContainerScanMode,
                savedCategories,
                allFinished,
                isSaving,
              ) {

                return Column(
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleLarge(
                            widget.task.clientName,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.bodyMedium(
                                '${isArabic ? 'تاريخ المهمة:' : 'Date:'} ${widget.task.date ?? ""}',
                                color: Colors.grey,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AppText(
                                  widget.task.status,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (allFinished) ...[
                      // Final Close Container section
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 80,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 20),
                                      AppText.titleLarge(
                                        isArabic ? 'اكتمل وضع كافة العينات' : 'All samples placed',
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 12),
                                      AppText(
                                        isArabic 
                                            ? 'تم وضع كافة أكياس العينات بنجاح في الحاويات بالسيارة. يرجى إغلاق وتأكيد الحاوية لحفظ المهمة.'
                                            : 'All sample bags have been placed in the containers. Please close and confirm containers to complete the task.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.grey, height: 1.4),
                                      ),
                                      const SizedBox(height: 30),
                                      AppElevatedButton(
                                        text: isArabic ? 'إغلاق الحاويات' : 'CLOSE CONTAINERS',
                                        onPressed: () {
                                          _showCloseConfirmation(context, widget.task.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Temperature Tabs (Horizontal indicator bar)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (originalBags.any((b) => _isTempTypeMatch(b.temperatureType, 'ROOM')) && !savedCategories.contains('ROOM'))
                              _buildTempTab(
                                title: 'ROOM',
                                count: remainingRoomBags.length,
                                isActive: selectedContainerType == 'ROOM',
                              ),
                            if (originalBags.any((b) => _isTempTypeMatch(b.temperatureType, 'REF')) && !savedCategories.contains('REF'))
                              _buildTempTab(
                                title: 'REF',
                                count: remainingRefBags.length,
                                isActive: selectedContainerType == 'REF',
                              ),
                            if (originalBags.any((b) => _isTempTypeMatch(b.temperatureType, 'FRZ')) && !savedCategories.contains('FRZ'))
                              _buildTempTab(
                                title: 'FRZ',
                                count: remainingFrzBags.length,
                                isActive: selectedContainerType == 'FRZ',
                              ),
                          ],
                        ),
                      ),

                      // Main Section switcher (Container scan vs Bag scan)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: isContainerScanMode 
                              ? _buildContainerScanView(
                                  context: context, 
                                  currentTemp: selectedContainerType ?? 'ROOM',
                                  scannedQr: selectedContainerQrCode,
                                  isValidated: isContainerValidated,
                                  isArabic: isArabic,
                                )
                              : _buildBagScanView(
                                  context: context,
                                  currentTemp: selectedContainerType ?? 'ROOM',
                                  containerQr: selectedContainerQrCode ?? '',
                                  remainingBags: selectedContainerType == 'ROOM'
                                      ? remainingRoomBags
                                      : selectedContainerType == 'REF'
                                          ? remainingRefBags
                                          : remainingFrzBags,
                                  isArabic: isArabic,
                                  isSaving: isSaving,
                                ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              orElse: () => Center(
                child: AppText(isArabic ? 'لا توجد بيانات متاحة' : 'No data available'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTempTab({
    required String title,
    required int count,
    required bool isActive,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            AppText(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.white24 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppText(
                '$count',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerScanView({
    required BuildContext context,
    required String currentTemp,
    required String? scannedQr,
    required bool isValidated,
    required bool isArabic,
  }) {
    return Column(
      children: [
        // Camera simulation box
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    isArabic ? 'مسح باركود الحاوية' : 'Scan Container Barcode',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              // Laser animation simulator
              Positioned(
                top: 90,
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent, blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Scanner button
        SizedBox(
          width: double.infinity,
          child: AppElevatedButton(
            text: isArabic ? 'مسح حاوية' : 'SCAN CONTAINER',
            onPressed: () => _onSimulateContainerScan(currentTemp),
          ),
        ),
        const SizedBox(height: 20),



        // Validation banner
        if (scannedQr != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isValidated ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isValidated ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                Icon(
                  isValidated ? Icons.check_circle : Icons.error,
                  color: isValidated ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        isArabic ? 'باركود الحاوية الممسوحة:' : 'Scanned Container:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        scannedQr,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 30),

        // Save Container/Proceed Button
        if (isValidated)
          AppElevatedButton(
            text: isArabic ? 'حفظ الحاوية والمتابعة' : 'SAVE CONTAINER & PROCEED',
            onPressed: () {
              context.read<FreezerPlacementCubit>().saveContainer();
            },
          ),
      ],
    );
  }

  Widget _buildBagScanView({
    required BuildContext context,
    required String currentTemp,
    required String containerQr,
    required List<BagItemModel> remainingBags,
    required bool isArabic,
    required bool isSaving,
  }) {
    return Column(
      children: [
        // Container info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_open, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      isArabic ? 'الحاوية النشطة:' : 'Active Container:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                    ),
                    AppText(
                      '$containerQr ($currentTemp)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cached, color: Colors.grey),
                onPressed: () {
                  context.read<FreezerPlacementCubit>().resetContainerScan();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Camera simulation box for bags
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 56,
                    color: AppColors.secondary.withOpacity(0.8),
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    isArabic ? 'مسح أكياس عينات $currentTemp' : 'Scan $currentTemp bag barcodes',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Positioned(
                top: 80,
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent, blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scanner bag button
        SizedBox(
          width: double.infinity,
          child: AppElevatedButton(
            text: isArabic ? 'مسح كيس' : 'SCAN BAG',
            onPressed: () => _onSimulateBagScan(remainingBags),
          ),
        ),
        const SizedBox(height: 16),

        // Manual text field for bags
        TextField(
          controller: _bagController,
          decoration: InputDecoration(
            hintText: isArabic ? 'أدخل باركود الكيس يدوياً' : 'Or type bag barcode manually',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _onManualBagSubmit,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Remaining bags list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleLarge(
              isArabic ? 'الأكياس المتبقية للنوع الحالي' : 'Remaining Bags for Category',
              color: Colors.black87,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppText(
                '${remainingBags.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Remaining list
        if (remainingBags.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.done_all, size: 48, color: Colors.green.shade400),
                const SizedBox(height: 8),
                AppText(
                  isArabic ? 'اكتمل مسح جميع أكياس هذه الفئة!' : 'All bags for this category scanned!',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: remainingBags.length,
            itemBuilder: (context, index) {
              final bag = remainingBags[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppText(
                        bag.bagCode,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: AppText(
                        bag.temperatureType,
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

        const SizedBox(height: 24),

        // Save Bags Button (Only enabled/visible when active list is empty)
        if (remainingBags.isEmpty)
          AppElevatedButton(
            text: isArabic ? 'حفظ أكياس الحاوية' : 'SAVE BAGS',
            isLoading: isSaving,
            onPressed: () {
              _showSaveBagsConfirmation(context);
            },
          ),
      ],
    );
  }

  void _showSaveBagsConfirmation(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: AppText(isArabic ? 'حفظ الأكياس' : 'Save Bags'),
        content: AppText(
          isArabic 
              ? 'هل أنت متأكد من حفظ أكياس الحاوية وإرسالها للخادم؟' 
              : 'Are you sure you want to save container bags and send them to the server?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: AppText(isArabic ? 'إلغاء' : 'CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FreezerPlacementCubit>().saveBags(widget.task.id);
            },
            child: AppText(
              isArabic ? 'تأكيد' : 'CONFIRM',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseConfirmation(BuildContext context, int taskId) {
    final isArabic = AppLocalizations.of(context).isArabic;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: AppText(isArabic ? 'إغلاق الحاويات' : 'Close Containers'),
        content: AppText(
          isArabic 
              ? 'هل أنت متأكد من إغلاق كافة حاويات المهمة وتأكيد تسكين العينات؟' 
              : 'Are you sure you want to close all task containers and finalize sample placement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: AppText(isArabic ? 'إلغاء' : 'CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FreezerPlacementCubit>().closeFreezers(taskId);
            },
            child: AppText(
              isArabic ? 'إغلاق وتأكيد' : 'CLOSE & CONFIRM',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
