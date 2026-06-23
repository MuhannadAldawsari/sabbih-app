import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:sabbh/views/pages/prayer_calendar_page.dart';
import 'package:sabbh/core/utils/stiff_bouncing_scroll_physics.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PrayerTimesView();
  }
}

// ── Main View ─────────────────────────────────────────────────────

class _PrayerTimesView extends StatefulWidget {
  const _PrayerTimesView();

  @override
  State<_PrayerTimesView> createState() => _PrayerTimesViewState();
}

class _PrayerTimesViewState extends State<_PrayerTimesView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh countdown every second for HH:MM:SS display.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark    = settings.isDarkMode;
        final bg        = isDark ? ColorsManager.darkBg    : ColorsManager.lightBg;
        final accent    = isDark ? ColorsManager.darkAccent: ColorsManager.lightAccent;
        final accentDark= const Color(0xFF2C5F3A);
        final cardBg    = isDark ? ColorsManager.darkCard  : ColorsManager.lightCard;
        final textColor = isDark ? ColorsManager.darkTextPrimary   : ColorsManager.lightTextPrimary;
        final subColor  = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            extendBodyBehindAppBar: true,
            body: BlocConsumer<PrayerCubit, PrayerState>(
              listenWhen: (previous, current) {
                if (current is PrayerError) return true;
                if (current is! PrayerLoaded) return false;
                if (current.noticeMessage == null || current.noticeMessage!.isEmpty) {
                  return false;
                }
                final prevNoticeId = previous is PrayerLoaded ? previous.noticeId : -1;
                return current.noticeId != prevNoticeId;
              },
              listener: (context, state) {
                String? message;
                int? noticeId;
                if (state is PrayerError) {
                  message = state.message;
                } else if (state is PrayerLoaded && state.noticeMessage != null) {
                  message = state.noticeMessage;
                  noticeId = state.noticeId;
                }
                if (message != null && message.isNotEmpty) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
                    );
                  if (noticeId != null && noticeId > 0) {
                    context.read<PrayerCubit>().clearNotice(noticeId);
                  }
                }
              },
              builder: (context, state) {
                return CustomScrollView(
                  physics: const StiffBouncingScrollPhysics(),
                  slivers: [
                    // ── Header ─────────────────────────────
                    SliverToBoxAdapter(
                      child: _Header(
                        settings: settings,
                        isDark: isDark,
                        accent: accent,
                        accentDark: accentDark,
                        state: state,
                      ),
                    ),
                    // ── Location Controls ───────────────────
                    SliverToBoxAdapter(
                      child: _LocationControls(
                        settings: settings,
                        isDark: isDark,
                        accent: accent,
                        cardBg: cardBg,
                        textColor: textColor,
                        subColor: subColor,
                        state: state,
                        onGPSTap: () => context.read<PrayerCubit>().requestGPS(),
                        onOpenCalendar: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider.value(value: context.read<AppSettingsCubit>()),
                                BlocProvider.value(value: context.read<PrayerCubit>()),
                              ],
                              child: const PrayerCalendarPage(),
                            ),
                          ),
                        ),
                        onPrevDay: () => context.read<PrayerCubit>().goToPreviousDay(),
                        onNextDay: () => context.read<PrayerCubit>().goToNextDay(),
                      ),
                    ),

                    // ── Body ───────────────────────────────
                    if (state is PrayerLoading)
                      SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(color: accent),
                        ),
                      )
                    else if (state is PrayerError)
                      SliverToBoxAdapter(
                        child: _ErrorCard(
                          message: state.message,
                          accent: accent,
                          cardBg: cardBg,
                          settings: settings,
                          textColor: textColor,
                        ),
                      )
                    else if (state is PrayerLoaded) ...[
                      // Next prayer highlight
                      SliverToBoxAdapter(
                        child: _NextPrayerCard(
                          state: state,
                          settings: settings,
                          isDark: isDark,
                          accent: accent,
                          accentDark: accentDark,
                        ),
                      ),
                      // All 5 prayer times
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 160),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            _buildPrayerCards(
                              state, settings, isDark, accent, cardBg,
                              textColor, subColor,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      SliverFillRemaining(
                        child: _EmptyState(
                          settings: settings,
                          textColor: textColor,
                          subColor: subColor,
                          accent: accent,
                        ),
                      ),
                  ],
                );
        },
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPrayerCards(
    PrayerLoaded state,
    AppSettingsState settings,
    bool isDark,
    Color accent,
    Color cardBg,
    Color textColor,
    Color subColor,
  ) {
    final isToday = _isSameDay(state.selectedDate, DateTime.now());
    final display = _buildCountdownDisplay(state, DateTime.now());
    final highlightedPrayer =
        isToday ? (display.isIqama ? display.prayer : state.nextPrayer) : null;

    final prayers = [
      _PrayerEntry('الفجر',   Prayer.fajr,    Icons.brightness_3_rounded, state.times.fajr),
      _PrayerEntry('الشروق',  Prayer.sunrise, Icons.wb_twilight_rounded,  state.times.sunrise),
      _PrayerEntry(_dhuhrLabelForDate(state.selectedDate), Prayer.dhuhr, Icons.wb_sunny_rounded, state.times.dhuhr),
      _PrayerEntry('العصر',   Prayer.asr,     Icons.wb_cloudy_rounded,    state.times.asr),
      _PrayerEntry('المغرب',  Prayer.maghrib, Icons.nights_stay_rounded,  state.times.maghrib),
      _PrayerEntry('العشاء',  Prayer.isha,    Icons.dark_mode_rounded,    state.times.isha),
    ];

    return prayers.map((p) {
      final isNext = highlightedPrayer != null && highlightedPrayer == p.prayer;
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _PrayerCard(
          entry: p,
          isNext: isNext,
          settings: settings,
          isDark: isDark,
          accent: accent,
          cardBg: cardBg,
          textColor: textColor,
          subColor: subColor,
        ),
      );
    }).toList();
  }
}

// ── Header ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  final Color accent;
  final Color accentDark;
  final PrayerState state;
  const _Header({
    required this.settings, required this.isDark,
    required this.accent,   required this.accentDark,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final locationName = state is PrayerLoaded
        ? (state as PrayerLoaded).locationName
        : 'مواقيت الصلاة';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          top: -1000,
          left: 0,
          right: 0,
          bottom: 50,
          child: Container(color: accentDark),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentDark, accent],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft:  Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              Text('مواقيت الصلاة',
                  style: _font(settings, 22, ColorsManager.white, FontWeight.bold)),
              const SizedBox(height: 4),
              Text(locationName,
                  style: _font(settings, 14,
                      ColorsManager.white.withValues(alpha: 0.85), FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Location Controls ─────────────────────────────────────────────

class _LocationControls extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  final Color accent, cardBg, textColor, subColor;
  final PrayerState state;
  final VoidCallback onGPSTap;
  final VoidCallback onOpenCalendar;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;

  const _LocationControls({
    required this.settings,
    required this.isDark,
    required this.accent,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.state,
    required this.onGPSTap,
    required this.onOpenCalendar,
    required this.onPrevDay,
    required this.onNextDay,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDate = state is PrayerLoaded
        ? (state as PrayerLoaded).selectedDate
        : DateTime.now();
    final hijri = HijriCalendar.fromDate(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          // ── Date navigation (replaces manual location dropdown) ─
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: ColorsManager.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onPrevDay,
                    icon: Icon(Icons.chevron_left_rounded, color: accent, size: 26),
                    tooltip: 'اليوم السابق',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _weekdayName(selectedDate),
                          style: _font(settings, 16, textColor, FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${hijri.hDay} ${_hijriMonthAr(hijri.hMonth)}',
                          style: _font(settings, 13, accent, FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onNextDay,
                    icon: Icon(Icons.chevron_right_rounded, color: accent, size: 26),
                    tooltip: 'اليوم التالي',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Quick actions: settings shortcut, calendar, GPS ─
          Row(
            children: [
              _actionButton(
                icon: Icons.calendar_month_rounded,
                onTap: onOpenCalendar,
                tooltip: 'التقويم',
                label: 'التقويم',
                settings: settings,
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.my_location_rounded,
                onTap: onGPSTap,
                tooltip: 'تحديد الموقع بدقة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    String? label,
    AppSettingsState? settings,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: label != null ? 16 : 12, vertical: 12),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ColorsManager.white, size: 20),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: _font(settings!, 14, ColorsManager.white, FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayName(DateTime date) {
    const names = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return names[date.weekday - 1];
  }

}

// ── Next Prayer Card ──────────────────────────────────────────────

class _NextPrayerCard extends StatelessWidget {
  final PrayerLoaded state;
  final AppSettingsState settings;
  final bool isDark;
  final Color accent, accentDark;
  const _NextPrayerCard({
    required this.state,  required this.settings,
    required this.isDark, required this.accent,
    required this.accentDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final display = _buildCountdownDisplay(state, now);
    final name = _prayerName(display.prayer, state.selectedDate);

    final iqamaLightStart = const Color(0xFFC87D24);
    final iqamaLightEnd   = const Color(0xFFE79B3C);
    final iqamaDarkStart  = const Color(0xFF7D4D14);
    final iqamaDarkEnd    = const Color(0xFFB06E1C);

    final cardStart = (display.isIqama && display.showCountdown)
        ? (isDark ? iqamaDarkStart : iqamaLightStart)
        : accentDark;
    final cardEnd = (display.isIqama && display.showCountdown)
        ? (isDark ? iqamaDarkEnd : iqamaLightEnd)
        : accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardStart, cardEnd],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardEnd.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prayer name + icon (right side in RTL)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    !display.showCountdown
                        ? 'مواقيت يوم ${_weekdayName(now, state.selectedDate)}'
                        : (display.isIqama ? 'الصلاة الحالية' : 'الصلاة القادمة'),
                    style: _font(settings, 12,
                        ColorsManager.white.withValues(alpha: 0.80), FontWeight.normal)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(_prayerIcon(display.prayer),
                        color: ColorsManager.white, size: 22),
                    const SizedBox(width: 8),
                    Text(name,
                        style: _font(settings, 18, ColorsManager.white, FontWeight.bold)),
                  ],
                ),
              ],
            ),
            // Countdown (left side in RTL)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    !display.showCountdown
                        ? 'وقت الصلاة'
                        : (display.isIqama ? 'وقت الإقامة' : 'الوقت المتبقي'),
                    style: _font(settings, 12,
                        ColorsManager.white.withValues(alpha: 0.80), FontWeight.normal)),
                const SizedBox(height: 4),
                Text(display.text,
                    style: _font(settings, 18, ColorsManager.white, FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownDisplay {
  final Prayer prayer;
  final String text;
  final bool isIqama;
  final bool showCountdown;
  const _CountdownDisplay({
    required this.prayer,
    required this.text,
    required this.isIqama,
    required this.showCountdown,
  });
}

_CountdownDisplay _buildCountdownDisplay(PrayerLoaded state, DateTime now) {
  if (!_isSameDay(state.selectedDate, now)) {
    return _CountdownDisplay(
      prayer: state.nextPrayer,
      text: _formatTime(state.nextPrayerTime),
      isIqama: false,
      showCountdown: false,
    );
  }

  const iqamaWindow = Duration(minutes: 30);
  final schedule = <Prayer, DateTime>{
    Prayer.fajr: state.times.fajr,
    Prayer.sunrise: state.times.sunrise,
    Prayer.dhuhr: state.times.dhuhr,
    Prayer.asr: state.times.asr,
    Prayer.maghrib: state.times.maghrib,
    Prayer.isha: state.times.isha,
  };

  // 1) If we are within 30 minutes after any prayer start => Iqama mode.
  Prayer? currentPrayer;
  DateTime? currentStart;
  for (final entry in schedule.entries) {
    if (!entry.value.isAfter(now)) {
      if (currentStart == null || entry.value.isAfter(currentStart)) {
        currentStart = entry.value;
        currentPrayer = entry.key;
      }
    }
  }
  if (currentPrayer != null && currentStart != null) {
    final elapsed = now.difference(currentStart);
    if (elapsed >= Duration.zero && elapsed < iqamaWindow) {
      return _CountdownDisplay(
        prayer: currentPrayer,
        text: _formatMmSs(elapsed),
        isIqama: true,
        showCountdown: true,
      );
    }
  }

  // 2) Otherwise show next upcoming obligatory prayer countdown HH:MM:SS.
  Prayer nextPrayer = Prayer.fajr;
  DateTime nextTime = state.times.fajr.add(const Duration(days: 1));
  for (final entry in schedule.entries) {
    if (entry.value.isAfter(now)) {
      nextPrayer = entry.key;
      nextTime = entry.value;
      break;
    }
  }

  final remaining = nextTime.difference(now);
  if (remaining <= const Duration(seconds: 1)) {
    return _CountdownDisplay(
      prayer: nextPrayer,
      text: _formatMmSs(Duration.zero),
      isIqama: true,
      showCountdown: true,
    );
  }

  return _CountdownDisplay(
    prayer: nextPrayer,
    text: _formatHhMmSs(remaining),
    isIqama: false,
    showCountdown: true,
  );
}

// ── Individual Prayer Card ────────────────────────────────────────

class _PrayerEntry {
  final String name;
  final Prayer prayer;
  final IconData icon;
  final DateTime? time;
  const _PrayerEntry(this.name, this.prayer, this.icon, this.time);
}

class _PrayerCard extends StatelessWidget {
  final _PrayerEntry entry;
  final bool isNext;
  final AppSettingsState settings;
  final bool isDark;
  final Color accent, cardBg, textColor, subColor;

  const _PrayerCard({
    required this.entry,     required this.isNext,
    required this.settings,  required this.isDark,
    required this.accent,    required this.cardBg,
    required this.textColor, required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = entry.time != null
        ? _formatTime(entry.time!)
        : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: isNext ? accent.withValues(alpha: 0.10) : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isNext
            ? Border.all(color: accent.withValues(alpha: 0.40), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: ColorsManager.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon (first child in RTL => visual right)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isNext ? accent : accent).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(entry.icon,
                color: accent, size: 17),
          ),
          const SizedBox(width: 11),
          // Text (center)
          Expanded(
            child: Text(
              entry.name,
              textAlign: TextAlign.right,
              style: _font(
                settings,
                16,
                isNext ? accent : textColor,
                FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Time (last child in RTL => visual left)
          Text(
            timeStr,
            style: _font(
              settings,
              16,
              isNext ? accent : subColor,
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppSettingsState settings;
  final Color textColor, subColor, accent;
  const _EmptyState({
    required this.settings, required this.textColor,
    required this.subColor,  required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 64, color: accent.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            Text('اختر طريقة تحديد الموقع',
                style: _font(settings, 18, textColor, FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('استخدم زر GPS لتحديد موقعك تلقائياً، أو اختر مدينتك من القائمة في الاعدادات',
                style: _font(settings, 14, subColor, FontWeight.normal),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final Color accent, cardBg, textColor;
  final AppSettingsState settings;
  const _ErrorCard({
    required this.message, required this.accent,
    required this.cardBg,  required this.textColor,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: _font(settings, 14, textColor, FontWeight.normal)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'م' : 'ص';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

String _formatHhMmSs(Duration d) {
  final safe = d.isNegative ? Duration.zero : d;
  final h = safe.inHours;
  final m = safe.inMinutes.remainder(60);
  final s = safe.inSeconds.remainder(60);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _formatMmSs(Duration d) {
  final safe = d.isNegative ? Duration.zero : d;
  final m = safe.inMinutes.remainder(60);
  final s = safe.inSeconds.remainder(60);
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayName(DateTime now, DateTime selected) {
  const names = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  if (_isSameDay(now, selected)) return 'اليوم';
  return names[selected.weekday - 1];
}

String _prayerName(Prayer p, DateTime selectedDate) {
  switch (p) {
    case Prayer.fajr:    return 'الفجر';
    case Prayer.sunrise: return 'الشروق';
    case Prayer.dhuhr:   return _dhuhrLabelForDate(selectedDate);
    case Prayer.asr:     return 'العصر';
    case Prayer.maghrib: return 'المغرب';
    case Prayer.isha:    return 'العشاء';
    default:             return 'غير محدد';
  }
}

String _dhuhrLabelForDate(DateTime date) =>
    date.weekday == DateTime.friday ? 'الجمعة' : 'الظهر';

String _hijriMonthAr(int month) {
  const months = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  return months[month - 1];
}

IconData _prayerIcon(Prayer p) {
  switch (p) {
    case Prayer.fajr:    return Icons.brightness_3_rounded;
    case Prayer.sunrise: return Icons.wb_twilight_rounded;
    case Prayer.dhuhr:   return Icons.wb_sunny_rounded;
    case Prayer.asr:     return Icons.wb_cloudy_rounded;
    case Prayer.maghrib: return Icons.nights_stay_rounded;
    case Prayer.isha:    return Icons.dark_mode_rounded;
    default:             return Icons.access_time_rounded;
  }
}

TextStyle _font(AppSettingsState s, double size, Color color, FontWeight weight) {
  final adjusted = size + (s.baseFontSize - 16.0);
  switch (s.fontFamilyIndex) {
    case 1:  return TextStyle(fontFamily: 'Cairo', fontSize: adjusted, color: color, fontWeight: weight);
    case 2:  return TextStyle(fontFamily: 'Amiri', fontSize: adjusted, color: color, fontWeight: weight);
    default: return TextStyle(fontFamily: 'Tajawal', fontSize: adjusted, color: color, fontWeight: weight);
  }
}
