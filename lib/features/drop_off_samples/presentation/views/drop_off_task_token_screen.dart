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

class DropOffTaskTokenScreen extends StatefulWidget {
  final DropOffCubit cubit;
  final ClientTaskModel destination;

  const DropOffTaskTokenScreen({
    super.key,
    required this.cubit,
    required this.destination,
  });

  @override
  State<DropOffTaskTokenScreen> createState() => _DropOffTaskTokenScreenState();
}

class _DropOffTaskTokenScreenState extends State<DropOffTaskTokenScreen> {
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _onScan() {
    final code = _tokenController.text.trim();
    if (code.isNotEmpty) {
      widget.cubit.checkTaskToken(widget.destination, code);
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
          title: AppText(isArabic ? 'التحقق من توكن المهام' : 'Task Token Check'),
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
                // Both location and token verified successfully, proceed to scan bags
                widget.cubit.proceedToScanBags(widget.destination);
                context.pushReplacement(
                  AppRouter.dropOffScanBags,
                  extra: widget.cubit,
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
                  Icon(Icons.qr_code, size: 80, color: AppColors.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 24),
                  AppText(
                    isArabic ? 'الرجاء مسح باركود التوكن (Takasi Number)' : 'Please scan the Task Token barcode',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      hintText: isArabic ? 'أدخل التوكن يدوياً...' : 'Enter token manually...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    AppElevatedButton(
                      text: isArabic ? 'متابعة' : 'Proceed',
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
