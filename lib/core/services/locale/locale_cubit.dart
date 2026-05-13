import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _langKey = 'app_language';
  final SharedPreferences _prefs;

  LocaleCubit(this._prefs) : super(_loadLocale(_prefs));

  static Locale _loadLocale(SharedPreferences prefs) {
    final saved = prefs.getString(_langKey);
    return Locale(saved ?? 'ar');
  }

  void toggleLanguage() {
    final newLang = state.languageCode == 'ar' ? 'en' : 'ar';
    _prefs.setString(_langKey, newLang);
    emit(Locale(newLang));
  }

  void setLanguage(String langCode) {
    _prefs.setString(_langKey, langCode);
    emit(Locale(langCode));
  }
}
