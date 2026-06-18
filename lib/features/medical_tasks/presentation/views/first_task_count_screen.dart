import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_text_field.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../data/models/task_model.dart';
import '../bloc/sample_collection_cubit.dart';
import '../bloc/sample_collection_state.dart';
import '../../../../core/services/di/di_container.dart';

class FirstTaskCountScreen extends StatelessWidget {
  final MedicalTask task;
  final List<Map<String, String>> scannedSamples;
  final VoidCallback? onBoxSaved;

  const FirstTaskCountScreen({
    super.key,
    required this.task,
    required this.scannedSamples,
    this.onBoxSaved,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SampleCollectionCubit>(),
      child: _FirstTaskCountView(
        task: task,
        scannedSamples: scannedSamples,
        onBoxSaved: onBoxSaved,
      ),
    );
  }
}

class _FirstTaskCountView extends StatefulWidget {
  final MedicalTask task;
  final List<Map<String, String>> scannedSamples;
  final VoidCallback? onBoxSaved;

  const _FirstTaskCountView({
    required this.task,
    required this.scannedSamples,
    this.onBoxSaved,
  });

  @override
  State<_FirstTaskCountView> createState() => _FirstTaskCountViewState();
}

class _FirstTaskCountViewState extends State<_FirstTaskCountView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _boxCountController = TextEditingController();
  final TextEditingController _sampleCountController = TextEditingController();
  String _selectedTemp = 'ROOM';

  @override
  void initState() {
    super.initState();
    // Pre-fill if already saved in UserInfo
    final userInfo = UserInfo();
    if (userInfo.boxCount != null) {
      _boxCountController.text = userInfo.boxCount.toString();
    }
    if (userInfo.sampleCount != null) {
      _sampleCountController.text = userInfo.sampleCount.toString();
    }

    if (widget.scannedSamples.isNotEmpty) {
      final firstTemp = widget.scannedSamples.first['temp']?.toUpperCase();
      if (firstTemp != null && ['ROOM', 'REFRIGERATE', 'FROZEN'].contains(firstTemp)) {
        _selectedTemp = firstTemp;
      }
    }
  }

  @override
  void dispose() {
    _boxCountController.dispose();
    _sampleCountController.dispose();
    super.dispose();
  }

  void _onSaveBox(BuildContext context) {
    if (widget.scannedSamples.isEmpty) {
      final isArabic = AppLocalizations.of(context).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic 
                ? 'لا توجد عينات ممسوحة لحفظها في صندوق.' 
                : 'No scanned samples to save in a box.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final boxCount = int.parse(_boxCountController.text.trim());
      final sampleCount = int.parse(_sampleCountController.text.trim());

      final userInfo = UserInfo();
      userInfo.boxCount = boxCount;
      userInfo.sampleCount = sampleCount;

      context.read<SampleCollectionCubit>().saveBoxTask(
        taskId: widget.task.id,
        locationId: widget.task.fromLocation ?? 0,
        scannedSamples: widget.scannedSamples,
        boxCount: boxCount,
        sampleCount: sampleCount,
      );
    }
  }

  void _onFinishCollecting() {
    if (_formKey.currentState?.validate() ?? false) {
      final boxCount = int.parse(_boxCountController.text.trim());
      final sampleCount = int.parse(_sampleCountController.text.trim());

      // Save counts locally
      final userInfo = UserInfo();
      userInfo.boxCount = boxCount;
      userInfo.sampleCount = sampleCount;

      // Navigate immediately to DriverSignatureFragment (SignatureSubmitScreen)
      context.push('/signature', extra: widget.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return BlocConsumer<SampleCollectionCubit, SampleCollectionState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: AppColors.success),
            );
            // Trigger callback to clear scanned samples in parent list
            if (widget.onBoxSaved != null) {
              widget.onBoxSaved!();
            }
            // Navigate back so driver can scan more
            Navigator.pop(context);
          },
          error: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: AppColors.error),
            );
          },
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: (_) => true, orElse: () => false);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: AppText(
              isArabic ? 'عدّ الصناديق' : 'Box Count Info',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: isLoading
              ? const Center(child: AppLoader())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card with info
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  isArabic ? 'تفاصيل الصندوق الحالي' : 'Current Box Details',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppText(
                                      isArabic ? 'العينات الممسوحة للصندوق:' : 'Scanned samples for box:',
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: AppText(
                                        '${widget.scannedSamples.length}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Input fields
                        AppTextField(
                          controller: _boxCountController,
                          labelText: isArabic ? 'عدد الصناديق' : 'Box Count',
                          hintText: isArabic ? 'أدخل عدد الصناديق' : 'Enter box count',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isArabic ? 'يرجى إدخال عدد الصناديق' : 'Please enter box count';
                            }
                            if (int.tryParse(val) == null || int.parse(val) <= 0) {
                              return isArabic ? 'يرجى إدخال عدد صحيح أكبر من 0' : 'Please enter a positive integer';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        AppTextField(
                          controller: _sampleCountController,
                          labelText: isArabic ? 'عدد العينات الكلي' : 'Total Sample Count',
                          hintText: isArabic ? 'أدخل عدد العينات الكلي' : 'Enter total sample count',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isArabic ? 'يرجى إدخال عدد العينات' : 'Please enter sample count';
                            }
                            if (int.tryParse(val) == null || int.parse(val) <= 0) {
                              return isArabic ? 'يرجى إدخال عدد صحيح أكبر من 0' : 'Please enter a positive integer';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Dropdown for Temperature (Disabled/Read-only as per specification)
                        DropdownButtonFormField<String>(
                          value: _selectedTemp,
                          items: const [
                            DropdownMenuItem(value: 'ROOM', child: Text('ROOM')),
                            DropdownMenuItem(value: 'REFRIGERATE', child: Text('REFRIGERATE')),
                            DropdownMenuItem(value: 'FROZEN', child: Text('FROZEN')),
                          ],
                          onChanged: null, // Disabled
                          decoration: InputDecoration(
                            labelText: isArabic ? 'درجة الحرارة (معطل)' : 'Temperature (Disabled)',
                            filled: true,
                            fillColor: Colors.grey.shade200,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: AppElevatedButton(
                                text: isArabic ? 'حفظ الصندوق' : 'SAVE BOX',
                                onPressed: () => _onSaveBox(context),
                              ),
                            ),
                            // const SizedBox(width: 16),
                            // Expanded(
                            //   child: AppElevatedButton(
                            //     text: isArabic ? 'إنهاء الجمع' : 'FINISH COLLECTING',
                            //     backgroundColor: AppColors.secondary,
                            //     onPressed: _onFinishCollecting,
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
