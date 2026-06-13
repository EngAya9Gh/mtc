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
import '../../../samples_pull_out/data/models/client_task_model.dart';

class DropOffLocationCheckScreen extends StatefulWidget {
  final DropOffCubit cubit;
  final ClientTaskModel destination;

  const DropOffLocationCheckScreen({
    super.key,
    required this.cubit,
    required this.destination,
  });

  @override
  State<DropOffLocationCheckScreen> createState() => _DropOffLocationCheckScreenState();
}

class _DropOffLocationCheckScreenState extends State<DropOffLocationCheckScreen> {
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _onScan() {
    final code = _barcodeController.text.trim();
    if (code.isNotEmpty) {
      widget.cubit.checkLocation(widget.destination, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        appBar: AppBar(
          title: AppText(isArabic ? 'التحقق من الموقع' : 'Location Check'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocConsumer<DropOffCubit, DropOffState>(
          listener: (context, state) {
            state.whenOrNull(
              error: (msg) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText(msg), backgroundColor: Colors.red),
                );
              },
              locationCheckSuccess: () {
                // Navigate to Task Token check (or bypass it)
                context.push(
                  AppRouter.dropOffTaskToken,
                  extra: {
                    'cubit': widget.cubit,
                    'destination': widget.destination,
                  },
                );
              },
            );
          },
          builder: (context, state) {
            final isLoading = state.maybeWhen(
              loading: (_) => true,
              orElse: () => false,
            );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined, size: 80, color: AppColors.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 24),
                  AppText(
                    isArabic ? 'الرجاء مسح باركود الموقع' : 'Please scan the location barcode',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    isArabic ? 'تنسيق الباركود: (رقم-location)' : 'Format: (number-location)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  // TextField(
                  //   controller: _barcodeController,
                  //   decoration: InputDecoration(
                  //     hintText: isArabic ? 'أدخل الباركود يدوياً...' : 'Enter barcode manually...',
                  //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  //     suffixIcon: IconButton(
                  //       icon: const Icon(Icons.qr_code_scanner),
                  //       onPressed: () {},
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 24),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    AppElevatedButton(
                      text: isArabic ? 'تحقق' : 'Verify',
                      onPressed: _onScan,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
