import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:sabbh/views/NavigableBottomSheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// ── Arabic month names ────────────────────────────────────────────

const _hijriMonths = [
  'محرم','صفر','ربيع الأول','ربيع الآخر',
  'جمادى الأولى','جمادى الآخرة','رجب','شعبان',
  'رمضان','شوال','ذو القعدة','ذو الحجة',
];

const _gregorianMonths = [
  'يناير','فبراير','مارس','أبريل','مايو','يونيو',
  'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر',
];

const _weekDays = [
  'الاثنين','الثلاثاء','الأربعاء','الخميس',
  'الجمعة','السبت','الأحد',
];

// ── Home Page ─────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark    = settings.isDarkMode;
        final bg        = isDark ? ColorsManager.darkBg    : ColorsManager.lightBg;
        final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;

        return Scaffold(
          backgroundColor: bg,
          // Let header bleed behind status bar
          extendBodyBehindAppBar: true,
          body: CustomScrollView(
            slivers: [
              // ── Rounded Header ────────────────────────────────
              SliverToBoxAdapter(
                child: _HomeHeader(settings: settings, isDark: isDark),
              ),

              // ── Body content ──────────────────────────────────
              SliverPadding(
                // Extra top padding accounts for floating card overlap
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _sectionLabel('الأذكار', settings, textColor),
                    const SizedBox(height: 12),
                    _DhikrGrid(settings: settings, isDark: isDark),
                    const SizedBox(height: 28),
                    _sectionLabel('المهام', settings, textColor),
                    const SizedBox(height: 12),
                    TaskCard(
                      text1: 'أذكار الصباح',
                      time: '5:00 AM',
                      cardColor: isDark ? ColorsManager.morningDark : ColorsManager.morningLight,
                      settings: settings,
                    ),
                    const SizedBox(height: 12),
                    TaskCard(
                      text1: 'أذكار المساء',
                      time: '4:00 PM',
                      cardColor: isDark ? ColorsManager.eveningDark : ColorsManager.eveningLight,
                      settings: settings,
                    ),
                    const SizedBox(height: 12),
                    TaskCard(
                      text1: 'أذكار النوم',
                      time: '12:30 AM',
                      cardColor: isDark ? ColorsManager.sleepDark : ColorsManager.sleepLight,
                      settings: settings,
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text, AppSettingsState s, Color c) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(text, style: _font(s, 18, c, FontWeight.bold)),
    );
  }
}

// ── Curved Header ─────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  const _HomeHeader({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent      = isDark ? ColorsManager.darkAccent  : ColorsManager.lightAccent;
    final accentDark  = isDark ? const Color(0xFF0A1A0C)   : const Color(0xFF2E5E3A);
    final cardBg      = isDark ? ColorsManager.darkCard     : ColorsManager.lightCard;
    final textOnAccent = ColorsManager.white;
    final subOnAccent  = ColorsManager.white.withValues(alpha: 0.80);

    // ── Dates ─────────────────────────────────────────────────
    final now   = DateTime.now();
    final hijri = HijriCalendar.now();

    final gregorianStr =
        '${_weekDays[now.weekday - 1]}، ${now.day} ${_gregorianMonths[now.month - 1]} ${now.year}';
    final hijriStr =
        '${hijri.hDay} ${_hijriMonths[hijri.hMonth - 1]} ${hijri.hYear}';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // ── Full-width gradient header with rounded bottom corners ─
        Container(
          width: double.infinity,
          // Extra height = status bar + content
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentDark, accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft:  Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'سبِّح',
                  style: _font(settings, 34, textOnAccent, FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  hijriStr,
                  style: _font(settings, 15, subOnAccent, FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  gregorianStr,
                  style: _font(settings, 13, subOnAccent, FontWeight.normal),
                ),
              ],
            ),
          ),
        ),

        // ── Floating card centred at the rounded edge ──────────
        Positioned(
          bottom: -44,
          child: _FloatingDhikrCard(
            settings: settings,
            isDark: isDark,
            cardBg: cardBg,
            accent: accent,
          ),
        ),
      ],
    );
  }
}



// ── Floating Dhikr Card at curve ─────────────────────────────────

class _FloatingDhikrCard extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  final Color cardBg;
  final Color accent;
  const _FloatingDhikrCard({
    required this.settings,
    required this.isDark,
    required this.cardBg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? ColorsManager.darkTextPrimary   : ColorsManager.lightTextPrimary;
    final subColor  = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

    return Container(
      width: MediaQuery.of(context).size.width - 48,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Text on the RIGHT (first in RTL)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ذكر اليوم',
                  style: _font(settings, 13, subColor, FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
                  style: _font(settings, 15, textColor, FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Icon on the LEFT (last in RTL)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 22),
          ),
        ],
      ),
    );
  }
}


// ── Dhikr Card Grid ───────────────────────────────────────────────

// ── Dhikr Card Grid (5 cards, 3 styles) ──────────────────────────

class _DhikrGrid extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  const _DhikrGrid({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent    = isDark ? ColorsManager.darkAccent  : ColorsManager.lightAccent;
    final cardWhite  = isDark ? ColorsManager.darkCard   : ColorsManager.lightCard;
    final textColor  = isDark ? ColorsManager.darkTextPrimary   : ColorsManager.lightTextPrimary;
    final iconColor  = isDark ? ColorsManager.darkAccent        : ColorsManager.lightAccent;
    final subText    = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

    // Subtle white gradients
    final brownGradient = LinearGradient(
      colors: isDark
          ? [ColorsManager.darkCard, const Color(0xFF2A200F)]
          : [ColorsManager.lightCard, const Color(0xFFFFF3E4)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    final greenGradient = LinearGradient(
      colors: isDark
          ? [ColorsManager.darkCard, const Color(0xFF102018)]
          : [ColorsManager.lightCard, const Color(0xFFE8F5ED)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );

    // Shared square height
    const cardH = 114.0;

    Widget whiteCard(String title, IconData icon, int num) => _SquareDhikrCard(
      title: title, icon: icon, number: num,
      bg: cardWhite, textColor: textColor, iconColor: iconColor,
      settings: settings, isDark: isDark, cardH: cardH,
    );

    Widget brownCard(String title, IconData icon, int num) => _SquareDhikrCard(
      title: title, icon: icon, number: num,
      bg: cardWhite, textColor: textColor, iconColor: iconColor,
      settings: settings, isDark: isDark, cardH: cardH,
      gradient: brownGradient,
    );

    return Column(
      children: [
        // ── Row 1: brown(right) | white | white(left) ──────────
        Row(
          children: [
            Expanded(child: brownCard('أذكار بعد الصلاة', Icons.mosque_outlined,    3)),
            const SizedBox(width: 12),
            Expanded(child: whiteCard('أذكار المساء',     Icons.nights_stay_outlined, 1)),
            const SizedBox(width: 12),
            Expanded(child: whiteCard('أذكار الصباح',     Icons.wb_sunny_outlined,  2)),
          ],
        ),
        const SizedBox(height: 12),
        // ── Row 2: green wide(right) | white(left) ────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wide green card on the RIGHT (first in RTL)
              Expanded(
                flex: 8,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: greenGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: ColorsManager.black.withValues(alpha: isDark ? 0.30 : 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.auto_stories_outlined, color: iconColor, size: 24),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            'المزيد من الأذكار',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: _font(settings, 13, textColor, FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // White card on the LEFT (second in RTL)
              Expanded(
                flex: 5,
                child: whiteCard('أذكار النوم', Icons.bedtime_outlined, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Square Dhikr Card (white & brown) ────────────────────────────

class _SquareDhikrCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int number;
  final Color bg;
  final Color textColor;
  final Color iconColor;
  final AppSettingsState settings;
  final bool isDark;
  final double cardH;
  final Gradient? gradient;

  const _SquareDhikrCard({
    required this.title, required this.icon, required this.number,
    required this.bg, required this.textColor, required this.iconColor,
    required this.settings, required this.isDark, required this.cardH,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        height: cardH,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.black.withValues(alpha: isDark ? 0.30 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Text(title,
                textAlign: TextAlign.center,
                style: _font(settings, 12.5, textColor, FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final cubit = context.read<AppSettingsCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: cubit,
        child: NavigableBottomSheet(number, isDark),
      ),
    );
  }
}



// ── Task Card ─────────────────────────────────────────────────────

class TaskCard extends StatefulWidget {
  final String text1;
  final String time;
  final Color cardColor;
  final AppSettingsState settings;

  const TaskCard({
    super.key,
    required this.text1,
    required this.time,
    required this.cardColor,
    required this.settings,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with WidgetsBindingObserver {
  bool isCompleted = false;
  DateTime? completedAt;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTaskState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkIfShouldReset();
  }

  Future<void> _loadTaskState() async {
    final prefs = await SharedPreferences.getInstance();
    final key   = widget.text1;
    final completed         = prefs.getBool('${key}_completed') ?? false;
    final completedAtMillis = prefs.getInt('${key}_completedAt');
    if (completed && completedAtMillis != null) {
      setState(() {
        isCompleted = completed;
        completedAt = DateTime.fromMillisecondsSinceEpoch(completedAtMillis);
      });
      _checkIfShouldReset();
    }
  }

  Future<void> _saveTaskState() async {
    final prefs = await SharedPreferences.getInstance();
    final key   = widget.text1;
    await prefs.setBool('${key}_completed', isCompleted);
    if (completedAt != null) {
      await prefs.setInt('${key}_completedAt', completedAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('${key}_completedAt');
    }
  }

  void _checkIfShouldReset() {
    if (isCompleted && completedAt != null) {
      final diff = DateTime.now().difference(completedAt!);
      if (diff.inHours >= 22) {
        setState(() { isCompleted = false; completedAt = null; });
        _saveTaskState();
        _resetTimer?.cancel();
      } else {
        final remaining = const Duration(hours: 22) - diff;
        _resetTimer?.cancel();
        _resetTimer = Timer(remaining, () {
          if (mounted) setState(() { isCompleted = false; completedAt = null; });
          _saveTaskState();
        });
      }
    }
  }

  void _toggleCompletion() {
    setState(() {
      if (!isCompleted) {
        isCompleted = true;
        completedAt = DateTime.now();
        _resetTimer?.cancel();
        _resetTimer = Timer(const Duration(hours: 22), () {
          if (mounted) setState(() { isCompleted = false; completedAt = null; });
          _saveTaskState();
        });
      } else {
        isCompleted  = false;
        completedAt  = null;
        _resetTimer?.cancel();
      }
    });
    _saveTaskState();
  }

  @override
  Widget build(BuildContext context) {
    final s         = widget.settings;
    final isDark    = s.isDarkMode;
    final textColor = isDark ? ColorsManager.darkTextPrimary   : ColorsManager.lightTextPrimary;
    final subColor  = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;
    final accent    = isDark ? ColorsManager.darkAccent        : ColorsManager.lightAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: _toggleCompletion,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(isCompleted),
                color: isCompleted ? accent : subColor,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.text1,
                    style: _font(s, 15, textColor, FontWeight.w600).copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? subColor : textColor,
                    )),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(widget.time, style: _font(s, 12, subColor, FontWeight.normal)),
                    const SizedBox(width: 4),
                    Icon(Icons.access_time_rounded, size: 13, color: subColor),
                    const SizedBox(width: 10),
                    Text('اليوم', style: _font(s, 12, subColor, FontWeight.normal)),
                    const SizedBox(width: 4),
                    Icon(Icons.calendar_today_outlined, size: 13, color: subColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Font helper ───────────────────────────────────────────────────

TextStyle _font(AppSettingsState s, double relativeSize, Color color, FontWeight weight) {
  final base = s.baseFontSize;
  final size = (base + (relativeSize - 15)).clamp(10.0, 42.0);
  switch (s.fontFamilyIndex) {
    case 1:  return GoogleFonts.cairo(fontSize: size,  color: color, fontWeight: weight);
    case 2:  return GoogleFonts.amiri(fontSize: size,  color: color, fontWeight: weight);
    default: return GoogleFonts.tajawal(fontSize: size, color: color, fontWeight: weight);
  }
}
