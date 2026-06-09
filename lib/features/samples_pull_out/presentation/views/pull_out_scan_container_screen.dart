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
import '../../../../core/common/widgets/app_scanner_screen.dart';

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

  void _onScanContainerBarcode() async {
    final String? scannedBarcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppScannerScreen()),
    );
    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      setState(() {
        _containerController.text = scannedBarcode;
      });
      _onManualContainerSubmit();
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

                    // Scanner Button
                    SizedBox(
                      width: double.infinity,
                      child: AppElevatedButton(
                        text: isArabic ? 'مسح الحاوية بالماسح' : 'SCAN CONTAINER',
                        onPressed: _onScanContainerBarcode,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (!isContainerValidated) ...[

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
