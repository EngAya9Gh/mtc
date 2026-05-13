import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';

class TaskTypeScreen extends StatelessWidget {
  const TaskTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Very light gray/blue background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF006972), // Teal color from the image
        centerTitle: true,
        title: AppText(
          l.medicalTasks,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtitle bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: AppText(
              isArabic 
                  ? 'اختر نوع المهمة التي تريد تنفيذها:' 
                  : 'Select the type of task you want to perform:',
              style: const TextStyle(
                color: Color(0xFF7B8D9E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
            ),
          ),
          
          // List of cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _TaskTypeCard(
                  title: l.pickupSamples,
                  subtitle: isArabic ? 'مهام جديدة' : 'New Tasks',
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF006972),
                  iconBgColor: const Color(0xFFE5F0F1),
                  onTap: () {
                    context.push('/task_list/NEW');
                  },
                ),
                const SizedBox(height: 16),
                _TaskTypeCard(
                  title: l.samplesPlacement,
                  subtitle: isArabic ? 'مهام جاهزة لوضعها في الفريزر' : 'Tasks ready for freezer placement',
                  icon: Icons.ac_unit_rounded,
                  iconColor: const Color(0xFF9C64A6),
                  iconBgColor: const Color(0xFFF5EBF7),
                  onTap: () {
                    context.push('/task_list/COLLECTED');
                  },
                ),
                const SizedBox(height: 16),
                _TaskTypeCard(
                  title: l.dropOffSamples,
                  subtitle: isArabic ? 'مهام خارج الفريزر للتسليم' : 'Tasks out of freezer',
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF4CAF50),
                  iconBgColor: const Color(0xFFE8F5E9),
                  onTap: () {
                    context.push('/task_list/OUT_FREEZER');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _TaskTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Leading Arrow
            Icon(
              isArabic ? Icons.arrow_back_ios_rounded : Icons.arrow_back_ios_rounded, // Assuming from the image it points left in English too, wait, in the image it points left (looks like an iOS back arrow <).
              color: const Color(0xFFB0BEC5),
              size: 20,
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  AppText(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF455A64),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF90A4AE),
                      fontSize: 13,
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
