import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/adhkar/models/adhkar_model.dart';
import 'package:sabbh/features/adhkar/services/adhkar_service.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';

class MoreAdhkarPage extends StatefulWidget {
  const MoreAdhkarPage({super.key});

  @override
  State<MoreAdhkarPage> createState() => _MoreAdhkarPageState();
}

class _MoreAdhkarPageState extends State<MoreAdhkarPage> {
  final AdhkarService _service = AdhkarService();
  List<AdhkarCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  static const List<int> _categoryIds = [5, 6, 7, 8, 9, 10, 11, 12, 13];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final allCategories = await _service.loadAllCategories();
      final filtered = allCategories
          .where((c) => _categoryIds.contains(c.id))
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
          _error = 'حدث خطأ في تحميل الأذكار';
          _isLoading = false;
        });
      }
    }
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
        final accent = isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent;

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
                'المزيد من الأذكار',
                style: _font(settings, 18, textColor, FontWeight.bold),
              ),
            ),
            body: _buildBody(
              settings: settings,
              isDark: isDark,
              cardBg: cardBg,
              textColor: textColor,
              subColor: subColor,
              accent: accent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required AppSettingsState settings,
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color subColor,
    required Color accent,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: textColor)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _CategoryCard(
          category: category,
          settings: settings,
          isDark: isDark,
          cardBg: cardBg,
          textColor: textColor,
          subColor: subColor,
          onTap: () => _showAdhkarBottomSheet(
            context,
            category,
            settings,
            isDark,
          ),
        );
      },
    );
  }

  void _showAdhkarBottomSheet(
    BuildContext context,
    AdhkarCategory category,
    AppSettingsState settings,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _AdhkarBottomSheet(
        category: category,
        settings: settings,
        isDark: isDark,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AdhkarCategory category;
  final AppSettingsState settings;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.settings,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.category,
                    style: _font(settings, 15, textColor, FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAdhkarCount(category.items.length),
                    style: _font(settings, 12, subColor, FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: subColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdhkarBottomSheet extends StatelessWidget {
  final AdhkarCategory category;
  final AppSettingsState settings;
  final bool isDark;

  const _AdhkarBottomSheet({
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
            const SizedBox(height: 8),
            Text(
              _formatAdhkarCount(category.items.length),
              style: _font(settings, 13, subColor, FontWeight.w500),
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
                  return _AdhkarItemTile(
                    item: item,
                    index: index,
                    totalItems: category.items.length,
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

class _AdhkarItemTile extends StatelessWidget {
  final AdhkarItem item;
  final int index;
  final int totalItems;
  final AppSettingsState settings;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _AdhkarItemTile({
    required this.item,
    required this.index,
    required this.totalItems,
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

String _formatAdhkarCount(int count) {
  if (count == 1) {
    return 'ذكر 1';
  } else if (count == 2) {
    return 'ذكرين';
  } else {
    return '$count أذكار';
  }
}

TextStyle _font(AppSettingsState s, double size, Color color, FontWeight weight, {double? height}) {
  final adjusted = size + (s.baseFontSize - 16.0);
  switch (s.fontFamilyIndex) {
    case 1:
      return GoogleFonts.cairo(fontSize: adjusted, color: color, fontWeight: weight, height: height);
    case 2:
      return GoogleFonts.amiri(fontSize: adjusted, color: color, fontWeight: weight, height: height);
    default:
      return GoogleFonts.tajawal(fontSize: adjusted, color: color, fontWeight: weight, height: height);
  }
}
