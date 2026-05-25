import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'الملف الشخصي' : 'Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(child: AppLoader()),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  AppText(message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().fetchProfile(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: AppText(isArabic ? 'إعادة المحاولة' : 'Retry', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            loaded: (profile) {
              return SingleChildScrollView(
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
                            profile.txtName ?? (isArabic ? 'سائق' : 'Driver'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            profile.txtMobileNumber ?? '',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Driver Details Section
                    _buildSectionHeader(isArabic ? 'معلومات السائق' : 'Driver Information'),
                    _buildInfoCard([
                      _buildInfoRow(Icons.person_outline, isArabic ? 'الاسم' : 'Name', profile.txtName ?? ''),
                      _buildInfoRow(Icons.account_circle_outlined, isArabic ? 'اسم المستخدم' : 'Username', profile.txtUserName ?? ''),
                      _buildInfoRow(Icons.email_outlined, isArabic ? 'البريد الإلكتروني' : 'Email', profile.txtEmail ?? ''),
                      _buildInfoRow(Icons.phone_android_outlined, isArabic ? 'رقم الجوال' : 'Mobile Number', profile.txtMobileNumber ?? ''),
                      _buildInfoRow(Icons.location_city_outlined, isArabic ? 'المدينة' : 'City', profile.txtCity ?? ''),
                      _buildInfoRow(Icons.badge_outlined, isArabic ? 'رقم السائق' : 'Driver ID', profile.txtDriverID ?? ''),
                    ]),

                    const SizedBox(height: 20),

                    // Car Details Section
                    _buildSectionHeader(isArabic ? 'معلومات السيارة' : 'Car Information'),
                    _buildInfoCard([
                      _buildInfoRow(Icons.directions_car_filled_outlined, isArabic ? 'موديل السيارة' : 'Model', profile.txtModel ?? '---'),
                      _buildInfoRow(Icons.color_lens_outlined, isArabic ? 'لون السيارة' : 'Color', profile.txtColor ?? '---'),
                      _buildInfoRow(Icons.confirmation_number_outlined, isArabic ? 'رقم اللوحة' : 'Plate Number', profile.txtCarNumber ?? '---'),
                      _buildInfoRow(Icons.description_outlined, isArabic ? 'الوصف' : 'Description', profile.txtDescription ?? '---'),
                    ]),
                    
                    const SizedBox(height: 40),
                    
                    // Version Info
                    AppText(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
