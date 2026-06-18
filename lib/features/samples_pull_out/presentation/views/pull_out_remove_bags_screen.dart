import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/pull_out_cubit.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/utils/end_points.dart';
import '../bloc/pull_out_state.dart';
import '../../../../core/common/widgets/app_scanner_screen.dart';
import '../../data/models/client_task_model.dart';

class PullOutRemoveBagsScreen extends StatelessWidget {
  final PullOutCubit cubit;

  const PullOutRemoveBagsScreen({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit..proceedToBags(),
      child: const _PullOutRemoveBagsScreenView(),
    );
  }
}

class _PullOutRemoveBagsScreenView extends StatefulWidget {
  const _PullOutRemoveBagsScreenView();

  @override
  State<_PullOutRemoveBagsScreenView> createState() => _PullOutRemoveBagsScreenViewState();
}

class _PullOutRemoveBagsScreenViewState extends State<_PullOutRemoveBagsScreenView> {
  final TextEditingController _bagController = TextEditingController();

  @override
  void dispose() {
    _bagController.dispose();
    super.dispose();
  }

  void _onManualBagSubmit() {
    final code = _bagController.text.trim();
    if (code.isNotEmpty) {
      context.read<PullOutCubit>().scanBagToRemove(code);
      _bagController.clear();
    }
  }

  void _onScanBagBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AppScannerScreen(
        multiScan: true, 
        allowDuplicates: true, 
        title: AppLocalizations.of(context).isArabic ? 'مسح الأكياس للتحميل' : 'Scan Bags to Remove',
        scannedItemsTitle: AppLocalizations.of(context).isArabic ? 'الأكياس الممسوحة' : 'Scanned Bags',
        emptyMessage: AppLocalizations.of(context).isArabic ? 'لم يتم مسح أي كيس بعد' : 'No bags scanned yet',
      )),
    );
    if (result is List<String> && result.isNotEmpty) {
      for (final code in result) {
        context.read<PullOutCubit>().scanBagToRemove(code);
      }
    } else if (result is String && result.isNotEmpty) {
      setState(() {
        _bagController.text = result;
      });
      _onManualBagSubmit();
    }
  }

  void _showCloseConfirmation(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText.titleLarge(isArabic ? 'تأكيد الإغلاق' : 'Confirm Close'),
        content: AppText(
          isArabic 
              ? 'هل أنت متأكد من أنك تريد إغلاق هذه المهام؟ سيتم حفظ التغييرات وتحديث الحالة.'
              : 'Are you sure you want to close these tasks? Changes will be saved and status updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: AppText(isArabic ? 'إلغاء' : 'CANCEL', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PullOutCubit>().closeTasks();
            },
            child: AppText(isArabic ? 'تأكيد' : 'CONFIRM', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'سحب العينات' : 'Remove Bags'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<PullOutCubit, PullOutState>(
        listener: (context, state) {
          state.whenOrNull(
            error: (msg) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(msg), backgroundColor: Colors.red),
              );
            },
            success: (msg) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(msg), backgroundColor: Colors.green),
              );
            },
            closeTasksSuccess: () {
              context.go(AppRouter.taskStatus, extra: {
                'isSuccess': true,
                'message': isArabic 
                    ? 'تم إغلاق الحاويات بنجاح وانتهت عملية السحب.' 
                    : 'Freezers closed successfully and pull out is complete.',
                'taskId': null,
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
            pullOutState: (
              selectedTask,
              allDestinationBags,
              currentContainerBags,
              scannedBagsToRemove,
              scannedContainerId,
              scannedContainerType,
              isContainerValidated,
              isContainerScanMode,
              allFinished,
              hasBagsInOtherContainers,
              isRemoving,
            ) {
              return Column(
                children: [
                  // Active Container Info Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                isArabic ? 'الحاوية المفتوحة' : 'Open Container',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              AppText(
                                '$scannedContainerId ($scannedContainerType)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: currentContainerBags.isEmpty
                        ? _buildContainerFinishedView(context, isArabic, allFinished, hasBagsInOtherContainers)
                        : _buildBagRemovalView(context, isArabic, currentContainerBags, scannedBagsToRemove, isRemoving),
                  ),
                ],
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildContainerFinishedView(BuildContext context, bool isArabic, bool allFinished, bool hasBagsInOtherContainers) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppText.titleLarge(
                    isArabic ? 'اكتمل سحب عينات الحاوية' : 'Container Pull Out Complete',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    isArabic 
                        ? 'تم سحب جميع الأكياس من هذه الحاوية بنجاح.'
                        : 'All bags have been removed from this container successfully.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 32),

                  if (hasBagsInOtherContainers) ...[
                    // There are still bags in other containers!
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppText(
                              isArabic 
                                  ? 'تنبيه: لا يزال هناك أكياس لهذه الوجهة في ثلاجات أخرى.' 
                                  : 'Warning: There are still bags for this destination in other freezers.',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppElevatedButton(
                      text: isArabic ? 'مسح حاوية أخرى' : 'SCAN ANOTHER CONTAINER',
                      onPressed: () {
                        context.read<PullOutCubit>().resetContainerScan();
                        context.pop(); // Go back to the scanner screen
                      },
                    ),
                  ] else ...[
                    // Fully done
                    AppElevatedButton(
                      text: isArabic ? 'إغلاق المهام' : 'CLOSE TASKS',
                      onPressed: () => _showCloseConfirmation(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureBadge(String type) {
    Color bgColor;
    Color textColor;
    switch (type.toUpperCase()) {
      case 'ROOM':
      case 'ROOM_TEMP':
        bgColor = const Color(0xFFE8F5E9); // Soft Green
        textColor = const Color(0xFF2E7D32);
        break;
      case 'REFRIGERATE':
      case 'COLD':
        bgColor = const Color(0xFFE3F2FD); // Soft Blue
        textColor = const Color(0xFF1565C0);
        break;
      case 'FROZEN':
        bgColor = const Color(0xFFEDE7F6); // Soft Purple
        textColor = const Color(0xFF651FFF);
        break;
      default:
        bgColor = const Color(0xFFFFF3E0); // Soft Orange
        textColor = const Color(0xFFE65100);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText(
        type,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBagRemovalView(
    BuildContext context, 
    bool isArabic, 
    List<SampleSummaryModel> currentContainerBags,
    List<SampleSummaryModel> scannedBagsToRemove,
    bool isRemoving,
  ) {
    // Unique remaining bags count
    final uniqueRemainingBags = <String, SampleSummaryModel>{};
    for (var bag in currentContainerBags) {
      if (!uniqueRemainingBags.containsKey(bag.bagCode)) {
        uniqueRemainingBags[bag.bagCode!] = bag;
      }
    }
    
    // Unique scanned bags to display
    final displayScannedBags = scannedBagsToRemove.toSet().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Scanner Button
          SizedBox(
            width: double.infinity,
            child: AppElevatedButton(
              text: isArabic ? 'مسح الكيس بالماسح لإزالته' : 'SCAN BAG TO REMOVE',
              onPressed: _onScanBagBarcode,
            ),
          ),
          // Manual/Fake Scan Input for test env
          if (getIt<Dio>().options.baseUrl == EndPoints.debugBaseUrl) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bagController,
                    decoration: InputDecoration(
                      hintText: isArabic ? 'أو أدخل الباركود يدوياً' : 'Or enter barcode manually',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _onManualBagSubmit,
                  child: AppText(isArabic ? 'إضافة' : 'ADD', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Remaining bags list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                isArabic ? 'الأكياس المتبقية في هذه الحاوية' : 'Bags left in this container',
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  '${uniqueRemainingBags.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isRemoving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: uniqueRemainingBags.length,
            itemBuilder: (context, index) {
              final bag = uniqueRemainingBags.values.toList()[index];
              final isScanned = scannedBagsToRemove.any((b) => b.bagCode == bag.bagCode);
              return _buildBagCard(isArabic, bag, isScanned);
            },
          ),

          if (scannedBagsToRemove.isNotEmpty) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.read<PullOutCubit>().confirmRemoveBags(),
                child: AppText(
                  isArabic ? 'تأكيد إزالة الأكياس الممسوحة (${scannedBagsToRemove.length})' : 'CONFIRM REMOVE SCANNED BAGS (${scannedBagsToRemove.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildBagCard(bool isArabic, SampleSummaryModel bag, bool isScanned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isScanned ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isScanned ? Colors.green : Colors.grey.shade100, width: isScanned ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled Header for Task ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                AppText(
                  isArabic 
                      ? 'رقم المهمة: #${bag.taskId}' 
                      : 'Task ID: #${bag.taskId}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (isScanned)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ),
                _buildTemperatureBadge(bag.temperatureType ?? ''),
              ],
            ),
          ),
          
          // Card Body containing Bag Code
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        isArabic ? 'كود الكيس' : 'Bag Code',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        bag.bagCode ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
