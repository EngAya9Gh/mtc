import 'package:mobile_scanner/mobile_scanner.dart';
void main() {
  final b = Barcode(rawValue: '123', format: BarcodeFormat.unknown);
  final c = BarcodeCapture(barcodes: [b]);
  print('Success: ${c.barcodes.first.rawValue}');
}
