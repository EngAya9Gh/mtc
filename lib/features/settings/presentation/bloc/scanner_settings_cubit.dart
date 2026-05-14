import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerSettingsState {
  final bool beep;
  final bool vibrate;
  final bool flash;

  ScannerSettingsState({this.beep = true, this.vibrate = true, this.flash = false});

  ScannerSettingsState copyWith({bool? beep, bool? vibrate, bool? flash}) {
    return ScannerSettingsState(
      beep: beep ?? this.beep,
      vibrate: vibrate ?? this.vibrate,
      flash: flash ?? this.flash,
    );
  }
}

class ScannerSettingsCubit extends Cubit<ScannerSettingsState> {
  final SharedPreferences _prefs;

  ScannerSettingsCubit(this._prefs) : super(ScannerSettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final beep = _prefs.getBool('scanner_beep') ?? true;
    final vibrate = _prefs.getBool('scanner_vibrate') ?? true;
    final flash = _prefs.getBool('scanner_flash') ?? false;
    emit(ScannerSettingsState(beep: beep, vibrate: vibrate, flash: flash));
  }

  Future<void> toggleBeep(bool value) async {
    await _prefs.setBool('scanner_beep', value);
    emit(state.copyWith(beep: value));
  }

  Future<void> toggleVibrate(bool value) async {
    await _prefs.setBool('scanner_vibrate', value);
    emit(state.copyWith(vibrate: value));
  }

  Future<void> toggleFlash(bool value) async {
    await _prefs.setBool('scanner_flash', value);
    emit(state.copyWith(flash: value));
  }
}
