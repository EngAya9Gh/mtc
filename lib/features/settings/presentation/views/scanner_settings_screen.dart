import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../bloc/scanner_settings_cubit.dart';

class ScannerSettingsScreen extends StatelessWidget {
  const ScannerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ScannerSettingsCubit>(),
      child: const _ScannerSettingsScreenView(),
    );
  }
}

class _ScannerSettingsScreenView extends StatelessWidget {
  const _ScannerSettingsScreenView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'إعدادات الماسح' : 'Scanner Settings'),
        centerTitle: true,
      ),
      body: BlocBuilder<ScannerSettingsCubit, ScannerSettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSettingsGroup(
                isArabic ? 'التنبيهات' : 'Feedback Options',
                [
                  _buildSwitchTile(
                    Icons.volume_up_outlined,
                    isArabic ? 'صوت التنبيه (Beep)' : 'Audio Feedback (Beep)',
                    isArabic ? 'إصدار صوت عند نجاح المسح' : 'Plays a sound on successful scan',
                    state.beep,
                    (val) => context.read<ScannerSettingsCubit>().toggleBeep(val),
                  ),
                  _buildSwitchTile(
                    Icons.vibration,
                    isArabic ? 'الاهتزاز' : 'Haptic Feedback (Vibrate)',
                    isArabic ? 'اهتزاز عند نجاح المسح' : 'Vibrates on successful scan',
                    state.vibrate,
                    (val) => context.read<ScannerSettingsCubit>().toggleVibrate(val),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSettingsGroup(
                isArabic ? 'إعدادات الكاميرا' : 'Camera Options',
                [
                  _buildSwitchTile(
                    Icons.flashlight_on_outlined,
                    isArabic ? 'الفلاش التلقائي' : 'Auto Flash',
                    isArabic ? 'تفعيل الفلاش عند المسح' : 'Turn on flash while scanning',
                    state.flash,
                    (val) => context.read<ScannerSettingsCubit>().toggleFlash(val),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
          child: AppText(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: AppText(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: AppText(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
