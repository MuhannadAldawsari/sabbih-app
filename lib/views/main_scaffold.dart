import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:sabbh/views/pages/home_page.dart';
import 'package:sabbh/views/pages/page2.dart';
import 'package:sabbh/views/pages/page3.dart';
import 'package:sabbh/views/pages/settings_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const HomePage(),
    const Page2(),
    Page3(isActive: _currentIndex == 2),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark     = settings.isDarkMode;
        final accent     = isDark ? ColorsManager.darkAccent    : ColorsManager.lightAccent;
        final unselected = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;
        // Nav bar bg: semi-transparent for frosted glass effect
        final navBgColor = (isDark ? ColorsManager.darkNavBar : ColorsManager.lightNavBar)
            .withValues(alpha: 0.72);

        final items = [
          _NavItem(icon: Icons.home_rounded,              label: 'الرئيسية'),
          _NavItem(icon: Icons.mosque_rounded,            label: 'مواقيت الصلاة'),
          _NavItem(icon: Icons.explore_rounded,             label: 'القبلة'),
          _NavItem(icon: Icons.settings_rounded,          label: 'الإعدادات'),
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            // extendBody lets the scroll content go BEHIND the nav bar
            extendBody: true,
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 20),
              child: SizedBox(
                height: 70,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Frosted glass background ──────────────────
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: navBgColor,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: (isDark ? ColorsManager.white : ColorsManager.lightAccent)
                                    .withValues(alpha: 0.10),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorsManager.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ── Nav items — Positioned.fill + center vertically ─
                    Positioned.fill(
                      child: Row(
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(items.length, (i) {
                          final selected = _currentIndex == i;
                          return _NavButton(
                            item: items[i],
                            selected: selected,
                            accent: accent,
                            unselected: unselected,
                            settings: settings,
                            onTap: () => setState(() => _currentIndex = i),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final Color accent;
  final Color unselected;
  final AppSettingsState settings;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.accent,
    required this.unselected,
    required this.settings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: selected
            ? const EdgeInsets.fromLTRB(18, 8, 18, 12)
            : const EdgeInsets.fromLTRB(14, 8, 14, 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: selected ? accent : unselected, size: 24),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Transform.translate(
                        offset: const Offset(0, 3),
                        child: Text(
                          item.label,
                          style: _font(settings, 13, accent, FontWeight.w700).copyWith(
                            height: 1.0,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
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
