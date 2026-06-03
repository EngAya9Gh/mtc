import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import '../../../features/settings/presentation/bloc/scanner_settings_cubit.dart';
import '../../services/di/di_container.dart';

/// Professional barcode scanner with:
///  • Strict scan-window post-detection filter (handles Android camera rotation)
///  • Scan & Lock debounce — same barcode locked 1.5 s after detection
///  • Subtle green border flash as scan confirmation
class AppScanner extends StatefulWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final Widget? overlay;
  // scanWindow in LOGICAL pixels, widget coordinate space (portrait)
  final Rect? scanWindow;

  const AppScanner({
    super.key,
    required this.onDetect,
    this.overlay,
    this.scanWindow,
  });

  @override
  State<AppScanner> createState() => _AppScannerState();
}

class _AppScannerState extends State<AppScanner>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  late ScannerSettingsCubit _settingsCubit;

  /// Widget dimensions — captured via LayoutBuilder for coordinate mapping
  Size _widgetSize = Size.zero;

  /// Per-barcode lock: ignored until now > _locks[code]
  final Map<String, DateTime> _locks = {};
  static const int _lockDurationMs = 1500;

  // ── Confirmation flash ────────────────────────────────────────────────────
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
    List<BarcodeFormat> formats = [];
    if (settings.symbologies['Code 128'] == true) formats.add(BarcodeFormat.code128);
    if (settings.symbologies['Code 39'] == true) formats.add(BarcodeFormat.code39);
    if (settings.symbologies['EAN-13'] == true) formats.add(BarcodeFormat.ean13);
    if (settings.symbologies['EAN-8'] == true) formats.add(BarcodeFormat.ean8);
    if (settings.symbologies['UPC-E'] == true) formats.add(BarcodeFormat.upcE);
    if (settings.symbologies['QR Code'] == true) formats.add(BarcodeFormat.qrCode);
    if (formats.isEmpty) formats = [BarcodeFormat.all];

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

  // ── Scan-window post-filter ───────────────────────────────────────────────
  //
  // Problem: on Android, MLKit returns barcode corners in the camera's
  // NATIVE coordinate space (landscape, e.g. 1280×720). But our scanWindow
  // is in the Flutter widget's coordinate space (portrait, e.g. 720×1600).
  //
  // Strategy:
  //   1. Treat the capture frame as portrait by always using its
  //      smaller dimension as width and larger as height.
  //   2. Normalise barcode centre to [0,1] in that portrait-oriented space.
  //   3. Normalise scan window to [0,1] in widget space.
  //   4. Compare — both spaces are now portrait-proportional.
  //
  bool _isInsideScanWindow(Barcode barcode, Size? rawFrameSize) {
    if (widget.scanWindow == null) return true;
    if (_widgetSize == Size.zero) return true;

    final corners = barcode.corners;
    if (corners == null || corners.isEmpty) return true;

    // Average corner position → barcode centre
    double fx = 0, fy = 0;
    for (final c in corners) {
      fx += c.dx;
      fy += c.dy;
    }
    fx /= corners.length;
    fy /= corners.length;

    // Step 1: determine the "oriented" frame size.
    //   Camera native frame is landscape (width > height).
    //   Device is in portrait (widgetHeight > widgetWidth).
    //   → swap frame dimensions so the coordinate space aligns with portrait.
    final Size orientedFrame;
    if (rawFrameSize != null &&
        rawFrameSize.width > rawFrameSize.height &&
        _widgetSize.height > _widgetSize.width) {
      // Landscape camera → portrait widget: swap W and H
      orientedFrame = Size(rawFrameSize.height, rawFrameSize.width);
    } else if (rawFrameSize != null) {
      orientedFrame = rawFrameSize;
    } else {
      // Fallback: use widget size itself
      orientedFrame = _widgetSize;
    }

    // Step 2: normalise barcode centre to [0,1]
    final normCx = (fx / orientedFrame.width).clamp(0.0, 1.0);
    final normCy = (fy / orientedFrame.height).clamp(0.0, 1.0);

    // Step 3: normalise scan window to [0,1]
    final winLeft   = widget.scanWindow!.left   / _widgetSize.width;
    final winRight  = widget.scanWindow!.right  / _widgetSize.width;
    final winTop    = widget.scanWindow!.top    / _widgetSize.height;
    final winBottom = widget.scanWindow!.bottom / _widgetSize.height;

    // Step 4: compare
    return normCx >= winLeft &&
           normCx <= winRight &&
           normCy >= winTop &&
           normCy <= winBottom;
  }

  // ── Detection logic ───────────────────────────────────────────────────────

  void _handleDetection(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue ?? '';
    if (code.isEmpty) return;

    // ① Position filter — reject barcodes outside the scan window
    if (!_isInsideScanWindow(barcode, capture.size)) return;

    // ② Scan & Lock — reject same barcode within cooldown
    final now = DateTime.now();
    final lockUntil = _locks[code];
    if (lockUntil != null && now.isBefore(lockUntil)) return;

    // ③ Accept — update lock
    _locks[code] = now.add(const Duration(milliseconds: _lockDurationMs));
    if (_locks.length > 20) {
      final sorted = _locks.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (int i = 0; i < sorted.length - 20; i++) {
        _locks.remove(sorted[i].key);
      }
    }

    // ④ Green border flash
    if (mounted) _flashCtrl.forward(from: 0);

    // ⑤ Haptic feedback
    final settings = _settingsCubit.state;
    if (settings.vibrate) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) Vibration.vibrate(duration: 50);
    }

    if (!settings.autoResume) _controller?.stop();

    widget.onDetect(capture);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            // Capture widget size for coordinate normalisation
            _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Camera feed ────────────────────────────────────────────
                // scanWindow is passed in logical pixels so mobile_scanner
                // can also hint MLKit about the detection region (belt & braces)
                MobileScanner(
                  controller: _controller!,
                  scanWindow: widget.scanWindow,
                  onDetect: _handleDetection,
                ),

                // ── Green border flash (no filled overlay) ─────────────────
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

                // ── Torch button ───────────────────────────────────────────
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

                if (widget.overlay != null) widget.overlay!,
              ],
            );
          },
        );
      },
    );
  }
}
