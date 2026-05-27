import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/adhkar/cubit/adhkar_cubit.dart';
import 'package:sabbh/features/adhkar/models/adhkar_model.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';
import 'package:sabbh/core/utils/haptic_helper.dart';

class AdhkarPage extends StatelessWidget {
  final int categoryId;

  const AdhkarPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdhkarCubit(categoryId: categoryId)..loadCategory(),
      child: const _AdhkarPageContent(),
    );
  }
}

class _AdhkarPageContent extends StatefulWidget {
  const _AdhkarPageContent();

  @override
  State<_AdhkarPageContent> createState() => _AdhkarPageContentState();
}

class _AdhkarPageContentState extends State<_AdhkarPageContent> {
  static const _vibrationKey = 'adhkar_vibration_enabled';
  bool _vibrationEnabled = true;

  // ── Auto Scroll ──
  bool _isAutoScrollEnabled = true;
  late AutoScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadVibrationSetting();
    _scrollController = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVibrationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    });
  }

  Future<void> _toggleVibration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vibrationEnabled = !_vibrationEnabled;
    });
    await prefs.setBool(_vibrationKey, _vibrationEnabled);
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

        return BlocBuilder<AdhkarCubit, AdhkarState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Scaffold(
                backgroundColor: bg,
                body: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              );
            }

            if (state.error != null) {
              return Scaffold(
                backgroundColor: bg,
                body: Center(
                  child: Text(state.error!, style: TextStyle(color: textColor)),
                ),
              );
            }

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
                    state.categoryTitle,
                    style: _font(settings, 18, textColor, FontWeight.bold),
                  ),
                  actions: [
                    IconButton(
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: _isAutoScrollEnabled ? accent : subColor.withValues(alpha: 0.5),
                          ),
                          if (!_isAutoScrollEnabled)
                            Transform.rotate(
                              angle: -0.785,
                              child: Container(
                                width: 28,
                                height: 2.5,
                                color: Colors.red.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        setState(() {
                          _isAutoScrollEnabled = !_isAutoScrollEnabled;
                        });
                      },
                      tooltip: _isAutoScrollEnabled ? 'إيقاف النزول التلقائي' : 'تفعيل النزول التلقائي',
                    ),
                    IconButton(
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.vibration,
                            color: _vibrationEnabled ? accent : subColor.withValues(alpha: 0.5),
                          ),
                          if (!_vibrationEnabled)
                            Transform.rotate(
                              angle: -0.785,
                              child: Container(
                                width: 28,
                                height: 2.5,
                                color: Colors.red.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _toggleVibration,
                      tooltip: _vibrationEnabled ? 'إيقاف الاهتزاز' : 'تفعيل الاهتزاز',
                    ),
                  ],
                ),
                body: ColoredBox(
                  color: bg,
                  child: Column(
                    children: [
                      _ProgressHeader(
                        settings: settings,
                        state: state,
                        isDark: isDark,
                        textColor: textColor,
                        subColor: subColor,
                        accent: accent,
                        cardBg: cardBg,
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return AutoScrollTag(
                              key: ValueKey(index),
                              controller: _scrollController,
                              index: index,
                              child: _AdhkarCard(
                                item: item,
                                index: index,
                                totalItems: state.items.length,
                                settings: settings,
                                isDark: isDark,
                                cardBg: cardBg,
                                textColor: textColor,
                                subColor: subColor,
                                accent: accent,
                                vibrationEnabled: _vibrationEnabled,
                                isAutoScrollEnabled: _isAutoScrollEnabled,
                                scrollController: _scrollController,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final AppSettingsState settings;
  final AdhkarState state;
  final bool isDark;
  final Color textColor;
  final Color subColor;
  final Color accent;
  final Color cardBg;

  const _ProgressHeader({
    required this.settings,
    required this.state,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.accent,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdhkarCubit>();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.completedItems} / ${state.totalItems} ذكر',
                style: _font(settings, 14, subColor, FontWeight.w500),
              ),
              Text(
                '${state.completionPercentage.toStringAsFixed(0)}%',
                style: _font(settings, 14, accent, FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.completionPercentage / 100,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'تم قراءة الكل',
                  icon: Icons.done_all_rounded,
                  onTap: state.allCompleted ? null : () => cubit.markAllAsRead(),
                  settings: settings,
                  accent: accent,
                  isDark: isDark,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'إعادة تعيين',
                  icon: Icons.refresh_rounded,
                  onTap: state.completedItems == 0 ? null : () => cubit.resetProgress(),
                  settings: settings,
                  accent: accent,
                  isDark: isDark,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final AppSettingsState settings;
  final Color accent;
  final bool isDark;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.settings,
    required this.accent,
    required this.isDark,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bgColor = isPrimary 
        ? (enabled ? accent : accent.withValues(alpha: 0.3))
        : Colors.transparent;
    final borderColor = isPrimary ? Colors.transparent : (enabled ? accent : accent.withValues(alpha: 0.3));
    final textColor = isPrimary 
        ? ColorsManager.white 
        : (enabled ? accent : accent.withValues(alpha: 0.5));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(label, style: _font(settings, 13, textColor, FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AdhkarCard extends StatefulWidget {
  final AdhkarItem item;
  final int index;
  final int totalItems;
  final AppSettingsState settings;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subColor;
  final Color accent;
  final bool vibrationEnabled;
  final bool isAutoScrollEnabled;
  final AutoScrollController scrollController;

  const _AdhkarCard({
    required this.item,
    required this.index,
    required this.totalItems,
    required this.settings,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.accent,
    required this.vibrationEnabled,
    required this.isAutoScrollEnabled,
    required this.scrollController,
  });

  @override
  State<_AdhkarCard> createState() => _AdhkarCardState();
}

class _AdhkarCardState extends State<_AdhkarCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _showCompletionAnim = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onTap(AdhkarCubit cubit, AdhkarItem item) async {
    final wasCompleted = cubit.isItemCompleted(item.id);
    if (wasCompleted) return;

    final previousStage = cubit.getCurrentStage(item.id);
    
    await cubit.incrementCounter(item.id);
    
    final newStage = cubit.getCurrentStage(item.id);
    final isNowCompleted = cubit.isItemCompleted(item.id);

    if (widget.vibrationEnabled) {
      if (isNowCompleted && !wasCompleted) {
        HapticHelper.zikrCompleted();
      } else {
        HapticHelper.tasbihClick();
      }
    }

    if (newStage > previousStage || isNowCompleted) {
      _playCompletionAnimation();
    }

    // ── Auto Scroll ──
    if (isNowCompleted && !wasCompleted) {
      if (widget.isAutoScrollEnabled && widget.index < widget.totalItems - 1) {
        await Future.delayed(const Duration(milliseconds: 600));
        widget.scrollController.scrollToIndex(
          widget.index + 1,
          preferPosition: AutoScrollPosition.begin,
          duration: const Duration(milliseconds: 600),
        );
      }
    }
  }

  void _resetCounter(AdhkarCubit cubit) {
    if (widget.vibrationEnabled) {
      HapticHelper.tasbihClick();
    }
    cubit.resetSingleItem(widget.item.id);
  }

  void _playCompletionAnimation() {
    setState(() => _showCompletionAnim = true);
    _animController.forward().then((_) {
      _animController.reverse().then((_) {
        if (mounted) setState(() => _showCompletionAnim = false);
      });
    });
  }

  Color _getCardColor(bool isCompleted, int currentStage) {
    if (isCompleted) {
      return widget.isDark 
          ? Colors.green.withValues(alpha: 0.2) 
          : Colors.green.withValues(alpha: 0.12);
    }
    if (widget.item.hasMultipleStages && currentStage > 0) {
      return widget.isDark 
          ? Color.lerp(widget.cardBg, Colors.green, 0.08)! 
          : Color.lerp(widget.cardBg, Colors.green, 0.06)!;
    }
    return widget.cardBg;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdhkarCubit>();
    
    return BlocBuilder<AdhkarCubit, AdhkarState>(
      builder: (context, state) {
        final progress = cubit.getItemProgress(widget.item);
        final currentTaps = cubit.getCurrentTaps(widget.item.id);
        final currentStage = cubit.getCurrentStage(widget.item.id);
        final currentStageTarget = cubit.getCurrentStageTarget(widget.item);
        final isCompleted = cubit.isItemCompleted(widget.item.id);

        return GestureDetector(
          onTap: () => _onTap(cubit, widget.item),
          child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCardColor(isCompleted, currentStage),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColorsManager.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: _CircularCounter(
                            progress: progress,
                            currentTaps: currentTaps,
                            targetTaps: currentStageTarget,
                            isCompleted: isCompleted,
                            showCompletionAnim: _showCompletionAnim,
                            accent: widget.accent,
                            isDark: widget.isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.index + 1}/${widget.totalItems}',
                          style: _font(widget.settings, 13, widget.subColor, FontWeight.w500),
                        ),
                        const Spacer(),
                        if (widget.item.hasMultipleStages)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'مراحل متعددة',
                              style: _font(widget.settings, 10, widget.accent, FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.item.text,
                      style: _font(widget.settings, 16, widget.textColor, FontWeight.w500, height: 2),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: widget.subColor.withValues(alpha: 0.2), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (widget.item.hasSource) ...[
                          Icon(Icons.menu_book_rounded, size: 16, color: widget.subColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.item.source,
                              style: _font(widget.settings, 12, widget.subColor, FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (currentTaps > 0) ...[
                          GestureDetector(
                            onTap: () => _resetCounter(cubit),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (widget.item.hasDetails)
                          GestureDetector(
                            onTap: () => _showDetailsSheet(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: widget.accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: widget.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.item.hasFadhelShort) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.item.fadhelShort,
                          style: _font(widget.settings, 12, widget.accent, FontWeight.w500),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        );
      },
    );
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _DetailsBottomSheet(
        item: widget.item,
        settings: widget.settings,
        isDark: widget.isDark,
      ),
    );
  }
}

class _CircularCounter extends StatefulWidget {
  final double progress;
  final int currentTaps;
  final int targetTaps;
  final bool isCompleted;
  final bool showCompletionAnim;
  final Color accent;
  final bool isDark;

  const _CircularCounter({
    required this.progress,
    required this.currentTaps,
    required this.targetTaps,
    required this.isCompleted,
    required this.showCompletionAnim,
    required this.accent,
    required this.isDark,
  });

  @override
  State<_CircularCounter> createState() => _CircularCounterState();
}

class _CircularCounterState extends State<_CircularCounter> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
    _previousProgress = widget.progress;
    _progressController.forward();
  }

  @override
  void didUpdateWidget(_CircularCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOut,
      ));
      _previousProgress = widget.progress;
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: 4,
                  backgroundColor: widget.isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isCompleted ? ColorsManager.successGreen : widget.accent,
                  ),
                );
              },
            ),
          ),
          if (widget.isCompleted)
            Icon(
              Icons.check_rounded,
              color: ColorsManager.successGreen,
              size: 24,
            )
          else
            Text(
              '${widget.currentTaps}/${widget.targetTaps}',
              style: TextStyle(fontFamily: 'Tajawal', 
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailsBottomSheet extends StatelessWidget {
  final AdhkarItem item;
  final AppSettingsState settings;
  final bool isDark;

  const _DetailsBottomSheet({
    required this.item,
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
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
              'تفاصيل الذكر',
              style: _font(settings, 18, textColor, FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.hasFadhelShort) ...[
                      _DetailSection(
                        title: 'الفضل',
                        content: item.fadhelShort,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                        accent: accent,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (item.dalil.isNotEmpty) ...[
                      _DetailSection(
                        title: 'الدليل',
                        content: item.dalil,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                        accent: accent,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (item.summary.isNotEmpty) ...[
                      _DetailSection(
                        title: null,
                        content: item.summary,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                        accent: accent,
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (item.narrator.isNotEmpty) ...[
                      _DetailRow(
                        label: 'الراوي',
                        value: item.narrator,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (item.almohdith.isNotEmpty) ...[
                      _DetailRow(
                        label: 'المحدث',
                        value: item.almohdith,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (item.source.isNotEmpty) ...[
                      _DetailRow(
                        label: 'المصدر',
                        value: item.source,
                        settings: settings,
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String? title;
  final String content;
  final AppSettingsState settings;
  final Color textColor;
  final Color subColor;
  final Color accent;
  final bool isHighlighted;

  const _DetailSection({
    required this.title,
    required this.content,
    required this.settings,
    required this.textColor,
    required this.subColor,
    required this.accent,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? accent.withValues(alpha: 0.12)
            : subColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: _font(settings, 13, accent, FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            content,
            style: _font(
              settings, 
              isHighlighted ? 14 : 13, 
              isHighlighted ? accent : textColor, 
              isHighlighted ? FontWeight.w600 : FontWeight.normal,
              height: 2,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final AppSettingsState settings;
  final Color textColor;
  final Color subColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.settings,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: _font(settings, 13, subColor, FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: _font(settings, 13, textColor, FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

TextStyle _font(AppSettingsState s, double size, Color color, FontWeight weight, {double? height}) {
  final adjusted = size + (s.baseFontSize - 16.0);
  switch (s.fontFamilyIndex) {
    case 1:
      return TextStyle(fontFamily: 'Cairo', fontSize: adjusted, color: color, fontWeight: weight, height: height);
    case 2:
      return TextStyle(fontFamily: 'Amiri', fontSize: adjusted, color: color, fontWeight: weight, height: height);
    default:
      return TextStyle(fontFamily: 'Tajawal', fontSize: adjusted, color: color, fontWeight: weight, height: height);
  }
}
