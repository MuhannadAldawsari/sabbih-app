import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/core/storage/shared_prefs_helper.dart';
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
  bool _morningSound = true;
  bool _eveningSound = true;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(IqamaNotificationService.instance.ensureAndroidNotificationPermission());
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = SharedPrefsHelper();
    final notificationsEnabled = await prefs.getBool('adhkar_notif_enabled') ?? false;
    final morningEnabled = await prefs.getBool('morning_adhkar_enabled') ?? true;
    final eveningEnabled = await prefs.getBool('evening_adhkar_enabled') ?? true;
    final morningSound = await prefs.getBool('morning_adhkar_sound') ?? true;
    final eveningSound = await prefs.getBool('evening_adhkar_sound') ?? true;
    
    final mHour = await prefs.getInt('morning_adhkar_hour') ?? 5;
    final mMin = await prefs.getInt('morning_adhkar_minute') ?? 0;
    final eHour = await prefs.getInt('evening_adhkar_hour') ?? 16;
    final eMin = await prefs.getInt('evening_adhkar_minute') ?? 0;

    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _morningEnabled = morningEnabled;
      _eveningEnabled = eveningEnabled;
      _morningSound = morningSound;
      _eveningSound = eveningSound;
      _morningTime = TimeOfDay(hour: mHour, minute: mMin);
      _eveningTime = TimeOfDay(hour: eHour, minute: eMin);
    });
  }

  Future<void> _saveSettings() async {
    await IqamaNotificationService.instance.updateAdhkarSettings(
      morningEnabled: _morningEnabled,
      morningSound: _morningSound,
      morningTime: _morningTime,
      eveningEnabled: _eveningEnabled,
      eveningSound: _eveningSound,
      eveningTime: _eveningTime,
    );
  }

  void _playSoundPreview(bool isMorning) async {
    try {
      await _audioPlayer.stop();
      final resourceName = isMorning ? 'morning.mp3' : 'evening.mp3';
      await _audioPlayer.play(AssetSource('sounds/$resourceName'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تشغيل المعاينة. تأكد من إعادة تشغيل التطبيق بالكامل (Restart).')),
        );
      }
    }
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
            body: ColoredBox(
              color: bg,
              child: ListView(
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
                    await SharedPrefsHelper().setBool('adhkar_notif_enabled', v);
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
                        onChanged: (v) {
                          setState(() => _morningEnabled = v);
                          _saveSettings();
                        },
                      ),
                      if (_morningEnabled) ...[
                        Divider(color: divider, height: 1),
                        _soundSelectionRow(
                          isMorning: true,
                          value: _morningSound,
                          settings: settings,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          onChanged: (v) {
                            setState(() => _morningSound = v);
                            _saveSettings();
                          },
                        ),
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
                            if (t != null) {
                              setState(() => _morningTime = t);
                              _saveSettings();
                            }
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
                        onChanged: (v) {
                          setState(() => _eveningEnabled = v);
                          _saveSettings();
                        },
                      ),
                      if (_eveningEnabled) ...[
                        Divider(color: divider, height: 1),
                        _soundSelectionRow(
                          isMorning: false,
                          value: _eveningSound,
                          settings: settings,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                          onChanged: (v) {
                            setState(() => _eveningSound = v);
                            _saveSettings();
                          },
                        ),
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
                            if (t != null) {
                              setState(() => _eveningTime = t);
                              _saveSettings();
                            }
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
          ),
        );
      },
    );
  }


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
        ? 'يبدأ وقت أذكار الصباح بعد أذان الفجر، ويُستحب قراءتها في هذا الوقت.'
        : 'يبدأ وقت أذكار المساء بعد صلاة العصر، ويُستحب قراءتها في هذا الوقت.';

    final prayerState = context.read<PrayerCubit>().state;
    late final String anchorLine;
    bool hasAnchor = false;

    if (prayerState is PrayerLoaded) {
      final loc = MaterialLocalizations.of(context);
      final anchor = isMorning
          ? prayerState.times.fajr
          : prayerState.times.asr.add(const Duration(minutes: 20));
      final tod = TimeOfDay.fromDateTime(anchor);
      anchorLine = 'وقت البداية المُقترح: ${loc.formatTimeOfDay(tod)}';
      hasAnchor = true;
    } else {
      anchorLine =
          'تفعيل الموقع يتيح لك عرض الوقت المقترح بناءً على مواقيت الصلاة.';
    }

    return showTimePicker(
      context: context,
      initialTime: initial,
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
      helpText: isMorning ? 'تنبيه أذكار الصباح' : 'تنبيه أذكار المساء',
      builder: (dialogContext, child) {
        final isDark = settings.isDarkMode;
        final cardColor = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline, color: accent, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      guidance,
                                      textAlign: TextAlign.right,
                                      style: _font(settings, 13, textColor, FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    if (hasAnchor) ...[
                                      Icon(Icons.access_time_filled, color: accent, size: 18),
                                    ] else ...[
                                      Icon(Icons.info_outline, color: accent, size: 18),
                                    ],
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        anchorLine,
                                        textAlign: TextAlign.right,
                                        style: _font(settings, 13, textColor, FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _soundSelectionRow({
    required bool isMorning,
    required bool value,
    required AppSettingsState settings,
    required Color textColor,
    required Color subColor,
    required Color accent,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: value ? accent.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: value ? accent : subColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.volume_up_rounded, size: 20, color: value ? accent : subColor),
                        const SizedBox(width: 6),
                        Text('تنبيه بصوت', style: _font(settings, 12, value ? accent : subColor, FontWeight.w600)),
                        if (value) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _playSoundPreview(isMorning),
                            child: Icon(Icons.play_circle_fill, size: 20, color: accent),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: !value ? accent.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !value ? accent : subColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, size: 20, color: !value ? accent : subColor),
                        const SizedBox(width: 6),
                        Text('إشعار فقط', style: _font(settings, 12, !value ? accent : subColor, FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    case 1:  return TextStyle(fontFamily: 'Cairo', fontSize: size, color: color, fontWeight: weight);
    case 2:  return TextStyle(fontFamily: 'Amiri', fontSize: size, color: color, fontWeight: weight);
    default: return TextStyle(fontFamily: 'Tajawal', fontSize: size, color: color, fontWeight: weight);
  }
}
