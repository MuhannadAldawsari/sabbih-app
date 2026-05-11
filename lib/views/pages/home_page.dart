import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:sabbh/views/pages/adhkar_page.dart';
import 'package:sabbh/views/pages/more_adhkar_page.dart';
import 'package:sabbh/features/adhkar/services/adhkar_service.dart';
import 'package:sabbh/features/adhkar/models/adhkar_model.dart';

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
                    _sectionLabel('الأدعية', settings, textColor),
                    const SizedBox(height: 12),
                    _DuaGrid(settings: settings, isDark: isDark),
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
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
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

  void _openAdhkarPage(BuildContext context, int categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdhkarPage(categoryId: categoryId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Row 1: brown(right) | white | white(left) ──────────
        Row(
          children: [
            Expanded(
              child: _SquareCard(
                title: 'أذكار بعد الصلاة',
                icon: Icons.mosque_outlined,
                onTap: () => _openAdhkarPage(context, 3),
                settings: settings,
                isDark: isDark,
                gradient: _brownGradient(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SquareCard(
                title: 'أذكار المساء',
                icon: Icons.nights_stay_outlined,
                onTap: () => _openAdhkarPage(context, 2),
                settings: settings,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SquareCard(
                title: 'أذكار الصباح',
                icon: Icons.wb_sunny_outlined,
                onTap: () => _openAdhkarPage(context, 1),
                settings: settings,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── Row 2: green wide(right) | white(left) ────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 8,
                child: _WideCard(
                  title: 'المزيد من الأذكار',
                  icon: Icons.auto_stories_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MoreAdhkarPage()),
                  ),
                  settings: settings,
                  isDark: isDark,
                  gradient: _greenGradient(isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: _SquareCard(
                  title: 'أذكار النوم',
                  icon: Icons.bedtime_outlined,
                  onTap: () => _openAdhkarPage(context, 4),
                  settings: settings,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ── Reusable Card Components ──────────────────────────────────────
// ══════════════════════════════════════════════════════════════════

/// بطاقة مربعة قابلة لإعادة الاستخدام
/// [gradient] اختياري - إذا كان null يستخدم لون الخلفية الافتراضي
class _SquareCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final AppSettingsState settings;
  final bool isDark;
  final Gradient? gradient;

  const _SquareCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.settings,
    required this.isDark,
    this.gradient,
  });

  static const double _cardHeight = 114.0;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;
    final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
    final iconColor = isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _cardHeight,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gradient == null ? cardBg : null,
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
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: _font(settings, 12.5, textColor, FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة مستطيلة (عريضة) قابلة لإعادة الاستخدام
/// [gradient] إجباري - البطاقات المستطيلة دائماً ملونة
class _WideCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final AppSettingsState settings;
  final bool isDark;
  final Gradient gradient;

  const _WideCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.settings,
    required this.isDark,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
    final iconColor = isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: _font(settings, 13, textColor, FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient Helpers ──────────────────────────────────────────────

LinearGradient _brownGradient(bool isDark) => LinearGradient(
  colors: isDark
      ? [ColorsManager.darkCard, const Color(0xFF3D2A10)]
      : [ColorsManager.lightCard, const Color(0xFFFFF0E0)],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);

LinearGradient _greenGradient(bool isDark) => LinearGradient(
  colors: isDark
      ? [ColorsManager.darkCard, const Color(0xFF0D3320)]
      : [ColorsManager.lightCard, const Color(0xFFE0F2E0)],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);

// ── Dua Card Grid (5 cards) ───────────────────────────────────────

class _DuaGrid extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  const _DuaGrid({required this.settings, required this.isDark});

  void _showDuaBottomSheet(BuildContext context, int categoryId) async {
    final service = AdhkarService();
    final category = await service.getCategoryById(categoryId);
    
    if (category == null || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _DuaBottomSheet(
        category: category,
        settings: settings,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Row 1: green wide(left) | white square(right) ──────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Square white card - دعاء صلاة الاستخارة
              Expanded(
                flex: 5,
                child: _SquareCard(
                  title: 'دعاء صلاة الاستخارة',
                  icon: Icons.menu_book_outlined,
                  onTap: () => _showDuaBottomSheet(context, 16),
                  settings: settings,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              // Wide brown card - دعاء السفر والرجوع منه
              Expanded(
                flex: 8,
                child: _WideCard(
                  title: 'دعاء السفر والرجوع منه',
                  icon: Icons.menu_book_outlined,
                  onTap: () => _showDuaBottomSheet(context, 14),
                  settings: settings,
                  isDark: isDark,
                  gradient: _brownGradient(isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Row 2: white(left) | green wide(right) ──────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wide green card - المزيد من الأدعية
              Expanded(
                flex: 8,
                child: _WideCard(
                  title: 'المزيد من الأدعية',
                  icon: Icons.auto_stories_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MoreDuaPage()),
                  ),
                  settings: settings,
                  isDark: isDark,
                  gradient: _greenGradient(isDark),
                ),
              ),
              const SizedBox(width: 12),
              // Square white card - كفارة المجلس
              Expanded(
                flex: 5,
                child: _SquareCard(
                  title: 'كفارة المجلس',
                  icon: Icons.menu_book_outlined,
                  onTap: () => _showDuaBottomSheet(context, 15),
                  settings: settings,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dua Bottom Sheet ──────────────────────────────────────────────

class _DuaBottomSheet extends StatelessWidget {
  final AdhkarCategory category;
  final AppSettingsState settings;
  final bool isDark;

  const _DuaBottomSheet({
    required this.category,
    required this.settings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;
    final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
    final subColor = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;
    final accent = isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category.category,
              style: _font(settings, 18, textColor, FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Divider(color: subColor.withValues(alpha: 0.2), height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: category.items.length,
                separatorBuilder: (_, __) => Divider(
                  color: subColor.withValues(alpha: 0.15),
                  height: 32,
                ),
                itemBuilder: (context, index) {
                  final item = category.items[index];
                  return _DuaItemTile(
                    item: item,
                    index: index,
                    settings: settings,
                    textColor: textColor,
                    subColor: subColor,
                    accent: accent,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dua Item Tile ─────────────────────────────────────────────────

class _DuaItemTile extends StatelessWidget {
  final AdhkarItem item;
  final int index;
  final AppSettingsState settings;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _DuaItemTile({
    required this.item,
    required this.index,
    required this.settings,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: _font(settings, 12, accent, FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (item.totalCount > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.totalCount} مرات',
                  style: _font(settings, 11, subColor, FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.text,
          style: _font(settings, 15, textColor, FontWeight.w500, height: 2),
          textAlign: TextAlign.right,
        ),
        if (item.hasSource) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 14, color: subColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.source,
                  style: _font(settings, 11, subColor, FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── More Dua Page ─────────────────────────────────────────────────

class MoreDuaPage extends StatefulWidget {
  const MoreDuaPage({super.key});

  @override
  State<MoreDuaPage> createState() => _MoreDuaPageState();
}

class _MoreDuaPageState extends State<MoreDuaPage> {
  final AdhkarService _service = AdhkarService();
  final TextEditingController _searchController = TextEditingController();
  List<AdhkarCategory> _categories = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  List<AdhkarCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where((c) => c.category.contains(_searchQuery))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final allCategories = await _service.loadAllCategories();
      final filtered = allCategories
          .where((c) => c.id >= 17)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      
      if (mounted) {
        setState(() {
          _categories = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل الأدعية';
          _isLoading = false;
        });
      }
    }
  }

  void _showDuaBottomSheet(BuildContext context, AdhkarCategory category, AppSettingsState settings, bool isDark) {
    final bg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;
    final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
    final subColor = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;
    final accent = isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                category.category,
                style: _font(settings, 18, textColor, FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Divider(color: subColor.withValues(alpha: 0.2), height: 1),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: category.items.length,
                  separatorBuilder: (_, __) => Divider(
                    color: subColor.withValues(alpha: 0.15),
                    height: 32,
                  ),
                  itemBuilder: (context, index) {
                    final item = category.items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: _font(settings, 12, accent, FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (item.totalCount > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: subColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.totalCount} مرات',
                                  style: _font(settings, 11, subColor, FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.text,
                          style: _font(settings, 15, textColor, FontWeight.w500, height: 2),
                          textAlign: TextAlign.right,
                        ),
                        if (item.hasSource) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 14, color: subColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.source,
                                  style: _font(settings, 11, subColor, FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAdhkarCount(int count) {
    if (count == 1) return 'ذكر 1';
    if (count == 2) return 'ذكرين';
    return '$count أذكار';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        final isDark = settings.isDarkMode;
        final bg = isDark ? ColorsManager.darkBg : ColorsManager.lightBg;
        final cardBg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;
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
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'المزيد من الأدعية',
                style: _font(settings, 18, textColor, FontWeight.bold),
              ),
            ),
            body: _isLoading
                ? Center(child: CircularProgressIndicator(color: isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent))
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: textColor)))
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: _font(settings, 14, textColor, FontWeight.w500),
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'ابحث عن دعاء...',
                                hintStyle: _font(settings, 14, subColor, FontWeight.w400),
                                prefixIcon: Icon(Icons.search_rounded, color: subColor),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded, color: subColor, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: cardBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _filteredCategories.isEmpty
                                ? Center(
                                    child: Text(
                                      'لا توجد نتائج',
                                      style: _font(settings, 14, subColor, FontWeight.w500),
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.1,
                                    ),
                                    itemCount: _filteredCategories.length,
                                    itemBuilder: (context, index) {
                                      final category = _filteredCategories[index];
                                      return GestureDetector(
                                        onTap: () => _showDuaBottomSheet(context, category, settings, isDark),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: cardBg,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: ColorsManager.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                category.category,
                                                style: _font(settings, 14, textColor, FontWeight.w600),
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _formatAdhkarCount(category.items.length),
                                                style: _font(settings, 12, subColor, FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }
}

// ── Font helper ───────────────────────────────────────────────────

TextStyle _font(AppSettingsState s, double relativeSize, Color color, FontWeight weight, {double? height}) {
  final base = s.baseFontSize;
  final size = (base + (relativeSize - 15)).clamp(10.0, 42.0);
  switch (s.fontFamilyIndex) {
    case 1:  return GoogleFonts.cairo(fontSize: size,  color: color, fontWeight: weight, height: height);
    case 2:  return GoogleFonts.amiri(fontSize: size,  color: color, fontWeight: weight, height: height);
    default: return GoogleFonts.tajawal(fontSize: size, color: color, fontWeight: weight, height: height);
  }
}
