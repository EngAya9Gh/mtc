import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';

class TaskStatusScreen extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final int? taskId;

  const TaskStatusScreen({
    super.key,
    required this.isSuccess,
    required this.message,
    this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Container with gradient/shadow
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                    size: 80,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Success/Failure Title
              AppText(
                isSuccess
                    ? (isArabic ? 'تمت العملية بنجاح' : 'Success!')
                    : (isArabic ? 'فشلت العملية' : 'Failed'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppText(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              // Action Button
              AppElevatedButton(
                text: isArabic ? 'العودة لقائمة المهام' : 'BACK TO TASK LIST',
                backgroundColor: isSuccess ? AppColors.primary : Colors.red,
                foregroundColor: Colors.white,
                onPressed: () {
                  // Navigate to task_type screen
                  context.go('/task_type');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
