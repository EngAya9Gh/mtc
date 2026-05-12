import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/di/di_container.dart';
import '../bloc/terms_cubit.dart';
import '../bloc/terms_state.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final HandSignatureControl _signatureControl = HandSignatureControl();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TermsCubit(getIt())..getTerms(),
      child: BlocConsumer<TermsCubit, TermsState>(
        listener: (context, state) {
          state.maybeWhen(
            success: () {
              context.go(AppRouter.main);
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: AppColors.error),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Terms & Conditions'),
              centerTitle: true,
            ),
            body: state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (arLink, enLink) => _buildBody(context, arLink, enLink, state),
              submitting: () => const Center(child: CircularProgressIndicator()),
              orElse: () => _buildBody(context, '', '', state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, String arLink, String enLink, TermsState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText(
            'Review the terms in your preferred language:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LanguageButton(
                  label: 'العربية',
                  onPressed: () => _launchUrl(arLink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LanguageButton(
                  label: 'English',
                  onPressed: () => _launchUrl(enLink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const AppText(
            'Please provide your digital signature below:',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: HandSignature(
                control: _signatureControl,
                color: AppColors.primary,
                width: 3.0,
                maxWidth: 10.0,
                type: SignatureDrawType.shape,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _signatureControl.clear(),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                child: AppElevatedButton(
                  text: 'Accept',
                  isLoading: state is Submitting,
                  onPressed: () => _onAccept(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept(BuildContext context) async {
    if (_signatureControl.isPathEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your signature first')),
      );
      return;
    }

    final image = await _signatureControl.toImage(
      color: Colors.black,
      background: Colors.white,
      fit: true,
    );

    if (image != null) {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      if (bytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/signature.png');
        await file.writeAsBytes(bytes.buffer.asUint8List());
        
        if (mounted) {
          context.read<TermsCubit>().acceptTerms(file);
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _LanguageButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
