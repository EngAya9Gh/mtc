import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/common/widgets/app_scanner_screen.dart';

class BagScanScreen extends StatefulWidget {
  final String? temp;
  final String? type;

  const BagScanScreen({super.key, this.temp, this.type});

  @override
  State<BagScanScreen> createState() => _BagScanScreenState();
}

class _BagScanScreenState extends State<BagScanScreen> {
  final TextEditingController _bagController = TextEditingController();
  bool _isScanned = false;

  void _onScanBarcode() async {
    final String? scannedBarcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppScannerScreen()),
    );
    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      setState(() {
        _bagController.text = scannedBarcode;
        _isScanned = true;
      });
    }
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
            const SizedBox(height: 24),
            AppText(
              isArabic 
                ? 'يرجى مسح باركود كيس الخطر الحيوي قبل المتابعة' 
                : 'Please scan the biohazard bag barcode before proceeding',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            if (widget.temp != null || widget.type != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    AppText(
                      isArabic
                          ? 'الفئة: ${widget.temp ?? ""} | النوع: ${widget.type ?? ""}'
                          : 'Temp: ${widget.temp ?? ""} | Type: ${widget.type ?? ""}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            
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
              onPressed: _onScanBarcode,
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
