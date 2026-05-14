import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';

class BagScanScreen extends StatefulWidget {
  const BagScanScreen({super.key});

  @override
  State<BagScanScreen> createState() => _BagScanScreenState();
}

class _BagScanScreenState extends State<BagScanScreen> {
  final TextEditingController _bagController = TextEditingController();
  bool _isScanned = false;

  void _onSimulateScan() {
    setState(() {
      _bagController.text = 'BAG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      _isScanned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: AppText(isArabic ? 'مسح باركود الكيس' : 'Scan Bag Barcode'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 100, color: AppColors.primary),
            const SizedBox(height: 30),
            AppText(
              isArabic 
                ? 'يرجى مسح باركود كيس الخطر الحيوي قبل المتابعة' 
                : 'Please scan the biohazard bag barcode before proceeding',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Bag Code Input/Display
            TextField(
              controller: _bagController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: isArabic ? 'رقم الكيس' : 'Bag Barcode',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            
            AppElevatedButton(
              text: isArabic ? 'فتح الماسح' : 'OPEN SCANNER',
              onPressed: _onSimulateScan, // In real app, open mobile_scanner
            ),
            
            const Spacer(),
            
            AppElevatedButton(
              text: isArabic ? 'متابعة' : 'PROCEED',
              onPressed: _isScanned ? () {
                context.pop(_bagController.text);
              } : null,
            ),
          ],
        ),
      ),
    );
  }
}
