import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import '../../../features/settings/presentation/bloc/scanner_settings_cubit.dart';
import '../../services/di/di_container.dart';

class AppScanner extends StatefulWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final Widget? overlay;
  final Rect? scanWindow;

  const AppScanner({super.key, required this.onDetect, this.overlay, this.scanWindow});

  @override
  State<AppScanner> createState() => _AppScannerState();
}

class _AppScannerState extends State<AppScanner> {
  MobileScannerController? _controller;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  late ScannerSettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    _settingsCubit = getIt<ScannerSettingsCubit>();
    _initController(_settingsCubit.state);
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

    Size? resolution;
    if (settings.cameraResolution == 'HD') {
      resolution = const Size(1280, 720);
    } else if (settings.cameraResolution == 'UHD') {
      resolution = const Size(3840, 2160);
    } else {
      // Default to HD — fast enough for all barcodes, much faster than Full HD
      resolution = const Size(1280, 720);
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
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;

    final code = capture.barcodes.first.rawValue ?? '';
    if (code.isEmpty) return;

    final now = DateTime.now();
    final settings = _settingsCubit.state;

    if (_lastScannedCode == code && _lastScanTime != null) {
      // Same barcode: enforce minimum cooldown (800ms) to avoid MLKit duplicates
      if (now.difference(_lastScanTime!).inMilliseconds < 800) return;
    }
    // Different barcode: scan immediately — no wait

    _lastScannedCode = code;
    _lastScanTime = now;

    // Vibration feedback
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
      builder: (context, state) {
        if (_controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            MobileScanner(
              controller: _controller!,
              scanWindow: widget.scanWindow,
              onDetect: _handleDetection,
            ),
            Positioned(
              top: 16,
              right: 16,
              child: ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller!,
                builder: (context, state, child) {
                  final torchOn = state.torchState == TorchState.on;
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
  }
}
