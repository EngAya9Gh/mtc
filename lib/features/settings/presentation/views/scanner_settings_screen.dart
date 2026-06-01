import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
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
                  _buildSwitchTile(
                    Icons.autorenew,
                    isArabic ? 'الاستئناف التلقائي' : 'Auto-Resume',
                    isArabic ? 'استئناف المسح تلقائياً بعد القراءة' : 'Resume scanning automatically after reading',
                    state.autoResume,
                    (val) => context.read<ScannerSettingsCubit>().toggleAutoResume(val),
                  ),
                  _buildSliderTile(
                    Icons.timer_outlined,
                    isArabic ? 'الانتظار بين اللقطات' : 'Hold Time / Filter',
                    isArabic ? '${state.holdTime.toStringAsFixed(1)} ثانية' : '${state.holdTime.toStringAsFixed(1)} seconds',
                    state.holdTime,
                    (val) => context.read<ScannerSettingsCubit>().setHoldTime(val),
                    isArabic,
                  ),
                  _buildDropdownTile(
                    Icons.hd_outlined,
                    isArabic ? 'دقة الكاميرا' : 'Camera Resolution',
                    state.cameraResolution,
                    (val) => context.read<ScannerSettingsCubit>().setCameraResolution(val ?? 'Full HD'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSettingsGroup(
                isArabic ? 'أنواع الباركود المدعومة' : 'Supported Symbologies',
                [
                  for (final entry in state.symbologies.entries)
                    _buildSwitchTile(
                      Icons.qr_code_scanner,
                      entry.key,
                      isArabic ? 'تفعيل ${entry.key}' : 'Enable ${entry.key}',
                      entry.value,
                      (val) => context.read<ScannerSettingsCubit>().toggleSymbology(entry.key, val),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: AppElevatedButton(
                      text: isArabic ? 'استعادة الافتراضيات' : 'Reset to Defaults',
                      backgroundColor: Colors.redAccent,
                      onPressed: () {
                        context.read<ScannerSettingsCubit>().resetToDefaults();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isArabic ? 'تمت استعادة الافتراضيات' : 'Defaults restored')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppElevatedButton(
                      text: isArabic ? 'تطبيق' : 'Apply',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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

  Widget _buildSliderTile(IconData icon, String title, String subtitle, double value, Function(double) onChanged, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  AppText(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0.5,
            max: 3.0,
            divisions: 25,
            activeColor: AppColors.primary,
            label: '${value.toStringAsFixed(1)}s',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(IconData icon, String title, String value, Function(String?) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: AppText(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: ['HD', 'Full HD', 'UHD'].map((String res) {
          return DropdownMenuItem<String>(
            value: res,
            child: AppText(res, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
