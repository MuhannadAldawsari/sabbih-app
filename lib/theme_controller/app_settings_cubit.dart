import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sabbh/core/storage/shared_prefs_helper.dart';
import 'package:sabbh/features/iqama_notification/iqama_countdown_logic.dart';
import 'package:sabbh/features/iqama_notification/iqama_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kIqamaNotifEnabled = 'iqama_notif_enabled';
const _kIqamaNotifMode = 'iqama_notif_mode';
const _kLegacyIqamaNotifEnabled = 'iqamaNotifEnabled';
const _kLegacyIqamaNotifMode = 'iqamaNotifMode';

// ── App Settings State ──────────────────────────────────────────

class AppSettingsState {
  final bool isDarkMode;
  final int fontSizeLevel;    // 0–7  (maps to 13–27pt)
  final int fontFamilyIndex;  // 0=Tajawal, 1=Cairo, 2=Amiri
  final bool iqamaNotifEnabled;
  final IqamaNotifMode iqamaNotifMode;

  const AppSettingsState({
    required this.isDarkMode,
    required this.fontSizeLevel,
    required this.fontFamilyIndex,
    required this.iqamaNotifEnabled,
    required this.iqamaNotifMode,
  });

  AppSettingsState copyWith({
    bool? isDarkMode,
    int? fontSizeLevel,
    int? fontFamilyIndex,
    bool? iqamaNotifEnabled,
    IqamaNotifMode? iqamaNotifMode,
  }) {
    return AppSettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSizeLevel: fontSizeLevel ?? this.fontSizeLevel,
      fontFamilyIndex: fontFamilyIndex ?? this.fontFamilyIndex,
      iqamaNotifEnabled: iqamaNotifEnabled ?? this.iqamaNotifEnabled,
      iqamaNotifMode: iqamaNotifMode ?? this.iqamaNotifMode,
    );
  }

  /// Base font size from the 7-level scale
  double get baseFontSize {
    const sizes = [16.0, 17.5, 19.0, 20.0, 21.0, 22.0, 23.0];
    return sizes[fontSizeLevel.clamp(0, 6)];
  }

  /// Font family name string (used by GoogleFonts)
  static const List<String> fontFamilyNames = ['Tajawal', 'Cairo', 'Amiri'];

  String get fontFamilyName => fontFamilyNames[fontFamilyIndex.clamp(0, 2)];
}

// ── AppSettings Cubit ────────────────────────────────────────────

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(super.initialState) {
    // Initial state already loaded from SharedPreferences before runApp.
    // Only run migration to sync legacy keys — no emit needed.
    _runMigration();
  }

  /// Load saved settings synchronously before widget tree is built.
  /// Call this in main() and pass result to AppSettingsCubit constructor.
  static Future<AppSettingsState> loadInitial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark   = prefs.getBool('isDarkMode') ?? false;
      final fontSize = prefs.getInt('fontSizeLevel') ?? 2;
      final fontFam  = prefs.getInt('fontFamilyIndex') ?? 2;
      final iqamaEnabled = prefs.getBool('iqama_notif_enabled') ??
          prefs.getBool('iqamaNotifEnabled') ?? false;
      final iqamaIdx = prefs.getInt('iqama_notif_mode') ?? IqamaNotifMode.before45.index;
      final iqamaMode = IqamaNotifMode.values[
          iqamaIdx.clamp(0, IqamaNotifMode.values.length - 1)];
      return AppSettingsState(
        isDarkMode: isDark,
        fontSizeLevel: fontSize,
        fontFamilyIndex: fontFam,
        iqamaNotifEnabled: iqamaEnabled,
        iqamaNotifMode: iqamaMode,
      );
    } catch (_) {
      return const AppSettingsState(
        isDarkMode: false,
        fontSizeLevel: 2,
        fontFamilyIndex: 2,
        iqamaNotifEnabled: false,
        iqamaNotifMode: IqamaNotifMode.before45,
      );
    }
  }

  /// Only syncs legacy keys — does NOT emit a new state.
  Future<void> _runMigration() async {
    try {
      final prefs = SharedPrefsHelper();
      await IqamaNotificationService.ensureModePrefsMigrated();
      final iqamaEnabled = state.iqamaNotifEnabled;
      final iqamaMode    = state.iqamaNotifMode;
      await prefs.setBool(_kLegacyIqamaNotifEnabled, iqamaEnabled);
      await prefs.setInt(_kLegacyIqamaNotifMode, iqamaMode.index);
      await prefs.setBool(_kIqamaNotifEnabled, iqamaEnabled);
      await prefs.setInt(_kIqamaNotifMode, iqamaMode.index);
    } catch (_) {}
  }

  // ── Toggles & Setters ────────────────────────────────────────

  Future<void> toggleTheme() async {
    final newVal = !state.isDarkMode;
    emit(state.copyWith(isDarkMode: newVal));
    await SharedPrefsHelper().setBool('isDarkMode', newVal);
  }

  Future<void> setFontSizeLevel(int level) async {
    final clamped = level.clamp(0, 6);
    emit(state.copyWith(fontSizeLevel: clamped));
    await SharedPrefsHelper().setInt('fontSizeLevel', clamped);
  }

  Future<void> setFontFamilyIndex(int index) async {
    final clamped = index.clamp(0, 2);
    emit(state.copyWith(fontFamilyIndex: clamped));
    await SharedPrefsHelper().setInt('fontFamilyIndex', clamped);
  }

  Future<void> setIqamaNotifEnabled(bool enabled) async {
    emit(state.copyWith(iqamaNotifEnabled: enabled));
    final prefs = SharedPrefsHelper();
    await prefs.setBool(_kIqamaNotifEnabled, enabled);
    await prefs.setBool(_kLegacyIqamaNotifEnabled, enabled);
  }

  Future<void> setIqamaNotifMode(IqamaNotifMode mode) async {
    emit(state.copyWith(iqamaNotifMode: mode));
    final prefs = SharedPrefsHelper();
    await prefs.setInt(_kIqamaNotifMode, mode.index);
    await prefs.setInt(_kLegacyIqamaNotifMode, mode.index);
  }
}
