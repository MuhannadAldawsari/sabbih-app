import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/iqama_notification/iqama_countdown_logic.dart';
import 'package:sabbh/features/iqama_notification/iqama_notification_service.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';

class IqamaNotificationPage extends StatefulWidget {
  const IqamaNotificationPage({super.key});

  @override
  State<IqamaNotificationPage> createState() => _IqamaNotificationPageState();
}

class _IqamaNotificationPageState extends State<IqamaNotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(IqamaNotificationService.instance.ensureAndroidNotificationPermission());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark = settings.isDarkMode;
        final bg = isDark ? ColorsManager.darkBg : ColorsManager.lightBg;
        final cardBg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;
        final accent = isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent;
        final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
        final subColor = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'إشعار وقت الإقامة',
                style: _font(settings, 20, textColor, FontWeight.bold),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _card(
                  cardBg: cardBg,
                  child: _toggleRow(
                    settings: settings,
                    accent: accent,
                    textColor: textColor,
                    subColor: subColor,
                    value: settings.iqamaNotifEnabled,
                    onChanged: (value) async {
                      final settingsCubit = context.read<AppSettingsCubit>();
                      final currentMode = settingsCubit.state.iqamaNotifMode;
                      if (value) {
                        await IqamaNotificationService.instance.ensureAndroidNotificationPermission();
                      }
                      await IqamaNotificationService.instance.applySettings(
                        enabled: value,
                        mode: currentMode,
                      );
                      await settingsCubit.setIqamaNotifEnabled(value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: !settings.iqamaNotifEnabled
                      ? const SizedBox.shrink()
                      : _card(
                          cardBg: cardBg,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Column(
                              children: IqamaNotifMode.values.map((mode) {
                                return RadioListTile<IqamaNotifMode>(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                  value: mode,
                                  groupValue: settings.iqamaNotifMode,
                                  activeColor: accent,
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    final settingsCubit = context.read<AppSettingsCubit>();
                                    final enabled = settingsCubit.state.iqamaNotifEnabled;
                                    if (enabled) {
                                      await IqamaNotificationService.instance.ensureAndroidNotificationPermission();
                                    }
                                    await IqamaNotificationService.instance.applySettings(
                                      enabled: enabled,
                                      mode: value,
                                    );
                                    await settingsCubit.setIqamaNotifMode(value);
                                  },
                                  title: Text(
                                    _modeLabel(mode),
                                    style: _font(settings, 14, textColor, FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  'يظهر الإشعار قبل الأذان ضمن النافذة التي تختارها (45 أو 30 أو 15 دقيقة)، ويُخفى تلقائياً بعد مرور 30 دقيقة على وقت الأذان.',
                  textAlign: TextAlign.right,
                  style: _font(settings, 12, subColor, FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card({required Color cardBg, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _toggleRow({
    required AppSettingsState settings,
    required Color accent,
    required Color textColor,
    required Color subColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.timer_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إشعار وقت الإقامة',
                  style: _font(settings, 15, textColor, FontWeight.w600),
                ),
                Text(
                  'عرض عدّاد الوقت المتبقي قبل الأذان في شريط الإشعارات',
                  style: _font(settings, 12, subColor, FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
          ),
        ],
      ),
    );
  }
}

String _modeLabel(IqamaNotifMode mode) {
  switch (mode) {
    case IqamaNotifMode.before45:
      return 'عرض الإشعار قبل الأذان بـ 45د';
    case IqamaNotifMode.before30:
      return 'عرض الإشعار قبل الأذان بـ 30د';
    case IqamaNotifMode.before15:
      return 'عرض الإشعار قبل الأذان بـ 15د';
  }
}

TextStyle _font(AppSettingsState s, double size, Color color, FontWeight weight) {
  switch (s.fontFamilyIndex) {
    case 1:
      return GoogleFonts.cairo(fontSize: size, color: color, fontWeight: weight);
    case 2:
      return GoogleFonts.amiri(fontSize: size, color: color, fontWeight: weight);
    default:
      return GoogleFonts.tajawal(fontSize: size, color: color, fontWeight: weight);
  }
}
