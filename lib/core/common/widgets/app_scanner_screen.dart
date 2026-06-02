import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'app_scanner.dart';
import 'app_text.dart';

class AppScannerScreen extends StatefulWidget {
  final bool multiScan;
  final String title;
  
  const AppScannerScreen({
    super.key, 
    this.multiScan = false,
    this.title = 'Scan Barcode',
  });

  @override
  State<AppScannerScreen> createState() => _AppScannerScreenState();
}

class _AppScannerScreenState extends State<AppScannerScreen> {
  final List<String> _scannedItems = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      
      if (widget.multiScan) {
        if (!_scannedItems.contains(code)) {
          setState(() {
            _scannedItems.add(code);
          });
          _playBeep();
        }
      } else {
        _playBeep();
        Navigator.pop(context, code);
      }
    }
  }

  void _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/scanner_beep.wav'));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(widget.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        actions: [
          if (widget.multiScan && _scannedItems.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _scannedItems);
              },
              child: const AppText('Done', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top Section: Camera Scanner
          Expanded(
            flex: widget.multiScan ? 4 : 10,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // scanWindow: 120px strip centered on laser line (widget coordinate space).
                // mobile_scanner v7 converts this internally to camera coordinates.
                final double centerY = constraints.maxHeight / 2;
                final Rect scanWindow = Rect.fromLTRB(
                  0,
                  centerY - 60,
                  constraints.maxWidth,
                  centerY + 60,
                );
                return Stack(
                  children: [
                    AppScanner(onDetect: _onDetect, scanWindow: scanWindow),
                    // Red laser line aligned exactly to scanWindow center
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.9),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),


          
          // Bottom Section: Scanned Items List
          if (widget.multiScan)
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A), // Slightly lighter than black for contrast
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          'العينات الممسوحة (${_scannedItems.length})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (_scannedItems.isNotEmpty)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context, _scannedItems),
                            child: const AppText('تأكيد', style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_scannedItems.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _scannedItems.length,
                          itemBuilder: (context, index) {
                            final item = _scannedItems[_scannedItems.length - 1 - index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppText(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _scannedItems.remove(item);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: AppText('لم يتم مسح أي عينة بعد', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Removed _buildCorner method as it is no longer needed
}
