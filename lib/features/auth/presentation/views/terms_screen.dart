import 'dart:io';
import 'dart:ui' as ui;
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
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    
    return BlocProvider(
      create: (context) => TermsCubit(getIt())..getTerms(),
      child: BlocConsumer<TermsCubit, TermsState>(
        listener: (context, state) {
          state.maybeWhen(
            success: () {
              // Only go to main if we came from login, otherwise just show success
              if (GoRouterState.of(context).uri.toString() == '/terms') {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isArabic ? 'تم قبول الشروط بنجاح' : 'Terms accepted successfully'), backgroundColor: Colors.green),
                );
              } else {
                context.go(AppRouter.main);
              }
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
              title: AppText(
                isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (arLink, enLink) => _buildBody(context, arLink, enLink, state, l),
              submitting: () => const Center(child: CircularProgressIndicator()),
              orElse: () => _buildBody(context, '', '', state, l),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, String arLink, String enLink, TermsState state, AppLocalizations l) {
    final isArabic = l.isArabic;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: AppText(
                    isArabic ? 'يرجى مراجعة الشروط بلغتك المفضلة' : 'Review the terms in your preferred language:',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 32),
          AppText(
            isArabic ? 'التوقيع الرقمي' : 'Digital Signature',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
          ),
          AppText(
            isArabic ? 'يرجى التوقيع في المساحة أدناه' : 'Please sign in the space below',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: HandSignature(
                  control: _signatureControl,
                  color: AppColors.primary,
                  width: 3.0,
                  maxWidth: 10.0,
                  type: SignatureDrawType.shape,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _signatureControl.clear(),
                icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
                label: AppText(
                  isArabic ? 'مسح التوقيع' : 'Clear',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: AppElevatedButton(
                  text: isArabic ? 'موافق' : 'ACCEPT',
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
    final l = AppLocalizations.of(context);
    if (_signatureControl.paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.isArabic ? 'يرجى وضع توقيعك أولاً' : 'Please provide your signature first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final image = await _signatureControl.toImage(
      color: Colors.black,
      background: Colors.white,
      fit: true,
    );

    if (image != null) {
      final ByteData? bytes = image is ByteData ? image : await (image as ui.Image).toByteData(format: ui.ImageByteFormat.png);
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
