import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:table_calendar/table_calendar.dart';

enum _CalendarMode { gregorian, hijri }

class PrayerCalendarPage extends StatefulWidget {
  const PrayerCalendarPage({super.key});

  @override
  State<PrayerCalendarPage> createState() => _PrayerCalendarPageState();
}

class _PrayerCalendarPageState extends State<PrayerCalendarPage> {
  DateTime _selectedDate = _strip(DateTime.now());
  DateTime _focusedDay = _strip(DateTime.now());
  _CalendarMode _mode = _CalendarMode.hijri;

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
            body: SafeArea(
              child: BlocBuilder<PrayerCubit, PrayerState>(
                builder: (context, state) {
                  if (state is! PrayerLoaded) {
                    return Center(
                      child: Text(
                        'يرجى تحديد الموقع أولاً',
                        style: _font(settings, 15, textColor, FontWeight.w600),
                      ),
                    );
                  }

                  final times = _calculateTimesForDate(state, _selectedDate);
                  final bottomDate = _mode == _CalendarMode.gregorian
                      ? _formatGregorianFullAr(_selectedDate)
                      : _formatHijriFullAr(_selectedDate);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: textColor,
                            ),
                            const Spacer(),
                            _buildModeToggle(settings, textColor, accent),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                          child: Column(
                            children: [
                              TableCalendar(
                                locale: 'ar',
                                firstDay: DateTime(2020, 1, 1),
                                lastDay: DateTime(2100, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) => _isSameDay(day, _selectedDate),
                                availableGestures: AvailableGestures.horizontalSwipe,
                                headerStyle: HeaderStyle(
                                  titleCentered: true,
                                  formatButtonVisible: false,
                                  leftChevronIcon: Icon(Icons.chevron_left_rounded, color: textColor),
                                  rightChevronIcon: Icon(Icons.chevron_right_rounded, color: textColor),
                                  titleTextStyle: _font(settings, 17, textColor, FontWeight.bold),
                                  titleTextFormatter: (date, _) {
                                    if (_mode == _CalendarMode.hijri) {
                                      final h = HijriCalendar.fromDate(date);
                                      return '${_hijriMonthAr(h.hMonth)} ${h.hYear}';
                                    }
                                    return '${_gregorianMonthAr(date.month)} ${date.year}';
                                  },
                                ),
                                calendarStyle: CalendarStyle(
                                  defaultTextStyle: _font(settings, 14, textColor, FontWeight.w600),
                                  weekendTextStyle: _font(settings, 14, textColor, FontWeight.w600),
                                  outsideTextStyle: _font(
                                    settings,
                                    13,
                                    subColor.withValues(alpha: 0.45),
                                    FontWeight.normal,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle: _font(settings, 13, accent, FontWeight.bold),
                                  weekendStyle: _font(settings, 13, accent, FontWeight.bold),
                                ),
                                calendarBuilders: _mode == _CalendarMode.hijri
                                    ? CalendarBuilders(
                                        selectedBuilder: (context, day, focusedDay) => _hijriDayCell(
                                          settings,
                                          day,
                                          ColorsManager.white,
                                          isSelected: true,
                                          isToday: _isSameDay(day, DateTime.now()),
                                          accent: accent,
                                        ),
                                        todayBuilder: (context, day, focusedDay) => _hijriDayCell(
                                          settings,
                                          day,
                                          textColor,
                                          isSelected: _isSameDay(day, _selectedDate),
                                          isToday: true,
                                          accent: accent,
                                        ),
                                        defaultBuilder: (context, day, focusedDay) => _hijriDayCell(
                                          settings,
                                          day,
                                          textColor,
                                          isSelected: _isSameDay(day, _selectedDate),
                                          isToday: _isSameDay(day, DateTime.now()),
                                          accent: accent,
                                        ),
                                        outsideBuilder: (context, day, focusedDay) => _hijriDayCell(
                                          settings,
                                          day,
                                          subColor.withValues(alpha: 0.45),
                                          isSelected: _isSameDay(day, _selectedDate),
                                          isToday: _isSameDay(day, DateTime.now()),
                                          accent: accent,
                                        ),
                                      )
                                    : const CalendarBuilders(),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDate = _strip(selectedDay);
                                    _focusedDay = _strip(focusedDay);
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  _focusedDay = _strip(focusedDay);
                                },
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      bottomDate,
                                      style: _font(settings, 14, subColor, FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    _timeRow(settings, textColor, subColor, 'الفجر', times.fajr),
                                    _timeRow(settings, textColor, subColor, 'الشروق', times.sunrise),
                                    _timeRow(
                                      settings,
                                      textColor,
                                      subColor,
                                      _selectedDate.weekday == DateTime.friday ? 'الجمعة' : 'الظهر',
                                      times.dhuhr,
                                    ),
                                    _timeRow(settings, textColor, subColor, 'العصر', times.asr),
                                    _timeRow(settings, textColor, subColor, 'المغرب', times.maghrib),
                                    _timeRow(settings, textColor, subColor, 'العشاء', times.isha),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeToggle(
    AppSettingsState settings,
    Color textColor,
    Color accent,
  ) {
    Widget modeButton({
      required String label,
      required bool isActive,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: _font(
                settings,
                12,
                isActive ? ColorsManager.white : textColor,
                FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 120,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          modeButton(
            label: 'هجري',
            isActive: _mode == _CalendarMode.hijri,
            onTap: () => setState(() => _mode = _CalendarMode.hijri),
          ),
          modeButton(
            label: 'ميلادي',
            isActive: _mode == _CalendarMode.gregorian,
            onTap: () => setState(() => _mode = _CalendarMode.gregorian),
          ),
        ],
      ),
    );
  }

  Widget _hijriDayCell(
    AppSettingsState settings,
    DateTime day,
    Color textColor, {
    required bool isSelected,
    required bool isToday,
    required Color accent,
  }) {
    final hijri = HijriCalendar.fromDate(day);
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected ? accent : (isToday ? accent.withValues(alpha: 0.35) : Colors.transparent),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${hijri.hDay}',
        style: _font(
          settings,
          13,
          isSelected ? ColorsManager.white : textColor,
          FontWeight.w600,
        ),
      ),
    );
  }

  Widget _timeRow(
    AppSettingsState settings,
    Color textColor,
    Color subColor,
    String name,
    DateTime time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(_formatTime(time), style: _font(settings, 16, textColor, FontWeight.bold)),
          const Spacer(),
          Text(name, style: _font(settings, 16, subColor, FontWeight.w600)),
        ],
      ),
    );
  }

  PrayerTimes _calculateTimesForDate(PrayerLoaded state, DateTime date) {
    final coords = Coordinates(state.lat, state.lng);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.adjustments = PrayerAdjustments(
      fajr: state.adjustments['fajr'] ?? 0,
      dhuhr: state.adjustments['dhuhr'] ?? 0,
      asr: state.adjustments['asr'] ?? 0,
      maghrib: state.adjustments['maghrib'] ?? 0,
      isha: state.adjustments['isha'] ?? 0,
    );
    return PrayerTimes(coords, DateComponents.from(date), params);
  }
}

DateTime _strip(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatHijriFullAr(DateTime dt) {
  const weekDays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  final h = HijriCalendar.fromDate(dt);
  return '${weekDays[dt.weekday - 1]}، ${h.hDay} ${_hijriMonthAr(h.hMonth)} ${h.hYear}';
}

String _formatGregorianFullAr(DateTime dt) {
  const weekDays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  return '${weekDays[dt.weekday - 1]}، ${dt.day} ${_gregorianMonthAr(dt.month)} ${dt.year}';
}

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

String _gregorianMonthAr(int month) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return months[month - 1];
}

String _formatTime(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'م' : 'ص';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

TextStyle _font(AppSettingsState s, double size, Color color, FontWeight weight) {
  final adjusted = size + (s.baseFontSize - 16.0);
  switch (s.fontFamilyIndex) {
    case 1:
      return GoogleFonts.cairo(fontSize: adjusted, color: color, fontWeight: weight);
    case 2:
      return GoogleFonts.amiri(fontSize: adjusted, color: color, fontWeight: weight);
    default:
      return GoogleFonts.tajawal(fontSize: adjusted, color: color, fontWeight: weight);
  }
}
