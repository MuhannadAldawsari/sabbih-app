

// ---------------- Theme Cubit for Dark Mode ----------------
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sabbh/core/storage/shared_prefs_helper.dart';

class ThemeCubit extends Cubit<bool> {
  ThemeCubit() : super(false) {
    _loadThemePreference();
  }

  void toggleTheme() {
    final newTheme = !state;
    emit(newTheme);
    _saveThemePreference(newTheme);
  }

  Future<void> _loadThemePreference() async {
    try {
      final isDarkMode = await SharedPrefsHelper().getBool('isDarkMode') ?? false;
      emit(isDarkMode);
    } catch (e) {
      emit(false); // Default to light mode
    }
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    try {
      await SharedPrefsHelper().setBool('isDarkMode', isDarkMode);
    } catch (e) {
      // Handle error silently
    }
  }
}