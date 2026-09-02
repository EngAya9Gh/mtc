export 'app_scanner_web.dart' if (dart.library.io) 'app_scanner_native.dart';

enum BarcodeFormat {
  unknown,
  all,
  code128,
  code39,
  code93,
  codabar,
  dataMatrix,
  ean13,
  ean8,
  itf,
  qrCode,
  upcA,
  upcE,
  pdf417,
  aztec,
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
