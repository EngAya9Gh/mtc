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
import '../bloc/pull_out_state.dart';
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
        backgroundColor: Colors.white,
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
                        : _buildBagRemovalView(context, isArabic, currentContainerBags, isRemoving),
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
                      text: isArabic ? 'مسح ثلاجة أخرى' : 'SCAN ANOTHER FREEZER',
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

  Widget _buildBagRemovalView(
    BuildContext context, 
    bool isArabic, 
    List<SampleSummaryModel> currentContainerBags,
    bool isRemoving,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                      Icons.qr_code_scanner,
                      size: 56,
                      color: AppColors.secondary.withOpacity(0.8),
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      isArabic ? 'وجّه الكاميرا لمسح كيس العينة لإزالته' : 'Point camera to scan bag to remove',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
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

          // Manual text field for bags
          TextField(
            controller: _bagController,
            decoration: InputDecoration(
              hintText: isArabic ? 'أو أدخل باركود الكيس يدوياً لإزالته' : 'Or type bag barcode to remove',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _onManualBagSubmit,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Simulate button for testing
          if (currentContainerBags.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.bug_report),
              label: AppText(isArabic ? 'مسح الكيس الأول وهمياً' : 'Mock scan first bag'),
              onPressed: () {
                _bagController.text = currentContainerBags.first.bagCode;
                _onManualBagSubmit();
              },
            ),
            
          const SizedBox(height: 24),

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
                  '${currentContainerBags.length}',
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
            itemCount: currentContainerBags.length,
            itemBuilder: (context, index) {
              final bag = currentContainerBags[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppText(
                        bag.bagCode,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText(
                        bag.temperatureType,
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
