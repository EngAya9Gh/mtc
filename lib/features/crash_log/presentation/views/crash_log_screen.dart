import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/services/crash/crash_log_service.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/config/theme/color_scheme.dart';

/// Crash Log Screen — shows the local crash log file content.
/// Accessible from the side drawer for drivers and support team.
class CrashLogScreen extends StatefulWidget {
  const CrashLogScreen({super.key});

  @override
  State<CrashLogScreen> createState() => _CrashLogScreenState();
}

class _CrashLogScreenState extends State<CrashLogScreen> {
  String _logContent = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    setState(() => _loading = true);
    final content = await CrashLogService.instance.read();
    setState(() {
      _logContent = content.isEmpty
          ? (Localizations.localeOf(context).languageCode == 'ar'
              ? '✅ لا توجد أخطاء مسجلة.'
              : '✅ No crash logs found.')
          : content;
      _loading = false;
    });
  }

  Future<void> _clearLog() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: AppText(
          isArabic ? 'مسح السجل' : 'Clear Log',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: AppText(
          isArabic
              ? 'هل أنت متأكد من حذف جميع سجلات الأخطاء؟'
              : 'Are you sure you want to delete all crash logs?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: AppText(isArabic ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: AppText(isArabic ? 'حذف' : 'Delete',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CrashLogService.instance.clear();
      await _loadLog();
    }
  }

  Future<void> _copyLog() async {
    await Clipboard.setData(ClipboardData(text: _logContent));
    if (mounted) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            isArabic ? 'تم نسخ السجل إلى الحافظة' : 'Log copied to clipboard',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareLog() async {
    final filePath = await CrashLogService.instance.filePath();
    if (filePath != null) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Crash Log — MTC App',
        text: 'Crash log from MTC Driver App',
      );
    } else {
      // Fallback: share as plain text
      await Share.share(
        _logContent,
        subject: 'Crash Log — MTC App',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasContent = _logContent.isNotEmpty && !_logContent.startsWith('✅');

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            AppText(
              isArabic ? 'سجل الأخطاء' : 'Crash Log',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh
          IconButton(
            tooltip: isArabic ? 'تحديث' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadLog,
          ),
          // Copy
          if (hasContent)
            IconButton(
              tooltip: isArabic ? 'نسخ' : 'Copy',
              icon: const Icon(Icons.copy_rounded, color: Colors.white70),
              onPressed: _copyLog,
            ),
          // Share
          if (hasContent)
            IconButton(
              tooltip: isArabic ? 'مشاركة' : 'Share',
              icon: const Icon(Icons.share_rounded, color: AppColors.primary),
              onPressed: _shareLog,
            ),
          // Clear
          if (hasContent)
            IconButton(
              tooltip: isArabic ? 'مسح' : 'Clear',
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              onPressed: _clearLog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : hasContent
              ? _LogView(content: _logContent)
              : _EmptyState(isArabic: isArabic),
    );
  }
}

// ── Log content view ──────────────────────────────────────────────────────────
class _LogView extends StatelessWidget {
  final String content;
  const _LogView({required this.content});

  @override
  Widget build(BuildContext context) {
    // Split entries by separator and reverse to show newest first
    final separator = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    final entries = content
        .split(separator)
        .where((e) => e.trim().isNotEmpty)
        .toList()
        .reversed
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index].trim();
        final isRecent = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isRecent
                ? Colors.redAccent.withValues(alpha: 0.08)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecent
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : Colors.white12,
              width: isRecent ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const AppText(
                      'Latest',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                SelectableText(
                  entry,
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isArabic;
  const _EmptyState({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Colors.greenAccent, size: 56),
          ),
          const SizedBox(height: 20),
          AppText(
            isArabic ? 'لا توجد أخطاء مسجلة' : 'No crash logs found',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 8),
          AppText(
            isArabic
                ? 'التطبيق يعمل بشكل سليم 🎉'
                : 'The app is running smoothly 🎉',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
