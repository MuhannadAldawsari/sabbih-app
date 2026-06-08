import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/views/pages/notification_settings_page.dart';
import 'package:sabbh/views/pages/iqama_notification_page.dart';
import 'package:sabbh/views/pages/prayer_adjustments_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            extendBody: true,
            body: SafeArea(
              bottom: false,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Text(
                  'الإعدادات',
                  textAlign: TextAlign.right,
                  style: _font(settings, 24, textColor, FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // ── المظهر ─────────────────────────────────────
                _sectionLabel('المظهر', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: _toggleRow(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    accent: accent,
                    title: isDark ? 'الوضع الداكن' : 'الوضع الفاتح',
                    subtitle: isDark ? 'تفعيل المظهر الداكن' : 'تفعيل المظهر الفاتح',
                    value: isDark,
                    settings: settings,
                    textColor: textColor,
                    subColor: subColor,
                    onChanged: (_) => context.read<AppSettingsCubit>().toggleTheme(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── الخط ──────────────────────────────────────
                _sectionLabel('نوع الخط', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(Icons.font_download_outlined, color: accent, size: 22),
                            const SizedBox(width: 10),
                            Text('اختر الخط', style: _font(settings, 15, textColor, FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(3, (i) {
                            final names = ['عصري', 'مريح', 'كلاسيكي'];
                            final selected = settings.fontFamilyIndex == i;
                            return GestureDetector(
                              onTap: () => context.read<AppSettingsCubit>().setFontFamilyIndex(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? accent : accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? accent : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  names[i],
                                  style: _fontByIndex(i, 14, selected ? ColorsManager.white : accent, FontWeight.w600),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── حجم الخط ──────────────────────────────────
                _sectionLabel('حجم الخط', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(Icons.format_size_rounded, color: accent, size: 22),
                                const SizedBox(width: 10),
                                Text('حجم الخط', style: _font(settings, 15, textColor, FontWeight.w600)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _fontSizeLabels[settings.fontSizeLevel],
                                style: _font(settings, 13, accent, FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 8 level dots picker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(8, (i) {
                            final selected = settings.fontSizeLevel == i;
                            return GestureDetector(
                              onTap: () => context.read<AppSettingsCubit>().setFontSizeLevel(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: selected ? 36 : 28,
                                height: selected ? 36 : 28,
                                decoration: BoxDecoration(
                                  color: selected ? accent : accent.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: selected ? 13 : 11,
                                    color: selected ? ColorsManager.white : accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        // Preview text
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
                            textAlign: TextAlign.center,
                            style: _font(settings, settings.baseFontSize, textColor, FontWeight.normal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── أوقات الأذان ──────────────────────────────
                _sectionLabel('أوقات الأذان', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: context.read<AppSettingsCubit>()),
                            BlocProvider.value(value: context.read<PrayerCubit>()),
                          ],
                          child: const PrayerAdjustmentsPage(),
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: _navigableRow(
                        settings: settings,
                        accent: accent,
                        textColor: textColor,
                        subColor: subColor,
                        icon: Icons.schedule_rounded,
                        title: 'تعديل الأذان والموقع اليدوي',
                        subtitle: 'تعديل الدقائق واختيار المدينة يدويًا',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── إشعار الإقامة ───────────────────────────────
                _sectionLabel('إشعار الإقامة', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AppSettingsCubit>(),
                          child: const IqamaNotificationPage(),
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: _navigableRow(
                        settings: settings,
                        accent: accent,
                        textColor: textColor,
                        subColor: subColor,
                        icon: Icons.timer_outlined,
                        title: 'إشعار وقت الإقامة',
                        subtitle: 'التحكم في عرض عدّاد الأذان والإقامة',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── الإشعارات ─────────────────────────────────
                _sectionLabel('الإشعارات', settings, subColor),
                const SizedBox(height: 8),
                _card(
                  cardBg: cardBg,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AppSettingsCubit>(),
                          child: const NotificationSettingsPage(),
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: _navigableRow(
                        settings: settings,
                        accent: accent,
                        textColor: textColor,
                        subColor: subColor,
                        icon: Icons.notifications_outlined,
                        title: 'اعدادات التنبيهات',
                        subtitle: 'ضبط أوقات وتنبيهات الأذكار',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  static const _fontSizeLabels = [
    'صغير جدا', 'صغير+', 'صغير', 'عادي', 'متوسط',
    'كبير', 'كبير+', 'كبير جدا'
  ];

  Widget _sectionLabel(String text, AppSettingsState s, Color color) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(text, style: _font(s, 13, color, FontWeight.w600)),
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
                  style: _font(settings, 12, subColor,  FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged, activeColor: accent),
        ],
      ),
    );
  }

  Widget _navigableRow({
    required AppSettingsState settings,
    required Color accent,
    required Color textColor,
    required Color subColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
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
        Icon(Icons.arrow_forward_ios_rounded, color: subColor),
      ],
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

TextStyle _fontByIndex(int idx, double size, Color color, FontWeight weight) {
  switch (idx) {
    case 1:  return TextStyle(fontFamily: 'Cairo', fontSize: size, color: color, fontWeight: weight);
    case 2:  return TextStyle(fontFamily: 'Amiri', fontSize: size, color: color, fontWeight: weight);
    default: return TextStyle(fontFamily: 'Tajawal', fontSize: size, color: color, fontWeight: weight);
  }
}
