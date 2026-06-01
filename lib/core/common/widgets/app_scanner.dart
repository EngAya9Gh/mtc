import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import '../../../features/settings/presentation/bloc/scanner_settings_cubit.dart';
import '../../services/di/di_container.dart';

class AppScanner extends StatefulWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final Widget? overlay;

  const AppScanner({super.key, required this.onDetect, this.overlay});

  @override
  State<AppScanner> createState() => _AppScannerState();
}

class _AppScannerState extends State<AppScanner> {
  MobileScannerController? _controller;
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

    // Provide a sensible default if none selected
    if (formats.isEmpty) {
      formats = [BarcodeFormat.all];
    }

    Size? resolution;
    if (settings.cameraResolution == 'HD') {
      resolution = const Size(1280, 720);
    } else if (settings.cameraResolution == 'UHD') {
      resolution = const Size(3840, 2160);
    } else {
      resolution = const Size(1920, 1080); // Full HD
    }

    _controller = MobileScannerController(
      formats: formats,
      cameraResolution: resolution,
      torchEnabled: settings.flash,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) async {
    final settings = _settingsCubit.state;
    final now = DateTime.now();

    // Duplicate filter / Hold time
    if (_lastScanTime != null) {
      final diff = now.difference(_lastScanTime!).inMilliseconds;
      if (diff < (settings.holdTime * 1000)) {
        return; // Ignore duplicate/rapid scans
      }
    }

    _lastScanTime = now;

    // Feedback
    if (settings.beep) {
      SystemSound.play(SystemSoundType.click);
    }
    if (settings.vibrate) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 100);
      }
    }

    // Auto-Resume logic
    if (!settings.autoResume) {
      _controller?.stop(); // Or pause if available. stop() requires starting again.
    }

    widget.onDetect(capture);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerSettingsCubit, ScannerSettingsState>(
      bloc: _settingsCubit,
      listenWhen: (previous, current) {
        // Rebuild controller if critical settings change
        return previous.flash != current.flash ||
            previous.cameraResolution != current.cameraResolution ||
            previous.symbologies != current.symbologies;
      },
      listener: (context, state) {
        // Re-initialize controller when settings are applied
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
              onDetect: _handleDetection,
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: _controller!,
                  builder: (context, state, child) {
                    final torchState = state.torchState;
                    return Icon(
                      torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                      color: torchState == TorchState.on ? Colors.yellow : Colors.white,
                      size: 32,
                    );
                  },
                ),
                onPressed: () => _controller!.toggleTorch(),
              ),
            ),
            if (widget.overlay != null) widget.overlay!,
          ],
        );
      },
    );
  }
}
