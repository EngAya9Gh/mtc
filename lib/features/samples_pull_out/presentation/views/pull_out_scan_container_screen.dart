import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../data/models/client_task_model.dart';
import '../bloc/pull_out_cubit.dart';
import '../bloc/pull_out_state.dart';

class PullOutScanContainerScreen extends StatelessWidget {
  final ClientTaskModel destination;

  const PullOutScanContainerScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PullOutCubit>()..selectTask(destination),
      child: const _PullOutScanContainerScreenView(),
    );
  }
}

class _PullOutScanContainerScreenView extends StatefulWidget {
  const _PullOutScanContainerScreenView();

  @override
  State<_PullOutScanContainerScreenView> createState() => _PullOutScanContainerScreenViewState();
}

class _PullOutScanContainerScreenViewState extends State<_PullOutScanContainerScreenView> {
  final TextEditingController _containerController = TextEditingController();

  @override
  void dispose() {
    _containerController.dispose();
    super.dispose();
  }

  void _onManualContainerSubmit() {
    final code = _containerController.text.trim();
    if (code.isNotEmpty) {
      context.read<PullOutCubit>().validateContainer(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'مسح الحاوية' : 'Scan Container'),
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
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
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
              final destinationName = isArabic 
                  ? (selectedTask.arabicName ?? selectedTask.name ?? 'وجهة غير معروفة')
                  : (selectedTask.englishName ?? selectedTask.name ?? 'Unknown Destination');

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Task Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleLarge(
                            destinationName,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            '${isArabic ? "إجمالي الأكياس المتبقية للوجهة:" : "Total Bags Left for Destination:"} ${allDestinationBags.length}',
                            style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Camera simulation box
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isContainerValidated ? Colors.green : AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (isContainerValidated ? Colors.green : AppColors.primary).withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isContainerValidated ? Icons.check_circle : Icons.qr_code_scanner,
                                size: 70,
                                color: (isContainerValidated ? Colors.green : AppColors.primary).withOpacity(0.8),
                              ),
                              const SizedBox(height: 16),
                              AppText(
                                isContainerValidated
                                    ? (isArabic ? 'تم التحقق من الحاوية بنجاح' : 'Container Verified Successfully')
                                    : (isArabic ? 'وجّه الكاميرا نحو باركود الحاوية' : 'Point camera to container barcode'),
                                style: TextStyle(
                                  color: isContainerValidated ? Colors.green.shade200 : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isContainerValidated ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          if (!isContainerValidated)
                            Positioned(
                              top: 110,
                              left: 30,
                              right: 30,
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
                    const SizedBox(height: 32),

                    if (!isContainerValidated) ...[
                      // Manual Input
                      TextField(
                        controller: _containerController,
                        decoration: InputDecoration(
                          hintText: isArabic ? 'أو أدخل باركود الحاوية يدوياً' : 'Or type container barcode manually',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                            onPressed: _onManualContainerSubmit,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final containerIdsFromBags = allDestinationBags
                              .map((b) => b.containerId)
                              .whereType<int>()
                              .toSet()
                              .toList();
                          final carContainerIds = UserInfo()
                                  .carInfo
                                  ?.containers
                                  ?.map((c) => c.id)
                                  .whereType<int>()
                                  .toSet()
                                  .toList() ??
                              [];
                          final uniqueContainerIds = <int>{
                            ...containerIdsFromBags,
                            ...carContainerIds
                          }.toList();

                          if (uniqueContainerIds.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                child: AppText(
                                  isArabic ? 'حاويات للتجربة والاختبار:' : 'Test containers available:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ),
                              ...uniqueContainerIds.map((id) {
                                final inCar = carContainerIds.contains(id);
                                final bagCount = allDestinationBags.where((b) => b.containerId == id || b.containerId == null).length;

                                String label = '';
                                if (inCar) {
                                  label = isArabic
                                      ? 'حاوية سيارتك: $id-container ($bagCount أكياس)'
                                      : 'Car container: $id-container ($bagCount bags)';
                                } else {
                                  label = isArabic
                                      ? 'حاوية اختبار (غير مسجلة): $id-container ($bagCount أكياس)'
                                      : 'Mock container (unregistered): $id-container ($bagCount bags)';
                                }

                                return TextButton.icon(
                                  key: ValueKey('mock_container_$id'),
                                  icon: const Icon(Icons.bug_report, color: AppColors.secondary),
                                  label: AppText(
                                    label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () {
                                    _containerController.text = '$id-container';
                                    _onManualContainerSubmit();
                                  },
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      // Success Info Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    isArabic ? 'رقم الحاوية:' : 'Container ID:',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  AppText(
                                    scannedContainerId ?? '',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  AppText(
                                    '${isArabic ? "النوع:" : "Type:"} ${scannedContainerType ?? ""}',
                                    style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      AppElevatedButton(
                        text: isArabic ? 'PROCEED / متابعة' : 'PROCEED',
                        onPressed: () {
                          context.push(
                            AppRouter.pullOutRemoveBags,
                            extra: context.read<PullOutCubit>(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          context.read<PullOutCubit>().resetContainerScan();
                          _containerController.clear();
                        },
                        child: AppText(
                          isArabic ? 'RESCAN / إعادة المسح' : 'RESCAN',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
