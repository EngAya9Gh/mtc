import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../features/settings/presentation/bloc/scanner_settings_cubit.dart';
import '../../services/di/di_container.dart';
import 'app_scanner.dart';

// ─────────────────────────────────────────────────────────────────────────────
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
    if (kIsWeb) {
      return const SizedBox(child: Center(child: Text('Web Scanner Not Supported')));
    }

    final settings = getIt<ScannerSettingsCubit>().state;

    Widget scannerWidget = _BarqScanWebViewImpl(
      onDetect: onDetect,
      overlay: overlay,
      settings: settings,
    );

    // Debug mode: add manual barcode entry field
    if (kDebugMode) {
      return Stack(
        fit: StackFit.expand,
        children: [
          scannerWidget,
          Positioned(
            bottom: 40, left: 20, right: 20,
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
      );
    }

    return scannerWidget;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _BarqScanWebViewImpl extends StatefulWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final Widget? overlay;
  final ScannerSettingsState settings;

  const _BarqScanWebViewImpl({
    required this.onDetect,
    this.overlay,
    required this.settings,
  });

  @override
  State<_BarqScanWebViewImpl> createState() => _BarqScanWebViewImplState();
}

// ─────────────────────────────────────────────────────────────────────────────
class _BarqScanWebViewImplState extends State<_BarqScanWebViewImpl>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isCameraGranted = false;
  bool _isScannerReady = false;
  late bool _isFlashOn;
  Timer? _readyTimeout;

  // Dart-level duplicate-scan guard (supplements BarqScan's duplicateFilter)
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  // ── Settings → JS values ───────────────────────────────────────────────────

  /// Active barcode symbologies as a JS array literal, e.g. "code128", "ean13"
  String get _jsSymbologies {
    final s = widget.settings.symbologies;
    final list = <String>[];
    if (s['Code 128'] == true) list.add('code128');
    if (s['Code 39']  == true) list.add('code39');
    if (s['EAN-13']   == true) list.add('ean13');
    if (s['EAN-8']    == true) list.add('ean8');
    if (s['UPC-E']    == true) list.add('upce');
    if (s['QR Code']  == true) list.add('qr');
    if (list.isEmpty) list.add('code128'); // always at least one
    return list.map((e) => '"$e"').join(', ');
  }

  /// Duplicate-filter duration in ms (= holdTime seconds × 1000)
  int get _duplicateFilterMs => (widget.settings.holdTime * 1000).round();

  /// maxDecodeWidth controls the decode quality/resolution.
  /// BarqScan downscales frames to this width before decoding.
  /// Higher = more accurate but slower; lower = faster.
  int get _maxDecodeWidth {
    switch (widget.settings.cameraResolution) {
      case 'UHD':     return 3840;
      case 'Full HD': return 1920;
      default:        return 1280; // HD — good balance of speed & accuracy
    }
  }

  // ── HTML string (generated once per scanner open) ─────────────────────────
  String get _barqscanHtml => '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"/>
  <style>
    html, body { margin:0; padding:0; width:100%; height:100%; background:#000; overflow:hidden; }
    #scanner { width:100vw; height:100vh; overflow:hidden; }
    video { display:block; }
    /* Hide native video controls & play overlay */
    video::-webkit-media-controls,
    video::-webkit-media-controls-enclosure,
    video::-webkit-media-controls-panel,
    video::-webkit-media-controls-play-button,
    video::-webkit-media-controls-overlay-play-button { display:none !important; opacity:0 !important; }
    
    /* Hide BarqScan's container completely to hide its white mask and green boxes */
    #scanner { opacity: 0 !important; position: absolute; top:0; left:0; width: 100vw; height: 100vh; pointer-events: none !important; z-index: 2; }
    
    /* Our custom video will be the ONLY thing visible */
    #bg-video { position: absolute; top: 0; left: 0; width: 100vw; height: 100vh; object-fit: cover; z-index: 1; }
  </style>
</head>
<body>
  <!-- Clean camera feed without BarqScan UI -->
  <video id="bg-video" playsinline autoplay muted></video>
  <!-- Hidden BarqScan container -->
  <div id="scanner"></div>

  <script src="https://cdn.jsdelivr.net/npm/@barqscan/web@0.1.3/dist/index.global.js"></script>
  <script>
    // ── Bridge to Flutter ────────────────────────────────────────────────────
    function toNative(msg) {
      if (window.BarqScanNative) window.BarqScanNative.postMessage(JSON.stringify(msg));
    }

    // ── Torch suppression via getUserMedia intercept ─────────────────────────
    // Merge resolution preference + strip torch from BarqScan's constraints.
    (function() {
      var idealWidth  = $_maxDecodeWidth;
      var idealHeight = Math.round(idealWidth * 9 / 16);

      var _origGUM = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
      navigator.mediaDevices.getUserMedia = async function(constraints) {
        if (constraints && constraints.video && typeof constraints.video === "object") {
          if (!constraints.video.width)  constraints.video.width  = { ideal: idealWidth };
          if (!constraints.video.height) constraints.video.height = { ideal: idealHeight };
          delete constraints.video.torch;
          if (Array.isArray(constraints.video.advanced)) {
            constraints.video.advanced = constraints.video.advanced.filter(function(c) {
              return !Object.prototype.hasOwnProperty.call(c, "torch");
            });
            if (!constraints.video.advanced.length) delete constraints.video.advanced;
          }
        }
        var stream = await _origGUM(constraints);
        
        // Attach stream to our clean bg-video
        var bgVideo = document.getElementById('bg-video');
        if (bgVideo) {
          bgVideo.srcObject = stream;
          bgVideo.play().catch(function(){});
        }

        // Log actual resolution chosen by the camera
        var tracks = stream.getVideoTracks();
        if (tracks.length > 0) {
          var settings = tracks[0].getSettings ? tracks[0].getSettings() : {};
          toNative({ type: "resolution", width: settings.width || 0, height: settings.height || 0 });
          // Apply torch=false immediately after stream opens
          var caps = tracks[0].getCapabilities ? tracks[0].getCapabilities() : {};
          if (caps.torch) {
            try { await tracks[0].applyConstraints({ advanced: [{ torch: false }] }); } catch(e) {}
          }
        }
        return stream;
      };
    })();

    // ── Smart torch watcher ──────────────────────────────────────────────────
    // Checks every 500ms if torch turned ON without user request → turns it off.
    // Unlike unconditional setInterval, this ONLY calls applyConstraints when
    // torch is actually on — no flicker from unnecessary toggling.
    setInterval(async function() {
      if (window._torchState) return; // user intentionally enabled torch
      document.querySelectorAll("video").forEach(async function(v) {
        if (!v.srcObject) return;
        v.srcObject.getVideoTracks().forEach(async function(track) {
          var settings = track.getSettings ? track.getSettings() : {};
          if (settings.torch === true) {
            var caps = track.getCapabilities ? track.getCapabilities() : {};
            if (caps.torch) {
              try { await track.applyConstraints({ advanced: [{ torch: false }] }); } catch(e) {}
            }
          }
        });
      });
    }, 500);

    // ── Camera stream health monitor ─────────────────────────────────────────
    // Detects when the camera stream dies (phone face-down, screen off, etc.)
    // and notifies Flutter to reload the scanner.
    setInterval(function() {
      var video = document.getElementById("bg-video");
      if (!video || !video.srcObject) return;
      var tracks = video.srcObject.getVideoTracks();
      if (tracks.length > 0 && tracks[0].readyState === "ended") {
        toNative({ type: "stream_ended" });
      }
    }, 2000);

    // React to visibility changes (screen on/off, app background)
    document.addEventListener("visibilitychange", function() {
      if (document.visibilityState !== "visible") return;
      setTimeout(function() {
        var video = document.getElementById("bg-video");
        if (!video) return;
        if (video.srcObject) {
          var tracks = video.srcObject.getVideoTracks();
          if (tracks.length > 0 && tracks[0].readyState !== "ended") {
            video.play().catch(function(){});
            return;
          }
        }
        toNative({ type: "stream_ended" });
      }, 500);
    });

    // ── Keep video playing inline ────────────────────────────────────────────
    function enforceVideo() {
      document.querySelectorAll("video").forEach(function(v) {
        v.setAttribute("playsinline", "true");
        v.setAttribute("autoplay", "true");
        v.muted = true;
        v.controls = false;
        if (v.paused) v.play().catch(function(){});
        if (!v._pauseGuard) {
          v._pauseGuard = true;
          v.addEventListener("pause", function() { v.play().catch(function(){}); });
        }
      });
    }
    new MutationObserver(enforceVideo).observe(document.body, { childList:true, subtree:true });

    // ── Main scanner init ────────────────────────────────────────────────────
    (async function() {
      try {
        await BarqScan.configure("BARQ-E32J3-BJMWC-0Q6JW-58JV1");

        window.activeScanner = await BarqScan.ScannerView.create(
          document.getElementById("scanner"),
          {
            symbologies:     [$_jsSymbologies],
            duplicateFilter: $_duplicateFilterMs,
            playSoundOnScan: ${widget.settings.beep},
            autoZoom:        false,
            maxDecodeWidth:  $_maxDecodeWidth,
            // ROI: center 10% of frame strictly for red line
            roi: { x: 0.0, y: 0.45, width: 1.0, height: 0.10 }
          }
        );

        // ── Torch control ────────────────────────────────────────────────────
        // Save the real SDK setTorch, then replace it with a no-op so
        // BarqScan cannot auto-activate the flash.
        var _realTorch = window.activeScanner.torchSupported
          ? window.activeScanner.setTorch.bind(window.activeScanner)
          : function() {};

        // userSetTorch() is called by Flutter via runJavaScript
        window.userSetTorch = function(on) {
          window._torchState = on;
          _realTorch(on);
          // Also push directly to track for hardware control
          document.querySelectorAll("video").forEach(async function(v) {
            if (!v.srcObject) return;
            v.srcObject.getVideoTracks().forEach(async function(track) {
              var caps = track.getCapabilities ? track.getCapabilities() : {};
              if (caps.torch) {
                try { await track.applyConstraints({ advanced: [{ torch: on }] }); } catch(e) {}
              }
            });
          });
        };

        // Block all internal BarqScan torch calls
        window.activeScanner.setTorch = function() {};
        window._torchState = $_isFlashOn;
        _realTorch($_isFlashOn); // apply initial torch state

        // ── Scan event ───────────────────────────────────────────────────────
        window.activeScanner.on("scan", function(evt) {
          for (var i = 0; i < evt.barcodes.length; i++) {
            toNative({ type: "scan", data: evt.barcodes[i].data });
          }
        });

        enforceVideo();
        toNative({ type: "ready" });

      } catch(err) {
        toNative({ type: "error", message: String((err && err.message) || err) });
      }
    })();
  </script>
</body>
</html>
  ''';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _isFlashOn = widget.settings.flash;
    WidgetsBinding.instance.addObserver(this);
    _initScanner();
  }

  @override
  void dispose() {
    _readyTimeout?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Force stop camera hardware before destroying the WebView
    _controller.runJavaScript('''
      if (window.activeScanner) {
        try { window.activeScanner.destroy(); } catch(e) {}
      }
      document.querySelectorAll("video").forEach(function(v) {
        if (v.srcObject) {
          v.srcObject.getTracks().forEach(function(track) {
            track.stop();
          });
        }
      });
    ''');
    super.dispose();
  }

  /// Fix white screen: when app returns from background, force video to resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCameraGranted) {
      // Stream resume is handled by visibilitychange in JS, but we ensure
      // the flutter side doesn't block it.
      _controller.runJavaScript('''
        var v = document.getElementById("bg-video");
        if (v) v.play().catch(function(){});
      ''');
    }
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _isCameraGranted = true);
      _setupWebView();
    }
  }

  void _setupWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('BarqScanNative', onMessageReceived: _onJsMessage)
      ..setNavigationDelegate(NavigationDelegate());

    if (_controller.platform is AndroidWebViewController) {
      final ac = _controller.platform as AndroidWebViewController;
      AndroidWebViewController.enableDebugging(kDebugMode);
      ac.setMediaPlaybackRequiresUserGesture(false);
      ac.setOnPlatformPermissionRequest((r) => r.grant());
    }

    _controller.loadHtmlString(_barqscanHtml, baseUrl: 'https://gosample.com/');

    // Safety timeout: if JS never sends "ready" in 20s, show camera anyway
    _readyTimeout = Timer(const Duration(seconds: 20), () {
      if (mounted && !_isScannerReady) {
        setState(() => _isScannerReady = true);
      }
    });
  }

  void _onJsMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      switch (data['type']) {
        case 'ready':
          _readyTimeout?.cancel();
          if (mounted) setState(() => _isScannerReady = true);
          break;

        case 'scan':
          final code = (data['data'] ?? '').toString().trim();
          if (code.isEmpty) break;

          // ── Dart-level duplicate guard ──────────────────────────────────
          // Rejects the same barcode if it arrives again within holdTime.
          // This is a safety net on top of BarqScan's own duplicateFilter.
          final holdMs = (widget.settings.holdTime * 1000).round();
          final now = DateTime.now();
          if (_lastScannedCode == code &&
              _lastScanTime != null &&
              now.difference(_lastScanTime!).inMilliseconds < holdMs) {
            break; // same barcode within hold window — ignore
          }
          _lastScannedCode = code;
          _lastScanTime = now;
          // ───────────────────────────────────────────────────────────────

          if (widget.settings.vibrate) {
            Vibration.hasVibrator().then((ok) {
              if (ok == true) Vibration.vibrate(duration: 100);
            });
          }
          widget.onDetect(BarcodeCapture(
            barcodes: [Barcode(rawValue: code, displayValue: code, format: BarcodeFormat.unknown)],
          ));
          break;

        case 'resolution':
          // Log the actual camera resolution chosen by the device
          final w = data['width'] ?? 0;
          final h = data['height'] ?? 0;
          debugPrint('[BarqScan] Actual camera resolution: ${w}x${h}');
          break;

        case 'stream_ended':
          // Camera stream died (screen off, phone face-down, etc.)
          debugPrint('[BarqScan] Stream ended — reloading scanner...');
          if (!mounted) break;
          setState(() => _isScannerReady = false);
          _readyTimeout?.cancel();
          
          // Force stop any lingering tracks before reloading
          _controller.runJavaScript('document.querySelectorAll("video").forEach(function(v){ if(v.srcObject) v.srcObject.getTracks().forEach(function(t){t.stop();}); });');
          
          // Add delay to let Android camera service release the lock
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            _controller.loadHtmlString(_barqscanHtml, baseUrl: 'https://gosample.com/');
            _readyTimeout = Timer(const Duration(seconds: 20), () {
              if (mounted && !_isScannerReady) setState(() => _isScannerReady = true);
            });
          });
          break;

        case 'error':
          debugPrint('[BarqScan] JS Error: ${data["message"]}');
          _readyTimeout?.cancel();
          if (mounted && !_isScannerReady) setState(() => _isScannerReady = true);
          break;
      }
    } catch (e) {
      debugPrint('[BarqScan] Message parse error: $e');
    }
  }


  void _toggleFlash() {
    final newVal = !_isFlashOn;
    setState(() => _isFlashOn = newVal);
    final jsVal = newVal ? 'true' : 'false';
    _controller.runJavaScript('if(window.userSetTorch) window.userSetTorch($jsVal);');
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isCameraGranted) {
      return Container(
        color: Colors.black,
        child: const Center(child: Icon(Icons.videocam_off, color: Colors.white54, size: 52)),
      );
    }

    // Use HybridComposition on Android to avoid BLASTBufferQueue GPU overflow.
    // SurfaceView (default) competes with Flutter's GPU buffers → "max frames" crash.
    // TextureView (HybridComposition) renders inside Flutter's texture layer safely.
    final Widget cameraView;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      cameraView = WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: _controller.platform,
          displayWithHybridComposition: true,
        ),
      );
    } else {
      cameraView = WebViewWidget(controller: _controller);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        cameraView,

        // Loading overlay — hidden once JS sends "ready" (or after 20s timeout)
        if (!_isScannerReady)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white38, size: 64),
                  SizedBox(height: 20),
                  CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                  SizedBox(height: 14),
                  Text('جارٍ تهيئة الكاميرا…',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          ),

        if (widget.overlay != null) widget.overlay!,

        // Flash toggle button
        if (_isScannerReady)
          Positioned(
            top: 20,
            right: 16,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              elevation: 4,
              child: IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? Colors.yellowAccent : Colors.white70,
                  size: 24,
                ),
                onPressed: _toggleFlash,
              ),
            ),
          ),
      ],
    );
  }
}

