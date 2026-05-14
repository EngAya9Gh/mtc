import 'package:flutter/material.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: AppText(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.privacy_tip_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            AppText(
              isArabic ? 'حماية بياناتك هي أولويتنا' : 'Your Privacy Matters',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            AppText(
              isArabic 
                ? 'نحن نلتزم بحماية خصوصيتك وضمان أمن بياناتك الشخصية وبيانات الموقع الجغرافي المستخدمة لتحسين خدمات التوصيل.' 
                : 'We are committed to protecting your privacy and ensuring the security of your personal data and location information used to optimize delivery services.',
              style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 30),
            _buildPolicySection(
              isArabic ? '1. جمع البيانات' : '1. Data Collection',
              isArabic 
                ? 'نقوم بجمع بيانات الموقع الجغرافي في الخلفية لضمان دقيق لتتبع الشحنات وحساب الوقت المتوقع للوصول.' 
                : 'We collect location data in the background to ensure accurate shipment tracking and estimated arrival times.',
            ),
            _buildPolicySection(
              isArabic ? '2. الاستخدام' : '2. Usage',
              isArabic 
                ? 'تُستخدم البيانات فقط لأغراض تشغيلية ولن يتم مشاركتها مع أي أطراف ثالثة لأغراض تسويقية.' 
                : 'Data is used solely for operational purposes and will not be shared with third parties for marketing.',
            ),
            const SizedBox(height: 40),
            Center(
              child: AppText(
                'Last Updated: May 2026',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          AppText(content, style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
