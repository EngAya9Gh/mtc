import 'package:flutter/material.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../data/providers/user_info_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    final user = UserInfo().loginInfo;
    final car = UserInfo().carInfo;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'الملف الشخصي' : 'Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar and Name Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    user?.name ?? (isArabic ? 'سائق' : 'Driver'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    user?.mobile ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Driver Details Section
            _buildSectionHeader(isArabic ? 'معلومات السائق' : 'Driver Information'),
            _buildInfoCard([
              _buildInfoRow(Icons.badge_outlined, isArabic ? 'رقم السائق' : 'Driver ID', user?.id?.toString() ?? ''),
              _buildInfoRow(Icons.phone_android_outlined, isArabic ? 'رقم الجوال' : 'Mobile Number', user?.mobile ?? ''),
            ]),

            const SizedBox(height: 20),

            // Car Details Section
            _buildSectionHeader(isArabic ? 'معلومات السيارة' : 'Car Information'),
            _buildInfoCard([
              _buildInfoRow(Icons.directions_car_filled_outlined, isArabic ? 'رقم اللوحة' : 'Plate Number', car?.plateNumber ?? '---'),
              _buildInfoRow(Icons.settings_outlined, isArabic ? 'رقم السيارة' : 'Car ID', car?.id?.toString() ?? '---'),
            ]),
            
            const SizedBox(height: 40),
            
            // Version Info
            AppText(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: AppText(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget val = entry.value;
          return Column(
            children: [
              val,
              if (idx != children.length - 1) 
                Divider(height: 1, color: Colors.grey.shade100, indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: AppText(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          AppText(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
