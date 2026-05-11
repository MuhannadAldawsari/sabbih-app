import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/iqama_notification/iqama_notification_service.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationsEnabled = true;
  bool _morningEnabled = true;
  bool _eveningEnabled = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 5, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 16, minute: 0);

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
        final isDark    = settings.isDarkMode;
        final bg        = isDark ? ColorsManager.darkBg      : ColorsManager.lightBg;
        final cardBg    = isDark ? ColorsManager.darkCard    : ColorsManager.lightCard;
        final accent    = isDark ? ColorsManager.darkAccent  : ColorsManager.lightAccent;
        final textColor = isDark ? ColorsManager.darkTextPrimary   : ColorsManager.lightTextPrimary;
        final subColor  = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;
        final divider   = isDark ? ColorsManager.darkDivider : ColorsManager.lightDivider;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              centerTitle: true,
              title: Text('اعدادات التنبيهات', style: _font(settings, 20, textColor, FontWeight.bold)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
              // ── Master Toggle ─────────────────────────────────
              _sectionLabel('عام', settings, subColor),
              const SizedBox(height: 8),
              _card(
                cardBg: cardBg,
                child: _toggleRow(
                  icon: Icons.notifications_outlined,
                  accent: accent,
                  title: 'تفعيل الإشعارات',
                  subtitle: 'استقبل تذكيرات الأذكار اليومية',
                  value: _notificationsEnabled,
                  settings: settings,
                  textColor: textColor,
                  subColor: subColor,
                  onChanged: (v) async {
                    if (v) {
                      await IqamaNotificationService.instance.ensureAndroidNotificationPermission();
                    }
                    setState(() => _notificationsEnabled = v);
                  },
                ),
              ),
              if (_notificationsEnabled) ...[
                const SizedBox(height: 20),

                // ── Morning ────────────────────────────────────
                _sectionLabel('أذكار الصباح', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: Column(
                    children: [
                      _toggleRow(
                        icon: Icons.wb_sunny_outlined,
                        accent: accent,
                        title: 'تنبيه الصباح',
                        subtitle: 'ذكّرني بأذكار الصباح',
                        value: _morningEnabled,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                        onChanged: (v) => setState(() => _morningEnabled = v),
                      ),
                      if (_morningEnabled) ...[
                        Divider(color: divider, height: 1),
                        _timePicker(
                          label: 'وقت التنبيه',
                          time: _morningTime,
                          accent: accent,
                          settings: settings,
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () async {
                            final t = await _pickReminderTime(
                              context,
                              isMorning: true,
                              initial: _morningTime,
                              settings: settings,
                              textColor: textColor,
                              subColor: subColor,
                              accent: accent,
                            );
                            if (t != null) setState(() => _morningTime = t);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Evening ────────────────────────────────────
                _sectionLabel('أذكار المساء', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: Column(
                    children: [
                      _toggleRow(
                        icon: Icons.nights_stay_outlined,
                        accent: accent,
                        title: 'تنبيه المساء',
                        subtitle: 'ذكّرني بأذكار المساء',
                        value: _eveningEnabled,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                        onChanged: (v) => setState(() => _eveningEnabled = v),
                      ),
                      if (_eveningEnabled) ...[
                        Divider(color: divider, height: 1),
                        _timePicker(
                          label: 'وقت التنبيه',
                          time: _eveningTime,
                          accent: accent,
                          settings: settings,
                          textColor: textColor,
                          subColor: subColor,
                          onTap: () async {
                            final t = await _pickReminderTime(
                              context,
                              isMorning: false,
                              initial: _eveningTime,
                              settings: settings,
                              textColor: textColor,
                              subColor: subColor,
                              accent: accent,
                            );
                            if (t != null) setState(() => _eveningTime = t);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// أوقات المرجع تُؤخذ من [PrayerLoaded] لنفس **يوم التقويم المعروض** في صفحة المواقيت.
  /// إن كان ذلك اليوم ليس «اليوم» الحالي لا نعرض أرقاماً لتجنب الالتباس.
  Future<TimeOfDay?> _pickReminderTime(
    BuildContext context, {
    required bool isMorning,
    required TimeOfDay initial,
    required AppSettingsState settings,
    required Color textColor,
    required Color subColor,
    required Color accent,
  }) async {
    final guidance = isMorning
        ? 'وقت قراءة أذكار الصباح يبدأ بعد أذان الفجر .'
        : 'وقت قراءة أذكار المساء يبدأ بعد صلاة العصر .';

    final prayerState = context.read<PrayerCubit>().state;
    late final String anchorLine;
    if (prayerState is PrayerLoaded) {
      final now = DateTime.now();
      final sameAsToday = _isSameCalendarDay(prayerState.selectedDate, now);
      final loc = MaterialLocalizations.of(context);
      if (sameAsToday) {
        final anchor = isMorning
            ? prayerState.times.fajr
            : prayerState.times.asr.add(const Duration(minutes: 20));
        final tod = TimeOfDay.fromDateTime(anchor);
        anchorLine = 'وقت مرجعي مُقترح لهذا اليوم: ${loc.formatTimeOfDay(tod)}';
      } else {
        anchorLine =
            'المواقيت في التطبيق تعرض يوماً آخر؛ افتح صفحة المواقيت واختر اليوم الحالي لعرض وقت مرجعي محسوب هنا.';
      }
    } else {
      anchorLine =
          'فعّل الموقع أو اختر المدينة من صفحة المواقيت لعرض وقت مرجعي من مواقيت الصلاة.';
    }

    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (dialogContext, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context),
            child: MediaQuery(
              data: MediaQuery.of(dialogContext),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            guidance,
                            textAlign: TextAlign.right,
                            style: _font(settings, 13, subColor, FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      anchorLine,
                                      textAlign: TextAlign.right,
                                      style: _font(settings, 13, textColor, FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (child != null) child,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Widget _sectionLabel(String text, AppSettingsState s, Color color) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: _font(s, 13, color, FontWeight.w600),
      ),
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
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required bool value,
    required AppSettingsState settings,
    required Color textColor,
    required Color subColor,
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
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _font(settings, 15, textColor, FontWeight.w600),
                ),
                Text(
                  subtitle,
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

  Widget _timePicker({
    required String label,
    required TimeOfDay time,
    required Color accent,
    required AppSettingsState settings,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _font(settings, 14, textColor, FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: _font(settings, 15, accent, FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
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
