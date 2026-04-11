import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';

class PrayerAdjustmentsPage extends StatelessWidget {
  const PrayerAdjustmentsPage({super.key});

  static const _icons = {
    'fajr':    Icons.brightness_3_rounded,
    'dhuhr':   Icons.wb_sunny_rounded,
    'asr':     Icons.wb_cloudy_rounded,
    'maghrib': Icons.nights_stay_rounded,
    'isha':    Icons.dark_mode_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark    = settings.isDarkMode;
        final bg        = isDark ? ColorsManager.darkBg        : ColorsManager.lightBg;
        final accent    = isDark ? ColorsManager.darkAccent    : ColorsManager.lightAccent;
        final accentDark= isDark ? const Color(0xFF0D2E15)     : const Color(0xFF2C5F3A);
        final cardBg    = isDark ? ColorsManager.darkCard      : ColorsManager.lightCard;
        final textColor = isDark ? ColorsManager.darkTextPrimary   : ColorsManager.lightTextPrimary;
        final subColor  = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            body: BlocBuilder<PrayerCubit, PrayerState>(
              builder: (context, prayerState) {
                final adjustments = context.read<PrayerCubit>().adjustments;

                return CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _Header(
                        settings: settings,
                        accent: accent,
                        accentDark: accentDark,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),

                    // Description
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'يمكنك تعديل وقت الأذان بإضافة أو طرح دقائق لكل صلاة حسب حاجتك.',
                          style: _font(settings, 13, subColor, FontWeight.normal),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Prayer adjustment cards
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          PrayerCubit.prayerKeys.map((key) {
                            final label = PrayerCubit.prayerLabels[key]!;
                            final adj = adjustments[key] ?? 0;
                            final icon = _icons[key] ?? Icons.access_time_rounded;

                            String? timeStr;
                            if (prayerState is PrayerLoaded) {
                              final t = _prayerTime(prayerState, key);
                              if (t != null) timeStr = _formatTime(t);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AdjustmentCard(
                                prayerKey: key,
                                label: label,
                                icon: icon,
                                adjustment: adj,
                                timeStr: timeStr,
                                settings: settings,
                                isDark: isDark,
                                accent: accent,
                                cardBg: cardBg,
                                textColor: textColor,
                                subColor: subColor,
                              ),
                            );
                          }).toList(),
                        ),
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

  static DateTime? _prayerTime(PrayerLoaded state, String key) {
    switch (key) {
      case 'fajr':    return state.times.fajr;
      case 'dhuhr':   return state.times.dhuhr;
      case 'asr':     return state.times.asr;
      case 'maghrib': return state.times.maghrib;
      case 'isha':    return state.times.isha;
      default:        return null;
    }
  }
}

// ── Header ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppSettingsState settings;
  final Color accent, accentDark;
  final VoidCallback onBack;

  const _Header({
    required this.settings,
    required this.accent,
    required this.accentDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentDark, accent],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.arrow_forward_rounded,
                    color: ColorsManager.white, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('تعديل أوقات الأذان',
              style: _font(settings, 24, ColorsManager.white, FontWeight.bold)),
          const SizedBox(height: 4),
          Text('إضافة أو طرح دقائق',
              style: _font(settings, 13,
                  ColorsManager.white.withValues(alpha: 0.8), FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Adjustment Card ───────────────────────────────────────────────

class _AdjustmentCard extends StatelessWidget {
  final String prayerKey, label;
  final IconData icon;
  final int adjustment;
  final String? timeStr;
  final AppSettingsState settings;
  final bool isDark;
  final Color accent, cardBg, textColor, subColor;

  const _AdjustmentCard({
    required this.prayerKey,
    required this.label,
    required this.icon,
    required this.adjustment,
    required this.timeStr,
    required this.settings,
    required this.isDark,
    required this.accent,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final adjText = adjustment == 0
        ? 'بدون تعديل'
        : adjustment > 0
            ? '+$adjustment د'
            : '$adjustment د';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
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
          // Prayer icon + name + current time
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _font(settings, 16, textColor, FontWeight.w700)),
                if (timeStr != null) ...[
                  const SizedBox(height: 2),
                  Text(timeStr!, style: _font(settings, 12, subColor, FontWeight.normal)),
                ],
              ],
            ),
          ),

          // Adjustment display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: adjustment != 0
                  ? accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              adjText,
              style: _font(settings, 12,
                  adjustment != 0 ? accent : subColor, FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),

          // - button
          _RoundButton(
            icon: Icons.remove_rounded,
            accent: accent,
            isDark: isDark,
            onTap: () => context
                .read<PrayerCubit>()
                .setAdjustment(prayerKey, adjustment - 1),
          ),
          const SizedBox(width: 8),
          // + button
          _RoundButton(
            icon: Icons.add_rounded,
            accent: accent,
            isDark: isDark,
            onTap: () => context
                .read<PrayerCubit>()
                .setAdjustment(prayerKey, adjustment + 1),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accent, size: 20),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────

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
    case 1:  return GoogleFonts.cairo(fontSize: adjusted, color: color, fontWeight: weight);
    case 2:  return GoogleFonts.amiri(fontSize: adjusted, color: color, fontWeight: weight);
    default: return GoogleFonts.tajawal(fontSize: adjusted, color: color, fontWeight: weight);
  }
}
