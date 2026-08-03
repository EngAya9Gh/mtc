import 'dart:math' show min, max;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scandit_flutter_datacapture_core/scandit_flutter_datacapture_core.dart' as scandit_core;
import 'package:scandit_flutter_datacapture_barcode/scandit_flutter_datacapture_barcode.dart' as scandit_barcode;
import 'package:scandit_flutter_datacapture_barcode/scandit_flutter_datacapture_barcode_capture.dart' as scandit_barcode_capture;
import '../../../features/settings/presentation/bloc/scanner_settings_cubit.dart';
import '../../services/di/di_container.dart';
import '../../services/network/api_client.dart';

/// TOGGLE THIS FLAG TO SWITCH BETWEEN SCANDIT AND MOBILE_SCANNER
const bool useScandit = true;

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
    if (useScandit && !kIsWeb) {
      return _ScanditScannerImpl(
        onDetect: onDetect,
        overlay: overlay,
        scanWindow: scanWindow,
        formats: formats,
      );
    } else {
      return _MobileScannerImpl(
        onDetect: onDetect,
        overlay: overlay,
        scanWindow: scanWindow,
        formats: formats,
      );
    }
  }
}

// ----------------------------------------------------------------------
// 1. MOBILE SCANNER IMPLEMENTATION (Legacy)
// ----------------------------------------------------------------------

class _MobileScannerImpl extends StatefulWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final Widget? overlay;
  final Rect? scanWindow;
  final List<BarcodeFormat>? formats;

  const _MobileScannerImpl({
    required this.onDetect,
    this.overlay,
    this.scanWindow,
    this.formats,
  });

  @override
  State<_MobileScannerImpl> createState() => _MobileScannerImplState();
}

class _MobileScannerImplState extends State<_MobileScannerImpl>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  late ScannerSettingsCubit _settingsCubit;

  Size _widgetSize = Size.zero;
  final Map<String, DateTime> _locks = {};
  static const int _lockDurationMs = 1500;

  late final AnimationController _flashCtrl;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _settingsCubit = getIt<ScannerSettingsCubit>();
    _initController(_settingsCubit.state);

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flashOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut),
    );
  }

  void _initController(ScannerSettingsState settings) {
    List<BarcodeFormat> formats = widget.formats ?? [];
    if (formats.isEmpty) {
      if (settings.symbologies['Code 128'] == true) formats.add(BarcodeFormat.code128);
      if (settings.symbologies['Code 39'] == true) formats.add(BarcodeFormat.code39);
      if (settings.symbologies['EAN-13'] == true) formats.add(BarcodeFormat.ean13);
      if (settings.symbologies['EAN-8'] == true) formats.add(BarcodeFormat.ean8);
      if (settings.symbologies['UPC-E'] == true) formats.add(BarcodeFormat.upcE);
      if (settings.symbologies['QR Code'] == true) formats.add(BarcodeFormat.qrCode);
      if (formats.isEmpty) formats = [BarcodeFormat.all];
    }

    Size resolution;
    switch (settings.cameraResolution) {
      case 'Full HD':
      case 'UHD':
        resolution = const Size(1920, 1080);
        break;
      case 'HD':
      default:
        resolution = const Size(1280, 720);
        break;
    }

    _controller = MobileScannerController(
      formats: formats,
      cameraResolution: resolution,
      torchEnabled: settings.flash,
      detectionSpeed: DetectionSpeed.unrestricted,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  bool _isInsideScanWindow(Barcode barcode, Size? rawFrameSize) {
    if (widget.scanWindow == null) return true;
    if (_widgetSize == Size.zero) return true;

    final corners = barcode.corners;
    if (corners == null || corners.isEmpty) return true;

    double fx = 0, fy = 0;
    for (final c in corners) {
      fx += c.dx;
      fy += c.dy;
    }
    fx /= corners.length;
    fy /= corners.length;

    final Size orientedFrame;
    if (rawFrameSize != null &&
        rawFrameSize.width > rawFrameSize.height &&
        _widgetSize.height > _widgetSize.width) {
      orientedFrame = Size(rawFrameSize.height, rawFrameSize.width);
    } else if (rawFrameSize != null) {
      orientedFrame = rawFrameSize;
    } else {
      orientedFrame = _widgetSize;
    }

    final normCx = (fx / orientedFrame.width).clamp(0.0, 1.0);
    final normCy = (fy / orientedFrame.height).clamp(0.0, 1.0);

    final winLeft   = widget.scanWindow!.left   / _widgetSize.width;
    final winRight  = widget.scanWindow!.right  / _widgetSize.width;
    final winTop    = widget.scanWindow!.top    / _widgetSize.height;
    final winBottom = widget.scanWindow!.bottom / _widgetSize.height;

    return normCx >= winLeft &&
           normCx <= winRight &&
           normCy >= winTop &&
           normCy <= winBottom;
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue ?? '';
    if (code.isEmpty) return;

    if (!_isInsideScanWindow(barcode, capture.size)) return;

    final now = DateTime.now();
    final lockUntil = _locks[code];
    if (lockUntil != null && now.isBefore(lockUntil)) return;

    _locks[code] = now.add(const Duration(milliseconds: _lockDurationMs));
    if (_locks.length > 20) {
      final sorted = _locks.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (int i = 0; i < sorted.length - 20; i++) {
        _locks.remove(sorted[i].key);
      }
    }

    if (mounted) _flashCtrl.forward(from: 0);

    final settings = _settingsCubit.state;
    if (settings.vibrate) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) Vibration.vibrate(duration: 50);
    }

    if (!settings.autoResume) _controller?.stop();

    widget.onDetect(capture);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerSettingsCubit, ScannerSettingsState>(
      bloc: _settingsCubit,
      listenWhen: (prev, curr) =>
          prev.flash != curr.flash ||
          prev.cameraResolution != curr.cameraResolution ||
          prev.symbologies != curr.symbologies,
      listener: (context, state) {
        _controller?.dispose();
        setState(() {
          _initController(state);
          _controller?.start();
        });
      },
      builder: (context, settings) {
        if (_controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller!,
                  scanWindow: widget.scanWindow,
                  onDetect: _handleDetection,
                ),
                AnimatedBuilder(
                  animation: _flashOpacity,
                  builder: (_, __) {
                    final opacity = _flashOpacity.value;
                    if (opacity <= 0) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: opacity),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller!,
                    builder: (context, scanState, _) {
                      final torchOn = scanState.torchState == TorchState.on;
                      return IconButton(
                        icon: Icon(
                          torchOn ? Icons.flash_on : Icons.flash_off,
                          color: torchOn ? Colors.yellow : Colors.white,
                          size: 32,
                        ),
                        onPressed: () => _controller!.toggleTorch(),
                      );
                    },
                  ),
                ),
                if (getIt<ApiClient>().isDebugMode)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard, color: Colors.blueAccent, size: 32),
                      onPressed: () => _showManualEntryDialog(context),
                    ),
                  ),
                if (widget.overlay != null) widget.overlay!,
              ],
            );
          },
        );
      },
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Manual Entry (Debug)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: 'Enter barcode...',
            hintStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                final barcode = Barcode(rawValue: code, format: BarcodeFormat.unknown);
                final capture = BarcodeCapture(barcodes: [barcode]);
                _handleDetection(capture);
              }
            },
            child: const Text('Simulate Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. SCANDIT SCANNER IMPLEMENTATION (New)
// ----------------------------------------------------------------------

class _ScanditScannerImpl extends StatefulWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final Widget? overlay;
  final Rect? scanWindow;
  final List<BarcodeFormat>? formats;

  const _ScanditScannerImpl({
    required this.onDetect,
    this.overlay,
    this.scanWindow,
    this.formats,
  });

  @override
  State<_ScanditScannerImpl> createState() => _ScanditScannerImplState();
}

class _ScanditScannerImplState extends State<_ScanditScannerImpl> 
    with SingleTickerProviderStateMixin implements scandit_barcode_capture.BarcodeCaptureListener {
  scandit_core.DataCaptureContext? _context;
  scandit_core.Camera? _camera;
  scandit_barcode_capture.BarcodeCapture? _barcodeCapture;
  scandit_core.DataCaptureView? _captureView;

  late ScannerSettingsCubit _settingsCubit;

  final Map<String, DateTime> _locks = {};
  static const int _lockDurationMs = 1500;

  late final AnimationController _flashCtrl;
  late final Animation<double> _flashOpacity;

  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _settingsCubit = getIt<ScannerSettingsCubit>();
    _initScanditAsync(_settingsCubit.state);

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flashOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut),
    );
  }

  Future<void> _initScanditAsync(ScannerSettingsState settings) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('SCANDIT: Camera permission denied');
      return;
    }

    debugPrint('SCANDIT: Starting initialization...');
    try {
      await scandit_core.ScanditFlutterDataCaptureCore.initialize();
      debugPrint('SCANDIT: Core initialized');
      await scandit_barcode.ScanditFlutterDataCaptureBarcode.initialize();
      debugPrint('SCANDIT: Barcode module initialized');
    } catch (e, st) {
      debugPrint('SCANDIT INIT ERROR: $e\n$st');
    }
    
    if (!mounted) return;

    // 1. مفتاح الترخيص
    final String licenseKey = "AS8ARpuBDytnQReAiwu/Ey4jPsx4D9nfU1754YcLeC85Qe99dWgHiuBLdLEqLolKenBDhklVcVAzXKoS70ocgSYr8oELWDwEwA3u04xmwCHAGsDXpHjwu9FR2/T+OH5t4TxB6BIeYXjKP2qqBMm3YTjFEfinK3PKo/HGgz2+8R100ZP6Y0nRM+/R89AWoiah8CBRzQ8MG5K5xQpztNT7b+uCXAbSUjEJ3P/KTmsBGuFHdIgexZ8HcINW3l11eOfnUju/Z1LtQF7GJrMtpXT59hfoV8sjYDxiS0/Tj+fmSdTTkL+zVr/yqBnBm9qf+eR6EvA0TEUWHLQOjrWiFS7tDOnS68CdyT0fE9XgBn9wfFJLQSNmMHAaqDtqlV1eC3PgYPig47E4mY38jTY2OzOA0d9LLcw5JOtZO8c+OZKc85fBcanJZaOnfoTE+7Jvw8ON3r6R3oP743zRhPfRyhCX6qZVxMPa/D47bJq+IWhlCTrFJsOgDVD2/bKC1du6kukN5LhAFaZxPKEJBgKcUzG4uHTdCYqFW1cVZTNzo6ktaDg7Fn9ywJrLF8xMjVqoiZyDQf37spX4RA0P7fmTC60o9A6veiIYQ2UkGebKQ5FTC+Ak+3RFgrnBv98kO84pN5p6cWEQiw3JlhRqRgCq0ZhHAtT3pLAg5A3FO5iaVqi9t993GlNb+gdT1lUo24bu4WhcAXhrgYrMatotDrbT3nbI75W56HKEUPcl81++jkSK2JVDckItmDtwWCW7bKRh2/HMiLG3+XOpFmevmDFNO/zN9eUylXpUoazLlF75nyDfCyqjaDz9OjY8zGGGPPU=";

    // 2. تهيئة الـ Context
    _context = scandit_core.DataCaptureContext.forLicenseKey(licenseKey);

    // 3. تفعيل الكاميرا الأساسية (الخلفية)
    _camera = scandit_core.Camera.defaultCamera;
    if (_camera != null) {
      _isTorchOn = settings.flash;
      _camera!.desiredTorchState = _isTorchOn ? scandit_core.TorchState.on : scandit_core.TorchState.off;
      _context!.setFrameSource(_camera!);
      _camera!.switchToDesiredState(scandit_core.FrameSourceState.on);
    }

    // 4. إعداد الأنواع المدعومة للباركود
    scandit_barcode_capture.BarcodeCaptureSettings captureSettings = scandit_barcode_capture.BarcodeCaptureSettings();
    captureSettings.enableSymbology(scandit_barcode.Symbology.qr, true);
    captureSettings.enableSymbology(scandit_barcode.Symbology.code128, true);
    captureSettings.enableSymbology(scandit_barcode.Symbology.code39, true);
    captureSettings.enableSymbology(scandit_barcode.Symbology.ean13Upca, true);
    captureSettings.enableSymbology(scandit_barcode.Symbology.ean8, true);
    
    // 5. ربط الإعدادات بمركز الالتقاط
    _barcodeCapture = scandit_barcode_capture.BarcodeCapture.forContext(_context!, captureSettings);
    _barcodeCapture!.addListener(this);

    if (mounted) {
      setState(() {
        _captureView = scandit_core.DataCaptureView.forContext(_context!);
      });
    }
  }

  @override
  Future<void> didScan(
      scandit_barcode_capture.BarcodeCapture barcodeCapture,
      scandit_barcode_capture.BarcodeCaptureSession session,
      Future<scandit_core.FrameData> Function() getFrameData) async {
    final code = session.newlyRecognizedBarcode?.data;
    if (code == null || code.isEmpty) return;

    final now = DateTime.now();
    final lockUntil = _locks[code];
    if (lockUntil != null && now.isBefore(lockUntil)) return;

    _locks[code] = now.add(const Duration(milliseconds: _lockDurationMs));
    if (_locks.length > 20) {
      final sorted = _locks.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (int i = 0; i < sorted.length - 20; i++) {
        _locks.remove(sorted[i].key);
      }
    }

    if (mounted) _flashCtrl.forward(from: 0);

    final settings = _settingsCubit.state;
    if (settings.vibrate) {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator == true) Vibration.vibrate(duration: 50);
      });
    }

    if (!settings.autoResume) {
      _barcodeCapture?.isEnabled = false;
    }

    // Wrap the result in mobile_scanner's BarcodeCapture to maintain compatibility
    final dummyBarcode = Barcode(rawValue: code, format: BarcodeFormat.unknown);
    final captureEvent = BarcodeCapture(barcodes: [dummyBarcode]);
    
    widget.onDetect(captureEvent);
  }

  @override
  Future<void> didUpdateSession(
      scandit_barcode_capture.BarcodeCapture barcodeCapture,
      scandit_barcode_capture.BarcodeCaptureSession session,
      Future<scandit_core.FrameData> Function() getFrameData) async {}

  void _toggleTorch() {
    if (_camera != null) {
      setState(() {
        _isTorchOn = !_isTorchOn;
        _camera!.desiredTorchState = _isTorchOn ? scandit_core.TorchState.on : scandit_core.TorchState.off;
      });
    }
  }

  @override
  void dispose() {
    _barcodeCapture?.removeListener(this);
    _camera?.switchToDesiredState(scandit_core.FrameSourceState.off);
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerSettingsCubit, ScannerSettingsState>(
      bloc: _settingsCubit,
      listenWhen: (prev, curr) =>
          prev.flash != curr.flash ||
          prev.symbologies != curr.symbologies,
      listener: (context, state) {
        if (_camera != null && _isTorchOn != state.flash) {
          _isTorchOn = state.flash;
          _camera!.desiredTorchState = _isTorchOn ? scandit_core.TorchState.on : scandit_core.TorchState.off;
        }
        if (!state.autoResume && _barcodeCapture != null) {
          _barcodeCapture!.isEnabled = true; // allow restart
        }
      },
      builder: (context, settings) {
        if (_captureView == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            if (ModalRoute.of(context)?.isCurrent ?? true)
              _captureView!
            else
              Container(color: Colors.black),
            AnimatedBuilder(
              animation: _flashOpacity,
              builder: (_, __) {
                final opacity = _flashOpacity.value;
                if (opacity <= 0) return const SizedBox.shrink();
                return Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: opacity),
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? Colors.yellow : Colors.white,
                  size: 32,
                ),
                onPressed: _toggleTorch,
              ),
            ),
            if (getIt<ApiClient>().isDebugMode)
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.keyboard, color: Colors.blueAccent, size: 32),
                  onPressed: () => _showManualEntryDialog(context),
                ),
              ),
            if (widget.overlay != null) widget.overlay!,
          ],
        );
      },
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Manual Entry (Debug)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: 'Enter barcode...',
            hintStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                final barcode = Barcode(rawValue: code, format: BarcodeFormat.unknown);
                final capture = BarcodeCapture(barcodes: [barcode]);
                widget.onDetect(capture);
              }
            },
            child: const Text('Simulate Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
