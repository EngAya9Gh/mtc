import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../bloc/swap_tasks_cubit.dart';
import '../bloc/swap_tasks_state.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/common/widgets/app_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';


class SwapTaskScanBagsScreen extends StatefulWidget {
  const SwapTaskScanBagsScreen({super.key});

  @override
  State<SwapTaskScanBagsScreen> createState() => _SwapTaskScanBagsScreenState();
}

class _SwapTaskScanBagsScreenState extends State<SwapTaskScanBagsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ValueNotifier<String?> _scanErrorNotifier = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _scanErrorNotifier.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/scanner_beep.wav'));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        final cubit = context.read<SwapTasksCubit>();
        final state = cubit.state;
        
        state.maybeWhen(
          scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) {
            final hasBag = remainingBags.any((bag) => bag.bagCode.toLowerCase() == code.toLowerCase());
            if (hasBag) {
              _playBeep();
            }
            // Send to Cubit to match or error
            cubit.scanBagToAccept(code);
          },
          orElse: () {},
        );
        break;
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    // Get the selected task just once for the AppBar and basic layout.
    // The task itself doesn't change on this screen.
    final currentState = context.read<SwapTasksCubit>().state;
    final selectedTask = currentState.maybeWhen(
      scanningBags: (task, _, _, _) => task,
      orElse: () => null,
    );

    if (selectedTask == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.read<SwapTasksCubit>().getSwapTasks();
        context.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          centerTitle: true,
          title: AppText(
            isArabic
                ? 'مسح أكياس المهمة #${selectedTask.taskId > 0 ? selectedTask.taskId : selectedTask.id}'
                : 'Scan Bags #${selectedTask.taskId > 0 ? selectedTask.taskId : selectedTask.id}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              context.read<SwapTasksCubit>().getSwapTasks();
              context.pop();
            },
          ),
        ),
        body: Column(
          children: [
            // Scanner view: Now completely outside the BlocConsumer so it NEVER rebuilds!
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double centerY = constraints.maxHeight / 2;
                      final Rect scanWindow = Rect.fromLTRB(
                        0,
                        centerY - 60,
                        constraints.maxWidth,
                        centerY + 60,
                      );
                      return AppScanner(onDetect: _onDetect, scanWindow: scanWindow);
                    },
                  ),
                  // Red laser line — aligned to center
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.9),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bags List: Only this part rebuilds when state changes
            Expanded(
              child: BlocConsumer<SwapTasksCubit, SwapTasksState>(
                listener: (context, state) {
                  state.maybeWhen(
                    error: (message) {
                      if (message.contains('عذراً') || message.contains('الكيس') || message.contains('not required')) {
                        _scanErrorNotifier.value = message;
                        Future.delayed(const Duration(seconds: 2), () {
                          if (_scanErrorNotifier.value == message) {
                            _scanErrorNotifier.value = null;
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: AppText(message), backgroundColor: Colors.red),
                        );
                      }
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
                    scanningBags: (_, remainingBags, scannedBags, allBagsScanned) {
                      return Container(
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
                            
                            // Confirm Button & Error Text
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      if (!allBagsScanned) {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: AppText(isArabic ? 'تنبيه نقص الأكياس' : 'Bags Shortage Warning'),
                                            content: AppText(
                                              isArabic
                                                  ? 'يوجد نقص عدد ${remainingBags.length} أكياس لم يتم مسحها. هل أنت متأكد من استلام المهمة بالرغم من النقص؟'
                                                  : 'There is a shortage of ${remainingBags.length} unscanned bags. Are you sure you want to receive the task despite the shortage?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: AppText(isArabic ? 'إلغاء' : 'Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  context.read<SwapTasksCubit>().submitSwapAcceptance();
                                                },
                                                child: AppText(isArabic ? 'تأكيد' : 'Confirm', style: const TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        context.read<SwapTasksCubit>().submitSwapAcceptance();
                                      }
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
                                  const SizedBox(height: 8),
                                  ValueListenableBuilder<String?>(
                                    valueListenable: _scanErrorNotifier,
                                    builder: (context, errorMessage, _) {
                                      return AnimatedOpacity(
                                        duration: const Duration(milliseconds: 300),
                                        opacity: errorMessage != null ? 1.0 : 0.0,
                                        child: AppText(
                                          errorMessage ?? ' ',
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    orElse: () => const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
