import 'package:flutter/material.dart';
import '../../../../core/config/theme/color_scheme.dart';

class TaskTimeline extends StatelessWidget {
  final int currentStep;
  static const List<String> _steps = ['NEW', 'COLLECTED', 'FREEZER', 'CLOSED'];

  const TaskTimeline({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(_steps.length, (index) {
            final isCompleted = index <= currentStep;
            final isCurrent = index == currentStep;
            final isLast = index == _steps.length - 1;

            return Expanded(
              child: Row(
                children: [
                  // Node
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? AppColors.primary
                          : isCompleted
                              ? AppColors.primary.withOpacity(0.6)
                              : Colors.grey[200],
                      border: isCurrent
                          ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 4)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted && !isCurrent
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : isCurrent
                              ? const Icon(Icons.local_shipping, size: 16, color: Colors.white)
                              : Text(
                                  (index + 1).toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                    ),
                  ),
                  // Line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: index < currentStep ? AppColors.primary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_steps.length, (index) {
            final isCompleted = index <= currentStep;
            return Expanded(
              child: Text(
                _steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? AppColors.primary : Colors.grey,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
