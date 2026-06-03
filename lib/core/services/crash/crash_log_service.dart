import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Global crash log service.
/// Writes structured crash entries to a local file and exposes
/// read/clear helpers for the CrashLogScreen.
class CrashLogService {
  static const _fileName = 'crash_log.txt';
  static const _maxEntries = 200; // keep last 200 errors

  static CrashLogService? _instance;
  static CrashLogService get instance => _instance ??= CrashLogService._();
  CrashLogService._();

  // ── File access ───────────────────────────────────────────────────────────

  Future<File> _logFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> log(dynamic error, StackTrace? stack, {String? context}) async {
    try {
      final file = await _logFile();
      final now = DateTime.now();
      final entry = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🕐 ${now.toIso8601String()}
${context != null ? '📍 Context: $context\n' : ''}💥 Error: $error
📋 StackTrace:
$stack
''';

      // Append (create if not exists)
      await file.writeAsString(entry, mode: FileMode.append);

      // Prune to keep file manageable
      await _pruneIfNeeded(file);
    } catch (e) {
      debugPrint('[CrashLog] Failed to write: $e');
    }
  }

  Future<void> _pruneIfNeeded(File file) async {
    try {
      final content = await file.readAsString();
      final entries = content.split('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (entries.length > _maxEntries) {
        final trimmed = entries.skip(entries.length - _maxEntries).join(
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        await file.writeAsString(trimmed);
      }
    } catch (_) {}
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<String> read() async {
    try {
      final file = await _logFile();
      if (!await file.exists()) return '';
      return await file.readAsString();
    } catch (e) {
      return 'Error reading log: $e';
    }
  }

  Future<bool> hasLogs() async {
    try {
      final file = await _logFile();
      return file.existsSync() && await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clear() async {
    try {
      final file = await _logFile();
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[CrashLog] Failed to clear: $e');
    }
  }

  // ── File path (for Share) ─────────────────────────────────────────────────

  Future<String?> filePath() async {
    try {
      final file = await _logFile();
      return file.existsSync() ? file.path : null;
    } catch (_) {
      return null;
    }
  }
}
