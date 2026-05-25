import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/drop_off_cubit.dart';
import '../bloc/drop_off_state.dart';

class DropOffScanBagsScreen extends StatelessWidget {
  final DropOffCubit cubit;

  const DropOffScanBagsScreen({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: const _DropOffScanBagsScreenView(),
    );
  }
}

class _DropOffScanBagsScreenView extends StatefulWidget {
  const _DropOffScanBagsScreenView();

  @override
  State<_DropOffScanBagsScreenView> createState() => _DropOffScanBagsScreenViewState();
}

class _DropOffScanBagsScreenViewState extends State<_DropOffScanBagsScreenView> {
  final TextEditingController _bagController = TextEditingController();

  @override
  void dispose() {
    _bagController.dispose();
    super.dispose();
  }

  void _onManualBagSubmit() {
    final code = _bagController.text.trim();
    if (code.isNotEmpty) {
      context.read<DropOffCubit>().scanBagToDeliver(code);
      _bagController.clear();
    }
  }

  Widget _buildTemperatureBadge(String type) {
    Color bgColor;
    Color textColor;
    switch (type.toUpperCase()) {
      case 'ROOM':
      case 'ROOM_TEMP':
        bgColor = const Color(0xFFE8F5E9); // Soft Green
        textColor = const Color(0xFF2E7D32);
        break;
      case 'REFRIGERATE':
      case 'COLD':
        bgColor = const Color(0xFFE3F2FD); // Soft Blue
        textColor = const Color(0xFF1565C0);
        break;
      case 'FROZEN':
        bgColor = const Color(0xFFEDE7F6); // Soft Purple
        textColor = const Color(0xFF651FFF);
        break;
      default:
        bgColor = const Color(0xFFFFF3E0); // Soft Orange
        textColor = const Color(0xFFE65100);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText(
        type,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'مسح أكياس التسليم' : 'Scan Drop Off Bags'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<DropOffCubit, DropOffState>(
        listener: (context, state) {
          state.whenOrNull(
            error: (msg) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(msg), backgroundColor: Colors.red),
              );
            },
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
            scanningBags: (selectedTask, remainingBags, scannedBags, allBagsScanned) {
              if (allBagsScanned) {
                return _buildAllBagsScannedView(context, isArabic);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Camera simulation box for bags
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondary, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 56,
                                color: AppColors.secondary.withOpacity(0.8),
                              ),
                              const SizedBox(height: 12),
                              AppText(
                                isArabic ? 'وجّه الكاميرا لمسح كيس العينة لتسليمه' : 'Point camera to scan bag to drop off',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 90,
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(color: Colors.redAccent, blurRadius: 4, spreadRadius: 1),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Manual text field for bags
                    TextField(
                      controller: _bagController,
                      decoration: InputDecoration(
                        hintText: isArabic ? 'أو أدخل باركود الكيس يدوياً' : 'Or type bag barcode',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _onManualBagSubmit,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Simulate button for testing
                    if (remainingBags.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.bug_report),
                        label: AppText(isArabic ? 'مسح الكيس الأول وهمياً' : 'Mock scan first bag'),
                        onPressed: () {
                          _bagController.text = remainingBags.first.bagCode;
                          _onManualBagSubmit();
                        },
                      ),
                      
                    const SizedBox(height: 24),

                    // Remaining bags list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          isArabic ? 'الأكياس المتبقية للتسليم' : 'Bags left to drop off',
                          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppText(
                            '${remainingBags.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: remainingBags.length,
                      itemBuilder: (context, index) {
                        final bag = remainingBags[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Styled Header for Task ID
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.06),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.assignment_outlined,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    AppText(
                                      isArabic 
                                          ? 'رقم المهمة: #${bag.taskId}' 
                                          : 'Task ID: #${bag.taskId}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    _buildTemperatureBadge(bag.temperatureType),
                                  ],
                                ),
                              ),
                              
                              // Card Body containing Bag Code
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            isArabic ? 'كود الكيس' : 'Bag Code',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          AppText(
                                            bag.bagCode,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.textPrimary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildAllBagsScannedView(BuildContext context, bool isArabic) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppText.titleLarge(
                    isArabic ? 'تمت مطابقة جميع الأكياس' : 'All Bags Matched',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    isArabic 
                        ? 'تم مسح وتأكيد جميع أكياس العينات المطلوبة للتسليم بنجاح.'
                        : 'All required sample bags for drop off have been successfully scanned and verified.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  AppElevatedButton(
                    text: isArabic ? 'الانتقال للتوقيع' : 'PROCEED TO SIGNATURE',
                    onPressed: () {
                      context.read<DropOffCubit>().proceedToSignature();
                      context.pushReplacement(
                        AppRouter.dropOffSignature,
                        extra: context.read<DropOffCubit>(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
