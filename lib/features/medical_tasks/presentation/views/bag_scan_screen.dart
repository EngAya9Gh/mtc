import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/common/widgets/app_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/services/network/api_client.dart';
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

  void _onScanBarcode(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      final code = capture.barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _bagController.text = code;
          _isScanned = true;
        });
      }
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
      body: Column(
        children: [
          // Top half: Live Scanner
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppScanner(
                    onDetect: _onScanBarcode,
                    formats: const [BarcodeFormat.code128],
                  ),
                  // Red laser line — aligned to center
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.9),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom half: Info and Button
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                          Flexible(
                            child: AppText(
                              isArabic
                                  ? 'الفئة: ${widget.temp ?? ""} | النوع: ${widget.type ?? ""}'
                                  : 'Temp: ${widget.temp ?? ""} | Type: ${widget.type ?? ""}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
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
                    readOnly: !getIt<ApiClient>().isDebugMode,
                    onChanged: (val) {
                      setState(() {
                        _isScanned = val.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: isArabic ? 'رقم الكيس' : 'Bag Barcode',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      suffixIcon: _bagController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _bagController.clear();
                                _isScanned = false;
                              });
                            },
                          ) 
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
                  ),
                  const SizedBox(height: 24),
                  
                  AppElevatedButton(
                    text: isArabic ? 'متابعة' : 'PROCEED',
                    onPressed: _isScanned || _bagController.text.isNotEmpty ? () {
                      context.pop(_bagController.text);
                    } : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
