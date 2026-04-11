import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/iqama_notification/iqama_notification_service.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:sabbh/views/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
  unawaited(_bootstrapBackgroundServices());
}

Future<void> _bootstrapBackgroundServices() async {
  try {
    await AndroidAlarmManager.initialize();
    await IqamaNotificationService.instance.init();
    await IqamaNotificationService.instance.ensureAndroidNotificationPermission();
    await IqamaNotificationService.instance.restoreFromPrefsAndStartIfNeeded();
  } catch (_) {
    // Never block app startup for notification services.
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppSettingsCubit()),
        BlocProvider(create: (_) => PrayerCubit()),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          final isDark = settings.isDarkMode;
          unawaited(IqamaNotificationService.instance.updateThemeMode(isDark));

          // Build TextTheme from selected font & size
          final baseSize = settings.baseFontSize;
          TextTheme buildTextTheme(Color bodyColor, Color displayColor) {
            TextStyle base(double size, FontWeight w, Color c) {
              switch (settings.fontFamilyIndex) {
                case 1:  return GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c);
                case 2:  return GoogleFonts.amiri(fontSize: size, fontWeight: w, color: c);
                default: return GoogleFonts.tajawal(fontSize: size, fontWeight: w, color: c);
              }
            }
            return TextTheme(
              displayLarge:  base(baseSize + 18, FontWeight.bold,   displayColor),
              displayMedium: base(baseSize + 12, FontWeight.bold,   displayColor),
              displaySmall:  base(baseSize + 8,  FontWeight.bold,   displayColor),
              headlineLarge: base(baseSize + 6,  FontWeight.bold,   displayColor),
              headlineMedium:base(baseSize + 4,  FontWeight.w600,   displayColor),
              headlineSmall: base(baseSize + 2,  FontWeight.w600,   displayColor),
              titleLarge:    base(baseSize + 2,  FontWeight.w600,   displayColor),
              titleMedium:   base(baseSize,      FontWeight.w600,   displayColor),
              titleSmall:    base(baseSize - 1,  FontWeight.w500,   displayColor),
              bodyLarge:     base(baseSize,      FontWeight.normal, bodyColor),
              bodyMedium:    base(baseSize - 1,  FontWeight.normal, bodyColor),
              bodySmall:     base(baseSize - 2,  FontWeight.normal, bodyColor),
              labelLarge:    base(baseSize - 1,  FontWeight.w600,   bodyColor),
              labelMedium:   base(baseSize - 2,  FontWeight.w500,   bodyColor),
              labelSmall:    base(baseSize - 3,  FontWeight.w500,   bodyColor),
            );
          }

          // ── Light Theme ─────────────────────────────────────
          final lightTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary:   ColorsManager.lightAccent,
              secondary: ColorsManager.lightAccent,
              surface:   ColorsManager.lightCard,
              error:     ColorsManager.errorRed,
            ),
            scaffoldBackgroundColor: ColorsManager.lightBg,
            cardColor: ColorsManager.lightCard,
            dividerColor: ColorsManager.lightDivider,
            textTheme: buildTextTheme(
              ColorsManager.lightTextPrimary,
              ColorsManager.lightTextPrimary,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: ColorsManager.lightBg,
              elevation: 0,
              iconTheme: IconThemeData(color: ColorsManager.lightTextPrimary),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? ColorsManager.lightAccent : null,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? ColorsManager.lightAccent.withValues(alpha: 0.4) : null,
              ),
            ),
          );

          // ── Dark Theme ──────────────────────────────────────
          final darkTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary:   ColorsManager.darkAccent,
              secondary: ColorsManager.darkAccent,
              surface:   ColorsManager.darkCard,
              error:     ColorsManager.errorRed,
            ),
            scaffoldBackgroundColor: ColorsManager.darkBg,
            cardColor: ColorsManager.darkCard,
            dividerColor: ColorsManager.darkDivider,
            textTheme: buildTextTheme(
              ColorsManager.darkTextPrimary,
              ColorsManager.darkTextPrimary,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: ColorsManager.darkBg,
              elevation: 0,
              iconTheme: IconThemeData(color: ColorsManager.darkTextPrimary),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? ColorsManager.darkAccent : null,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? ColorsManager.darkAccent.withValues(alpha: 0.4) : null,
              ),
            ),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'سبّح',
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [Locale('ar', 'SA')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: const MainScaffold(),
          );
        },
      ),
    );
  }
}