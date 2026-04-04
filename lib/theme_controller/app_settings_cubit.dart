import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sabbh/core/storage/shared_prefs_helper.dart';

// ── App Settings State ──────────────────────────────────────────

class AppSettingsState {
  final bool isDarkMode;
  final int fontSizeLevel;    // 0–7  (maps to 13–27pt)
  final int fontFamilyIndex;  // 0=Tajawal, 1=Cairo, 2=Amiri

  const AppSettingsState({
    required this.isDarkMode,
    required this.fontSizeLevel,
    required this.fontFamilyIndex,
  });

  AppSettingsState copyWith({
    bool? isDarkMode,
    int? fontSizeLevel,
    int? fontFamilyIndex,
  }) {
    return AppSettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSizeLevel: fontSizeLevel ?? this.fontSizeLevel,
      fontFamilyIndex: fontFamilyIndex ?? this.fontFamilyIndex,
    );
  }

  /// Base font size from the 7-level scale
  double get baseFontSize {
    const sizes = [13.0, 14.5, 16.0, 17.5, 19.0, 21.0, 23.0];
    return sizes[fontSizeLevel.clamp(0, 6)];
  }

  /// Font family name string (used by GoogleFonts)
  static const List<String> fontFamilyNames = ['Tajawal', 'Cairo', 'Amiri'];

  String get fontFamilyName => fontFamilyNames[fontFamilyIndex.clamp(0, 2)];
}

// ── AppSettings Cubit ────────────────────────────────────────────

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit()
      : super(const AppSettingsState(
          isDarkMode: false,
          fontSizeLevel: 2,        // default: 16pt
          fontFamilyIndex: 0,      // default: Tajawal
        )) {
    _loadSettings();
  }

  // ── Loaders ──────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    try {
      final prefs = SharedPrefsHelper();
      final isDark   = await prefs.getBool('isDarkMode') ?? false;
      final fontSize = await prefs.getInt('fontSizeLevel') ?? 2;
      final fontFam  = await prefs.getInt('fontFamilyIndex') ?? 0;
      emit(state.copyWith(
        isDarkMode: isDark,
        fontSizeLevel: fontSize,
        fontFamilyIndex: fontFam,
      ));
    } catch (_) {
      // keep defaults
    }
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
}
