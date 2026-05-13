import 'package:flutter/material.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import 'task_timeline.dart';

class LatestTaskCard extends StatelessWidget {
  const LatestTaskCard({super.key});

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
                      l.newBadge,
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'Al-Salam Hospital',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            AppText(
                              'Task #12940',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const AppText(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TaskTimeline(currentStep: 0),
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
                          value: 'Riyadh Main Office',
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
                          value: 'Central Lab',
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
