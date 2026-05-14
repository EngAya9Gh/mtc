import 'package:flutter/material.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import 'task_timeline.dart';

import '../../../../features/medical_tasks/data/models/task_model.dart';

class LatestTaskCard extends StatelessWidget {
  final MedicalTask task;
  const LatestTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(Localizations.localeOf(context).languageCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header gradient band
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF00838F)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  AppText(
                    l.latestTask,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      task.status == 'NEW' ? l.newBadge : task.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client info row
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withOpacity(0.15),
                              AppColors.secondary.withOpacity(0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: AppColors.secondary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              task.clientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            AppText(
                              'Task #${task.id}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AppText(
                          task.status,
                          style: TextStyle(
                            color: _getStatusColor(task.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TaskTimeline(currentStep: _getStepFromStatus(task.status)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F5FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildLocationPoint(
                          label: l.pickup,
                          value: task.fromLocationName,
                          icon: Icons.circle,
                          iconColor: AppColors.primary,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: List.generate(
                              5,
                              (i) => Container(
                                width: 5,
                                height: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                        _buildLocationPoint(
                          label: l.dropoff,
                          value: task.toLocationName,
                          icon: Icons.location_on_rounded,
                          iconColor: Colors.red,
                          align: CrossAxisAlignment.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEW': return Colors.blue;
      case 'COLLECTED': return Colors.orange;
      case 'IN_FREEZER': return Colors.cyan;
      case 'OUT_FREEZER': return Colors.purple;
      case 'CLOSED': return Colors.green;
      default: return Colors.grey;
    }
  }

  int _getStepFromStatus(String status) {
    switch (status) {
      case 'NEW': return 0;
      case 'COLLECTED': return 1;
      case 'IN_FREEZER': return 2;
      case 'OUT_FREEZER': return 3;
      case 'CLOSED': return 4;
      default: return 0;
    }
  }

  Widget _buildLocationPoint({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment:
                align == CrossAxisAlignment.end ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (align == CrossAxisAlignment.start)
                Icon(icon, size: 8, color: iconColor),
              if (align == CrossAxisAlignment.start) const SizedBox(width: 4),
              AppText(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
              ),
              if (align == CrossAxisAlignment.end) const SizedBox(width: 4),
              if (align == CrossAxisAlignment.end)
                Icon(icon, size: 12, color: iconColor),
            ],
          ),
          const SizedBox(height: 3),
          AppText(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
