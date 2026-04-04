import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark = settings.isDarkMode;
        final bg = isDark ? ColorsManager.darkBg : ColorsManager.lightBg;
        final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
        final subColor  = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 72,
                    color: isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'قريباً',
                    style: _font(settings, 28, textColor, FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'هذه الصفحة قيد التطوير',
                    style: _font(settings, 16, subColor, FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

TextStyle _font(AppSettingsState s, double size, Color color, FontWeight weight) {
  switch (s.fontFamilyIndex) {
    case 1:  return GoogleFonts.cairo(fontSize: size, color: color, fontWeight: weight);
    case 2:  return GoogleFonts.amiri(fontSize: size, color: color, fontWeight: weight);
    default: return GoogleFonts.tajawal(fontSize: size, color: color, fontWeight: weight);
  }
}
