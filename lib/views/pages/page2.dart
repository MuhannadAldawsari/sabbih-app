import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/data/cities_data.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrayerCubit(),
      child: const _PrayerTimesView(),
    );
  }
}

// ── Main View ─────────────────────────────────────────────────────

class _PrayerTimesView extends StatefulWidget {
  const _PrayerTimesView();

  @override
  State<_PrayerTimesView> createState() => _PrayerTimesViewState();
}

class _PrayerTimesViewState extends State<_PrayerTimesView> {
  List<CityEntry> _cities = [];
  CityEntry? _selectedCity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCities();
    // Refresh countdown every minute
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final cities = await CitiesRepository.load();
    if (mounted) setState(() => _cities = cities);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark    = settings.isDarkMode;
        final bg        = isDark ? ColorsManager.darkBg    : ColorsManager.lightBg;
        final accent    = isDark ? ColorsManager.darkAccent: ColorsManager.lightAccent;
        final accentDark= isDark ? const Color(0xFF0D2E15) : const Color(0xFF2C5F3A);
        final cardBg    = isDark ? ColorsManager.darkCard  : ColorsManager.lightCard;
        final textColor = isDark ? ColorsManager.darkTextPrimary   : ColorsManager.lightTextPrimary;
        final subColor  = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            body: BlocBuilder<PrayerCubit, PrayerState>(
              builder: (context, state) {
                return CustomScrollView(
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
                        cities: _cities,
                        selectedCity: _selectedCity,
                        onCitySelected: (city) {
                          setState(() => _selectedCity = city);
                          context.read<PrayerCubit>().selectCity(city);
                        },
                        onGPSTap: () => context.read<PrayerCubit>().requestGPS(),
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
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
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
    final prayers = [
      _PrayerEntry('الفجر',   Prayer.fajr,    Icons.brightness_3_rounded, state.times.fajr),
      _PrayerEntry('الشروق',  Prayer.sunrise, Icons.wb_twilight_rounded,  state.times.sunrise),
      _PrayerEntry('الظهر',   Prayer.dhuhr,   Icons.wb_sunny_rounded,     state.times.dhuhr),
      _PrayerEntry('العصر',   Prayer.asr,     Icons.wb_cloudy_rounded,    state.times.asr),
      _PrayerEntry('المغرب',  Prayer.maghrib, Icons.nights_stay_rounded,  state.times.maghrib),
      _PrayerEntry('العشاء',  Prayer.isha,    Icons.dark_mode_rounded,    state.times.isha),
    ];

    return prayers.map((p) {
      final isNext = state.nextPrayer == p.prayer;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 28),
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
              style: _font(settings, 28, ColorsManager.white, FontWeight.bold)),
          const SizedBox(height: 6),
          Text(locationName,
              style: _font(settings, 14,
                  ColorsManager.white.withValues(alpha: 0.85), FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Location Controls ─────────────────────────────────────────────

class _LocationControls extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  final Color accent, cardBg, textColor, subColor;
  final List<CityEntry> cities;
  final CityEntry? selectedCity;
  final ValueChanged<CityEntry> onCitySelected;
  final VoidCallback onGPSTap;

  const _LocationControls({
    required this.settings,   required this.isDark,
    required this.accent,     required this.cardBg,
    required this.textColor,  required this.subColor,
    required this.cities,     required this.selectedCity,
    required this.onCitySelected, required this.onGPSTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          // ── City Dropdown ────────────────────────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CityEntry>(
                  value: selectedCity,
                  hint: Text('اختر مدينة',
                      style: _font(settings, 13, subColor, FontWeight.normal)),
                  isExpanded: true,
                  dropdownColor: cardBg,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
                  items: cities.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayName,
                        style: _font(settings, 13, textColor, FontWeight.normal),
                        overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (c) { if (c != null) onCitySelected(c); },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── GPS Button ──────────────────────────────────
          GestureDetector(
            onTap: onGPSTap,
            child: Container(
              padding: const EdgeInsets.all(14),
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
              child: const Icon(Icons.my_location_rounded,
                  color: ColorsManager.white, size: 22),
            ),
          ),
        ],
      ),
    );
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
    final now       = DateTime.now();
    final diff      = state.nextPrayerTime.difference(now);
    final hours     = diff.inHours;
    final minutes   = diff.inMinutes % 60;
    final countdown = hours > 0 ? '$hours ساعة و$minutes دقيقة' : '$minutes دقيقة';
    final name      = _prayerName(state.nextPrayer);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentDark, accent],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Countdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوقت المتبقي',
                    style: _font(settings, 12,
                        ColorsManager.white.withValues(alpha: 0.80), FontWeight.normal)),
                const SizedBox(height: 4),
                Text(countdown,
                    style: _font(settings, 18, ColorsManager.white, FontWeight.bold)),
              ],
            ),
            // Prayer name + icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('الصلاة القادمة',
                    style: _font(settings, 12,
                        ColorsManager.white.withValues(alpha: 0.80), FontWeight.normal)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(name,
                        style: _font(settings, 18, ColorsManager.white, FontWeight.bold)),
                    const SizedBox(width: 8),
                    Icon(_prayerIcon(state.nextPrayer),
                        color: ColorsManager.white, size: 22),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
          // Time (left side in RTL = visual left)
          Text(timeStr,
              style: _font(settings, 16,
                  isNext ? accent : subColor, FontWeight.w600)),

          const Spacer(),

          // Name + icon (right side in RTL = visual right)
          Text(entry.name,
              style: _font(settings, 16,
                  isNext ? accent : textColor, FontWeight.w700)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isNext ? accent : accent).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.icon,
                color: accent, size: 18),
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
            Text('استخدم زر GPS تلقائياً، أو اختر مدينتك من القائمة',
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

String _prayerName(Prayer p) {
  switch (p) {
    case Prayer.fajr:    return 'الفجر';
    case Prayer.sunrise: return 'الشروق';
    case Prayer.dhuhr:   return 'الظهر';
    case Prayer.asr:     return 'العصر';
    case Prayer.maghrib: return 'المغرب';
    case Prayer.isha:    return 'العشاء';
    default:             return 'غير محدد';
  }
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
  switch (s.fontFamilyIndex) {
    case 1:  return GoogleFonts.cairo(fontSize: size, color: color, fontWeight: weight);
    case 2:  return GoogleFonts.amiri(fontSize: size, color: color, fontWeight: weight);
    default: return GoogleFonts.tajawal(fontSize: size, color: color, fontWeight: weight);
  }
}
