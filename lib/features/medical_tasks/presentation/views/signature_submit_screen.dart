import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/models/task_model.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/di/di_container.dart';
import '../bloc/signature_submit_cubit.dart';
import '../bloc/signature_submit_state.dart';



class SignatureSubmitScreen extends StatelessWidget {
  final MedicalTask task;

  const SignatureSubmitScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignatureSubmitCubit>()..fetchSamples(task.id),
      child: _SignatureSubmitView(task: task),
    );
  }
}

class _SignatureSubmitView extends StatefulWidget {
  final MedicalTask task;

  const _SignatureSubmitView({required this.task});

  @override
  State<_SignatureSubmitView> createState() => _SignatureSubmitViewState();
}

class _SignatureSubmitViewState extends State<_SignatureSubmitView> {
  final TextEditingController _boxCountController = TextEditingController();
  final TextEditingController _sampleCountController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  List<dynamic> _samples = [];

  @override
  void dispose() {
    _boxCountController.dispose();
    _sampleCountController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    final isBoxTask = widget.task.taskType == 'BOX';
    // If status is COLLECTED, it's a delivery task (task/close)
    final isCollection = widget.task.status != 'COLLECTED';

    return BlocConsumer<SignatureSubmitCubit, SignatureSubmitState>(
      listener: (context, state) {
        state.whenOrNull(
          samplesLoaded: (samples) => setState(() => _samples = samples),
          success: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                    AppText(
                      isArabic ? 'تمت العملية بنجاح' : 'Task Submitted Successfully',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppElevatedButton(
                      text: isArabic ? 'العودة للرئيسية' : 'Back to Home',
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go(AppRouter.main);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          error: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          },
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            title: AppText(isArabic ? 'إرسال المهمة' : 'Submit Task'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 30),
                      const SizedBox(height: 12),
                      AppText(
                        widget.task.clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        '#${widget.task.id} | ${widget.task.status}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Samples List Section
                AppText(
                  isArabic ? 'العينات المسجلة:' : 'Registered Samples:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _samples.isEmpty 
                    ? Center(child: AppText(isArabic ? 'لا توجد عينات مسجلة' : 'No samples found', style: const TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _samples.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final sample = _samples[index];
                          return Row(
                            children: [
                              const Icon(Icons.qr_code_2, size: 20, color: Colors.blueGrey),
                              const SizedBox(width: 12),
                              Expanded(child: AppText(sample['barcode'] ?? 'N/A', style: const TextStyle(fontSize: 14))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                child: AppText(sample['container'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                              ),
                            ],
                          );
                        },
                      ),
                ),
                
                const SizedBox(height: 24),

                // BOX Task Inputs
                if (isCollection && isBoxTask) ...[
                  AppText(isArabic ? 'بيانات الصناديق:' : 'Box Details:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _boxCountController,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'عدد الصناديق' : 'Box Count',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _sampleCountController,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'عدد العينات' : 'Sample Count',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Delivery OTP Input
                if (!isCollection) ...[
                  AppText(isArabic ? 'رمز التأكيد (OTP):' : 'Confirmation Code (OTP):', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                ],

                // Note Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText(
                          isArabic 
                            ? 'التوقيع الرقمي معطّل حالياً. سيتم إرسال المهمة مباشرة.'
                            : 'Digital signature is currently disabled. Task will be submitted directly.',
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                AppElevatedButton(
                  text: isArabic ? 'إرسال المهمة' : 'SUBMIT TASK',
                  isLoading: isLoading,
                  onPressed: () {
                    context.read<SignatureSubmitCubit>().submitTask(
                      taskId: widget.task.id,
                      isCollection: isCollection,
                      boxCount: int.tryParse(_boxCountController.text),
                      sampleCount: int.tryParse(_sampleCountController.text),
                      otp: _otpController.text,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
