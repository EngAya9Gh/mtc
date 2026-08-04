import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerSettingsState {
  final bool beep;
  final bool vibrate;
  final bool flash;
  final bool autoResume;
  final double holdTime;
  final String cameraResolution;
  final String activeScanner;
  final Map<String, bool> symbologies;

  ScannerSettingsState({
    this.beep = true,
    this.vibrate = true,
    this.flash = false,
    this.autoResume = true,
    this.holdTime = 1.0,
    this.cameraResolution = 'HD',
    this.symbologies = const {
      'Code 128': true,
      'Code 39': false,
      'EAN-13': false,
      'EAN-8': false,
      'UPC-E': false,
      'QR Code': false,
    },
    this.activeScanner = 'MobileScanner',
  });

  ScannerSettingsState copyWith({
    bool? beep,
    bool? vibrate,
    bool? flash,
    bool? autoResume,
    double? holdTime,
    String? cameraResolution,
    Map<String, bool>? symbologies,
    String? activeScanner,
  }) {
    return ScannerSettingsState(
      beep: beep ?? this.beep,
      vibrate: vibrate ?? this.vibrate,
      flash: flash ?? this.flash,
      autoResume: autoResume ?? this.autoResume,
      holdTime: holdTime ?? this.holdTime,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      symbologies: symbologies ?? this.symbologies,
      activeScanner: activeScanner ?? this.activeScanner,
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
    final cameraResolution = _prefs.getString('scanner_camera_resolution') ?? 'HD';
    
    final Map<String, bool> symbologies = {
      'Code 128': _prefs.getBool('sym_code128') ?? true,
      'Code 39': _prefs.getBool('sym_code39') ?? false,
      'EAN-13': _prefs.getBool('sym_ean13') ?? false,
      'EAN-8': _prefs.getBool('sym_ean8') ?? false,
      'UPC-E': _prefs.getBool('sym_upce') ?? false,
      'QR Code': _prefs.getBool('sym_qrcode') ?? false,
    };
    
    final activeScanner = _prefs.getString('scanner_engine') ?? 'MobileScanner';

    emit(ScannerSettingsState(
      beep: beep,
      vibrate: vibrate,
      flash: flash,
      autoResume: autoResume,
      holdTime: holdTime,
      cameraResolution: cameraResolution,
      symbologies: symbologies,
      activeScanner: activeScanner,
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
    final updated = Map<String, bool>.from(state.symbologies);
    updated[key] = value;
    
    final prefKey = _getPrefKeyForSymbology(key);
    await _prefs.setBool(prefKey, value);
    emit(state.copyWith(symbologies: updated));
  }

  Future<void> setScannerEngine(String engine) async {
    await _prefs.setString('scanner_engine', engine);
    emit(state.copyWith(activeScanner: engine));
  }

  String _getPrefKeyForSymbology(String key) {
    switch (key) {
      case 'Code 128': return 'sym_code128';
      case 'Code 39': return 'sym_code39';
      case 'EAN-13': return 'sym_ean13';
      case 'EAN-8': return 'sym_ean8';
      case 'UPC-E': return 'sym_upce';
      case 'QR Code': return 'sym_qrcode';
      default: return '';
    }
  }

  Future<void> resetToDefaults() async {
    await _prefs.setBool('scanner_beep', true);
    await _prefs.setBool('scanner_vibrate', true);
    await _prefs.setBool('scanner_flash', false);
    await _prefs.setBool('scanner_auto_resume', true);
    await _prefs.setDouble('scanner_hold_time', 1.5);
    await _prefs.setString('scanner_camera_resolution', 'HD');
    await _prefs.setBool('sym_code128', true);
    await _prefs.setBool('sym_code39', false);
    await _prefs.setBool('sym_ean13', false);
    await _prefs.setBool('sym_ean8', false);
    await _prefs.setBool('sym_upce', false);
    await _prefs.setBool('sym_qrcode', false);
    
    _loadSettings();
  }
}
