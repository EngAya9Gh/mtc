import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerSettingsState {
  final bool beep;
  final bool vibrate;
  final bool flash;
  final bool autoResume;
  final double holdTime;
  final String cameraResolution;
  final Map<String, bool> symbologies;

  ScannerSettingsState({
    this.beep = true,
    this.vibrate = true,
    this.flash = false,
    this.autoResume = true,
    this.holdTime = 1.0,
    this.cameraResolution = 'Full HD',
    this.symbologies = const {
      'Code 128': true,
      'Code 39': true,
      'EAN-13': true,
      'EAN-8': true,
      'UPC-E': true,
      'QR Code': true,
    },
  });

  ScannerSettingsState copyWith({
    bool? beep,
    bool? vibrate,
    bool? flash,
    bool? autoResume,
    double? holdTime,
    String? cameraResolution,
    Map<String, bool>? symbologies,
  }) {
    return ScannerSettingsState(
      beep: beep ?? this.beep,
      vibrate: vibrate ?? this.vibrate,
      flash: flash ?? this.flash,
      autoResume: autoResume ?? this.autoResume,
      holdTime: holdTime ?? this.holdTime,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      symbologies: symbologies ?? this.symbologies,
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
    final autoResume = _prefs.getBool('scanner_auto_resume') ?? true;
    final holdTime = _prefs.getDouble('scanner_hold_time') ?? 1.5;
    final cameraResolution = _prefs.getString('scanner_camera_resolution') ?? 'UHD';
    
    final Map<String, bool> symbologies = {
      'Code 128': _prefs.getBool('sym_code128') ?? true,
      'Code 39': _prefs.getBool('sym_code39') ?? true,
      'EAN-13': _prefs.getBool('sym_ean13') ?? true,
      'EAN-8': _prefs.getBool('sym_ean8') ?? true,
      'UPC-E': _prefs.getBool('sym_upce') ?? true,
      'QR Code': _prefs.getBool('sym_qrcode') ?? true,
    };

    emit(ScannerSettingsState(
      beep: beep,
      vibrate: vibrate,
      flash: flash,
      autoResume: autoResume,
      holdTime: holdTime,
      cameraResolution: cameraResolution,
      symbologies: symbologies,
    ));
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

  Future<void> toggleAutoResume(bool value) async {
    await _prefs.setBool('scanner_auto_resume', value);
    emit(state.copyWith(autoResume: value));
  }

  Future<void> setHoldTime(double value) async {
    await _prefs.setDouble('scanner_hold_time', value);
    emit(state.copyWith(holdTime: value));
  }

  Future<void> setCameraResolution(String value) async {
    await _prefs.setString('scanner_camera_resolution', value);
    emit(state.copyWith(cameraResolution: value));
  }

  Future<void> toggleSymbology(String key, bool value) async {
    final Map<String, bool> updatedSymbologies = Map.from(state.symbologies);
    updatedSymbologies[key] = value;
    
    String prefKey = '';
    switch (key) {
      case 'Code 128': prefKey = 'sym_code128'; break;
      case 'Code 39': prefKey = 'sym_code39'; break;
      case 'EAN-13': prefKey = 'sym_ean13'; break;
      case 'EAN-8': prefKey = 'sym_ean8'; break;
      case 'UPC-E': prefKey = 'sym_upce'; break;
      case 'QR Code': prefKey = 'sym_qrcode'; break;
    }
    if (prefKey.isNotEmpty) {
      await _prefs.setBool(prefKey, value);
    }
    
    emit(state.copyWith(symbologies: updatedSymbologies));
  }

  Future<void> resetToDefaults() async {
    await _prefs.setBool('scanner_beep', true);
    await _prefs.setBool('scanner_vibrate', true);
    await _prefs.setBool('scanner_flash', false);
    await _prefs.setBool('scanner_auto_resume', true);
    await _prefs.setDouble('scanner_hold_time', 1.5);
    await _prefs.setString('scanner_camera_resolution', 'UHD');
    await _prefs.setBool('sym_code128', true);
    await _prefs.setBool('sym_code39', true);
    await _prefs.setBool('sym_ean13', true);
    await _prefs.setBool('sym_ean8', true);
    await _prefs.setBool('sym_upce', true);
    await _prefs.setBool('sym_qrcode', true);
    
    _loadSettings();
  }
}
