import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../data/models/task_model.dart';

class FirstSampleInfoScreen extends StatefulWidget {
  final MedicalTask task;

  const FirstSampleInfoScreen({super.key, required this.task});

  @override
  State<FirstSampleInfoScreen> createState() => _FirstSampleInfoScreenState();
}

class _FirstSampleInfoScreenState extends State<FirstSampleInfoScreen> {
  String _selectedTemp = 'ROOM';
  String _selectedType = 'Tubes';

  final List<String> _tempOptions = ['ROOM', 'REFRIGERATE', 'FROZEN'];
  final List<Map<String, String>> _sampleTypes = [
    {'api': 'Tubes', 'ar': 'أنابيب', 'en': 'Tubes'},
    {'api': 'Swabs', 'ar': 'مسحة', 'en': 'Swabs'},
    {'api': 'Body Fluids', 'ar': 'سوائل الجسم', 'en': 'Body Fluids'},
    {'api': 'UBT', 'ar': 'فحص التنفس', 'en': 'UBT'},
    {'api': 'NBS', 'ar': 'كروت الدم', 'en': 'NBS'},
    {'api': 'Blood Bags', 'ar': 'أكياس الدم', 'en': 'Blood Bags'},
    {'api': 'Others', 'ar': 'أخرى', 'en': 'Others'},
  ];

  Color _getTempColor(String temp) {
    switch (temp) {
      case 'ROOM': return Colors.orange;
      case 'REFRIGERATE': return Colors.blue;
      case 'FROZEN': return Colors.deepPurple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: AppText(isArabic ? 'إعدادات العينة' : 'Sample Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            AppText(isArabic ? 'اختر درجة الحرارة' : 'Select Temperature', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _tempOptions.map((temp) {
                final isSelected = _selectedTemp == temp;
                final color = _getTempColor(temp);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(child: AppText(temp, style: TextStyle(color: isSelected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold))),
                      selected: isSelected,
                      selectedColor: color,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedTemp = temp);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 40),
            AppText(isArabic ? 'اختر نوع العينة' : 'Select Sample Type', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _sampleTypes.length,
                itemBuilder: (context, index) {
                  final type = _sampleTypes[index];
                  final isSelected = _selectedType == type['api'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.category_outlined, color: isSelected ? AppColors.primary : Colors.grey),
                      title: AppText(isArabic ? type['ar']! : type['en']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () => setState(() => _selectedType = type['api']!),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            AppElevatedButton(
              text: isArabic ? 'فتح الماسح' : 'OPEN SCANNER',
              onPressed: () {
                context.push('/sample_collection', extra: {
                  'task': widget.task,
                  'initialTemp': _selectedTemp,
                  'initialType': _selectedType,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
