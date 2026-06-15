import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/drop_off_cubit.dart';
import '../bloc/drop_off_state.dart';
import '../../../samples_pull_out/data/models/client_task_model.dart';

class DropOffTasksScreen extends StatelessWidget {
  const DropOffTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DropOffCubit>()..getDropOffTasks(),
      child: const _DropOffTasksScreenView(),
    );
  }
}

class _DropOffTasksScreenView extends StatelessWidget {
  const _DropOffTasksScreenView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'تسليم العينات' : 'Drop Off Samples'),
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
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
            loading: (msg) => const Center(child: AppLoader()),
            tasksLoaded: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      AppText(
                        isArabic ? 'لا توجد عينات حالياً للتسليم' : 'No samples ready for drop off',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DropOffCubit>().getDropOffTasks();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final destinationGroup = tasks[index];
                    return _DropOffDestinationCard(
                      destination: destinationGroup,
                      isArabic: isArabic,
                      onTap: () {
                        final isConfirmed = destinationGroup.driverConfirmToLocation == 'YES' || destinationGroup.driverConfirmToLocation == '1';
                        if (!isConfirmed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: AppText(isArabic ? 'يجب تأكيد الوصول للموقع أولاً' : 'You must confirm reach first'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        context.read<DropOffCubit>().proceedToScanBags(destinationGroup);
                        context.push(
                          AppRouter.dropOffScanBags,
                          extra: context.read<DropOffCubit>(), // Pass cubit to maintain state
                        );
                      },
                    );
                  },
                ),
              );
            },
            orElse: () => const Center(child: AppLoader()),
          );
        },
      ),
    );
  }
}

class _DropOffDestinationCard extends StatelessWidget {
  final ClientTaskModel destination;
  final bool isArabic;
  final VoidCallback onTap;

  const _DropOffDestinationCard({
    required this.destination,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int totalSamples = 0;
    Set<String> uniqueBags = {};
    
    if (destination.tasks != null) {
      for (var t in destination.tasks!) {
        if (t.samplesSummary != null) {
          totalSamples += t.samplesSummary!.length;
          for (var s in t.samplesSummary!) {
            if (s.bagCode.isNotEmpty) {
              uniqueBags.add(s.bagCode);
            }
          }
        }
      }
    }
    int totalBags = uniqueBags.length;
    
    final destinationName = isArabic 
        ? (destination.arabicName ?? destination.name ?? 'وجهة غير معروفة')
        : (destination.englishName ?? destination.name ?? 'Unknown Destination');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Tasks #${(destination.taskIds.isNotEmpty) ? destination.taskIds.join(", ") : destination.tasks?.map((t) => t.id).join(", ")}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        AppText(
                          destinationName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      '${destination.tasks?.length ?? 0} ${isArabic ? "مهام" : "Tasks"}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science, color: Colors.blue, size: 18),
                      const SizedBox(width: 4),
                      AppText(
                        '$totalSamples ${isArabic ? "عينات" : "Samples"}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.outbox_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      AppText(
                        '$totalBags ${isArabic ? "أكياس" : "Bags"}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (destination.toLocationLat != null && destination.toLocationLng != null)
                    IconButton(
                      icon: const Icon(Icons.location_on, color: Colors.red),
                      onPressed: () async {
                        final url = 'https://www.google.com/maps/search/?api=1&query=${destination.toLocationLat},${destination.toLocationLng}';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      tooltip: isArabic ? 'فتح في الخرائط' : 'Open in Maps',
                    ),
                ],
              ),
              if (destination.driverConfirmToLocation != 'YES' && destination.driverConfirmToLocation != '1') ...[
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleReach(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: AppText(
                      isArabic ? 'تأكيد الوصول للموقع' : 'Confirm Reach',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleReach(BuildContext context) {
    if (destination.ayenati == 'YES' && destination.dropOffOtp != null && destination.dropOffOtp!.isNotEmpty) {
      _showOtpDialog(context);
    } else {
      context.read<DropOffCubit>().reachDropOffLocation(destination);
    }
  }

  void _showOtpDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: AppText(
            isArabic ? 'رمز التحقق (OTP)' : 'OTP Verification',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                isArabic 
                  ? 'هذه المهمة تتطلب رمز تحقق للتسليم. يرجى إدخال الرمز:'
                  : 'This task requires a drop off OTP. Please enter the code:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: isArabic ? 'رمز التحقق' : 'OTP Code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: AppText(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (otpController.text.trim() == destination.dropOffOtp) {
                  Navigator.pop(ctx);
                  context.read<DropOffCubit>().reachDropOffLocation(destination);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppText(isArabic ? 'الرمز غير صحيح' : 'Invalid OTP Code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: AppText(isArabic ? 'تأكيد' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }
}
