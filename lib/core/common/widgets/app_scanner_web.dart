import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// --- MOCK CLASSES TO REPLACE MOBILE SCANNER ---
enum BarcodeFormat {
  unknown, aztec, code39, code93, code128, dataMatrix, ean8, ean13, itf,
  pdf417, qrCode, upca, upce, all
}

class Barcode {
  final String? rawValue;
  final String? displayValue;
  final BarcodeFormat format;

  const Barcode({
    this.rawValue,
    this.displayValue,
    this.format = BarcodeFormat.unknown,
  });
}

class BarcodeCapture {
  final List<Barcode> barcodes;

  const BarcodeCapture({
    required this.barcodes,
  });
}
// ----------------------------------------------

enum ScannerEngine { mobileScanner, scandit, barkoder, scanbot, dynamsoft }

Future<void> initScanner() async {
  // No-op for web
}

class AppScanner extends StatelessWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final Widget? overlay;
  final Rect? scanWindow;
  final List<BarcodeFormat>? formats;

  const AppScanner({
    super.key,
    required this.onDetect,
    this.overlay,
    this.scanWindow,
    this.formats,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        'Web Scanner Not Supported',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (overlay != null) overlay!,
          if (kDebugMode)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Debug: Enter barcode manually',
                      border: InputBorder.none,
                      icon: Icon(Icons.bug_report, color: Colors.red),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        onDetect(BarcodeCapture(barcodes: [
                          Barcode(rawValue: val.trim(), displayValue: val.trim(), format: BarcodeFormat.unknown)
                        ]));
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
