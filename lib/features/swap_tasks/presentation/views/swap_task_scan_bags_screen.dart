import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../bloc/swap_tasks_cubit.dart';
import '../bloc/swap_tasks_state.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SwapTaskScanBagsScreen extends StatefulWidget {
  const SwapTaskScanBagsScreen({super.key});

  @override
  State<SwapTaskScanBagsScreen> createState() => _SwapTaskScanBagsScreenState();
}

class _SwapTaskScanBagsScreenState extends State<SwapTaskScanBagsScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanning = false); // Pause scanning
        
        // Process barcode
        context.read<SwapTasksCubit>().scanBagToAccept(barcode.rawValue!);
        
        // Wait 1.5 seconds then resume
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _isScanning = true);
          }
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return BlocConsumer<SwapTasksCubit, SwapTasksState>(
      listener: (context, state) {
        state.maybeWhen(
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppText(message), backgroundColor: Colors.red),
            );
          },
          actionSuccess: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppText(message), backgroundColor: Colors.green),
            );
            // Go back to the Swap Tasks list
            context.pop();
            context.pop();
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.maybeWhen(
          scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) {
            return Scaffold(
              backgroundColor: const Color(0xFFF7F9FC),
              appBar: AppBar(
                elevation: 0,
                backgroundColor: AppColors.primary,
                centerTitle: true,
                title: AppText(
                  isArabic ? 'مسح أكياس المهمة #${selectedTask.id}' : 'Scan Bags #${selectedTask.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Column(
                children: [
                  // Scanner view
                  SizedBox(
                    height: 250,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        ),
                        // Scanner Overlay
                        Container(
                          decoration: ShapeDecoration(
                            shape: _ScannerOverlayShape(
                              borderColor: _isScanning ? AppColors.primary : Colors.grey,
                              borderWidth: 3.0,
                              overlayColor: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                        if (!_isScanning)
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: AppColors.primary),
                                  const SizedBox(height: 16),
                                  AppText(
                                    isArabic ? 'جاري التحقق...' : 'Verifying...',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bags List
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  isArabic ? 'الأكياس المتبقية' : 'Remaining Bags',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: AppText(
                                    '${remainingBags.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: remainingBags.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                                        ),
                                        const SizedBox(height: 16),
                                        AppText(
                                          isArabic ? 'تم مسح جميع الأكياس بنجاح' : 'All bags scanned successfully',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: remainingBags.length,
                                    itemBuilder: (context, index) {
                                      final bag = remainingBags[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFEEEEEE)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: AppText(
                                                bag.bagCode,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            AppText(
                                              bag.temperatureType,
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          
                          // Confirm Button
                          if (allBagsScanned)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<SwapTasksCubit>().submitSwapAcceptance();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: AppText(
                                  isArabic ? 'تأكيد استلام المهمة' : 'Confirm Task Receipt',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          orElse: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color(0x88000000),
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getClipPath(Rect rect) {
      return Path()
        ..addRect(Rect.fromLTWH(rect.left + 40, rect.top + 40, rect.width - 80, rect.height - 80));
    }

    return Path()
      ..addRect(rect)
      ..addPath(_getClipPath(rect), Offset.zero);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final borderSize = 30.0;

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    
    final r = Rect.fromLTWH(rect.left + 40, rect.top + 40, rect.width - 80, rect.height - 80);

    // Top left corner
    path.moveTo(r.left, r.top + borderSize);
    path.lineTo(r.left, r.top);
    path.lineTo(r.left + borderSize, r.top);

    // Top right corner
    path.moveTo(r.right - borderSize, r.top);
    path.lineTo(r.right, r.top);
    path.lineTo(r.right, r.top + borderSize);

    // Bottom right corner
    path.moveTo(r.right, r.bottom - borderSize);
    path.lineTo(r.right, r.bottom);
    path.lineTo(r.right - borderSize, r.bottom);

    // Bottom left corner
    path.moveTo(r.left + borderSize, r.bottom);
    path.lineTo(r.left, r.bottom);
    path.lineTo(r.left, r.bottom - borderSize);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
