import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/drop_off_cubit.dart';
import '../bloc/drop_off_state.dart';

class DropOffSignatureScreen extends StatelessWidget {
  final DropOffCubit cubit;

  const DropOffSignatureScreen({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: const _DropOffSignatureScreenView(),
    );
  }
}

class _DropOffSignatureScreenView extends StatefulWidget {
  const _DropOffSignatureScreenView();

  @override
  State<_DropOffSignatureScreenView> createState() => _DropOffSignatureScreenViewState();
}

class _DropOffSignatureScreenViewState extends State<_DropOffSignatureScreenView> {
  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submitSignature() async {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(isArabic ? 'يرجى التوقيع أولاً' : 'Please provide a signature first'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final Uint8List? signatureBytes = await _signatureController.toPngBytes();

    if (!mounted) return;
    
    // We convert Uint8List to List<int>
    context.read<DropOffCubit>().submitDropOffTasks(signatureBytes?.toList());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'تأكيد الاستلام والتوقيع' : 'Confirmation & Signature'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<DropOffCubit, DropOffState>(
        listener: (context, state) {
          state.whenOrNull(
            error: (msg) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(msg), backgroundColor: Colors.red),
              );
            },
            closeTasksSuccess: () {
              context.go(AppRouter.taskStatus, extra: {
                'isSuccess': true,
                'message': isArabic 
                    ? 'تم تسليم العينات بنجاح وإغلاق المهام.' 
                    : 'Samples dropped off successfully and tasks closed.',
                'taskId': null,
              });
            },
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
            signatureReady: (selectedTask, scannedBags, isSubmitting) {
              final destinationName = isArabic 
                  ? (selectedTask.arabicName ?? selectedTask.name ?? 'وجهة غير معروفة')
                  : (selectedTask.englishName ?? selectedTask.name ?? 'Unknown Destination');

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(height: 12),
                          AppText.titleLarge(destinationName, color: AppColors.primary),
                          const SizedBox(height: 4),
                          AppText(
                            isArabic ? 'إجمالي الأكياس: ${scannedBags.length}' : 'Total Bags: ${scannedBags.length}',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Signature Pad
                    AppText.titleLarge(isArabic ? 'توقيع المستلم' : 'Receiver Signature'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        children: [
                          Signature(
                            controller: _signatureController,
                            height: 250,
                            backgroundColor: Colors.white,
                          ),
                          Container(
                            color: Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _signatureController.clear(),
                                  icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                                  label: AppText(isArabic ? 'مسح التوقيع' : 'Clear', style: const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    if (isSubmitting)
                      const Center(child: CircularProgressIndicator())
                    else
                      AppElevatedButton(
                        text: isArabic ? 'إنهاء وتسليم' : 'SUBMIT & DROP OFF',
                        onPressed: _submitSignature,
                      ),
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
