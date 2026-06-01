import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      
      if (widget.multiScan) {
        if (!_scannedItems.contains(code)) {
          setState(() {
            _scannedItems.add(code);
          });
        }
      } else {
        Navigator.pop(context, code);
      }
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
      body: Stack(
        children: [
          AppScanner(
            onDetect: _onDetect,
            overlay: Center(
              child: Container(
                width: 300,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -1,
                      left: -1,
                      child: _buildCorner(true, true),
                    ),
                    Positioned(
                      top: -1,
                      right: -1,
                      child: _buildCorner(true, false),
                    ),
                    Positioned(
                      bottom: -1,
                      left: -1,
                      child: _buildCorner(false, true),
                    ),
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: _buildCorner(false, false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (widget.multiScan)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          'Scanned Items (${_scannedItems.length})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (_scannedItems.isNotEmpty)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context, _scannedItems),
                            child: const AppText('Submit', style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                    if (_scannedItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
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
                                  AppText(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
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
                      ),
                    ] else ...[
                      const SizedBox(height: 32),
                      const Center(
                        child: AppText('No items scanned yet', style: TextStyle(color: Colors.white54)),
                      ),
                      const SizedBox(height: 32),
                    ]
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
