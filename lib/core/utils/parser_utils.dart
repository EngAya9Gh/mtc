class ParserUtils {
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Returns the name in the current language, or null when the API sent none,
  /// so callers can fall back to the untranslated field.
  static String? pickLocalized(bool isArabic, {String? arabic, String? english}) {
    final preferred = isArabic ? arabic : english;
    return (preferred != null && preferred.trim().isNotEmpty) ? preferred : null;
  }
}
