import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/features/prayer_times/prayer_cubit.dart';
import 'package:sabbh/features/qibla/qibla_cubit.dart';
import 'package:sabbh/theme_controller/app_settings_cubit.dart';

class Page3 extends StatelessWidget {
  final bool isActive;
  const Page3({super.key, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QiblaCubit(),
      child: _QiblaView(isActive: isActive),
    );
  }
}

// ── Main View ─────────────────────────────────────────────────────

class _QiblaView extends StatefulWidget {
  final bool isActive;
  const _QiblaView({required this.isActive});

  @override
  State<_QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<_QiblaView> {
  bool _showMap = false;
  bool _locationLinked = false;
  bool _showTiltHint = false;
  Timer? _tiltTimer;
  bool _wasActive = false;

  @override
  void dispose() {
    _tiltTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryLinkLocation();
  }

  @override
  void didUpdateWidget(_QiblaView old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_wasActive) {
      _startTiltHint();
    }
    _wasActive = widget.isActive;
  }

  void _startTiltHint() {
    _tiltTimer?.cancel();
    setState(() => _showTiltHint = true);
    _tiltTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showTiltHint = false);
    });
  }

  void _tryLinkLocation() {
    if (_locationLinked) return;
    final prayerState = context.read<PrayerCubit>().state;
    if (prayerState is PrayerLoaded) {
      _locationLinked = true;
      context.read<QiblaCubit>().start(prayerState.lat, prayerState.lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrayerCubit, PrayerState>(
      listener: (context, prayerState) {
        if (prayerState is PrayerLoaded) {
          _locationLinked = true;
          context.read<QiblaCubit>().start(prayerState.lat, prayerState.lng);
        }
      },
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          final isDark = settings.isDarkMode;
          final bg = isDark ? ColorsManager.darkBg : ColorsManager.lightBg;
          final accent = isDark ? ColorsManager.darkAccent : ColorsManager.lightAccent;
          final accentDark = isDark ? const Color(0xFF0D2E15) : const Color(0xFF2C5F3A);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: bg,
              body: BlocBuilder<QiblaCubit, QiblaState>(
                builder: (context, qiblaState) {
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _Header(
                          settings: settings,
                          isDark: isDark,
                          accent: accent,
                          accentDark: accentDark,
                          qiblaState: qiblaState,
                        ),
                      ),
                      if (!qiblaState.hasLocation)
                        SliverFillRemaining(
                          child: _NoLocationState(
                            settings: settings,
                            isDark: isDark,
                            accent: accent,
                          ),
                        )
                      else ...[
                        // Mode toggle
                        SliverToBoxAdapter(
                          child: _ModeToggle(
                            showMap: _showMap,
                            onToggle: () => setState(() => _showMap = !_showMap),
                            settings: settings,
                            isDark: isDark,
                            accent: accent,
                          ),
                        ),
                        // Calibration warning (above compass)
                        if (!_showMap && qiblaState.needsCalibration)
                          SliverToBoxAdapter(
                            child: _CalibrationWarning(settings: settings, isDark: isDark),
                          ),
                        // Compass or Map
                        if (_showMap)
                          SliverToBoxAdapter(
                            child: _MapView(
                              lat: qiblaState.lat!,
                              lng: qiblaState.lng!,
                              isDark: isDark,
                              accent: accent,
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: _CompassView(
                              qiblaState: qiblaState,
                              settings: settings,
                              isDark: isDark,
                              accent: accent,
                            ),
                          ),
                        // Tilt hint (below compass, fades after 5s)
                        if (!_showMap)
                          SliverToBoxAdapter(
                            child: AnimatedOpacity(
                              opacity: _showTiltHint ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              child: _TiltWarning(settings: settings, isDark: isDark),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  final Color accent, accentDark;
  final QiblaState qiblaState;

  const _Header({
    required this.settings,
    required this.isDark,
    required this.accent,
    required this.accentDark,
    required this.qiblaState,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final subtitle = qiblaState.qiblaAngle != null
        ? 'زاوية القبلة: ${qiblaState.qiblaAngle!.toStringAsFixed(1)}°'
        : 'حدد موقعك أولاً';

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
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          Text('اتجاه القبلة',
              style: _font(settings, 28, ColorsManager.white, FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: _font(settings, 14,
                  ColorsManager.white.withValues(alpha: 0.85), FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Mode Toggle ───────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final bool showMap;
  final VoidCallback onToggle;
  final AppSettingsState settings;
  final bool isDark;
  final Color accent;

  const _ModeToggle({
    required this.showMap,
    required this.onToggle,
    required this.settings,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
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
            Expanded(
              child: _ToggleButton(
                label: 'البوصلة',
                icon: Icons.explore_rounded,
                selected: !showMap,
                onTap: showMap ? onToggle : null,
                settings: settings,
                accent: accent,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _ToggleButton(
                label: 'الخريطة',
                icon: Icons.map_rounded,
                selected: showMap,
                onTap: !showMap ? onToggle : null,
                settings: settings,
                accent: accent,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final AppSettingsState settings;
  final Color accent;
  final bool isDark;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.settings,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? accent : subColor),
            const SizedBox(width: 6),
            Text(label,
                style: _font(settings, 13, selected ? accent : subColor,
                    selected ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ── Calibration Warning ───────────────────────────────────────────

class _CalibrationWarning extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  const _CalibrationWarning({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _WarningBanner(
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFF9A825),
      text: 'دقة البوصلة منخفضة. حرّك الهاتف على شكل رقم 8 لمعايرتها.',
      settings: settings,
      isDark: isDark,
    );
  }
}

// ── Tilt Warning ──────────────────────────────────────────────────

class _TiltWarning extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  const _TiltWarning({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _WarningBanner(
      icon: Icons.screen_rotation_rounded,
      color: const Color(0xFF42A5F5),
      text: 'ضع الهاتف بشكل مسطح للحصول على أدق قراءة.',
      settings: settings,
      isDark: isDark,
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final AppSettingsState settings;
  final bool isDark;

  const _WarningBanner({
    required this.icon,
    required this.color,
    required this.text,
    required this.settings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;
    final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: _font(settings, 12, textColor, FontWeight.normal)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compass View ──────────────────────────────────────────────────

class _CompassView extends StatelessWidget {
  final QiblaState qiblaState;
  final AppSettingsState settings;
  final bool isDark;
  final Color accent;

  const _CompassView({
    required this.qiblaState,
    required this.settings,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
    final subColor = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;
    final cardBg = isDark ? ColorsManager.darkCard : ColorsManager.lightCard;

    final heading = qiblaState.deviceHeading;
    final rotationTurns = qiblaState.qiblaRotationTurns;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // Heading display
          if (heading != null)
            Text(
              '${heading.toStringAsFixed(0)}°',
              style: _font(settings, 48, textColor, FontWeight.bold),
            ),
          const SizedBox(height: 4),
          Text(
            heading != null ? _headingDirection(heading) : 'في انتظار البوصلة...',
            style: _font(settings, 14, subColor, FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // Compass dial with fixed top indicator
          SizedBox(
            width: 300,
            height: 298,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fixed indicator triangle at top
                Positioned(
                  top: 0,
                  child: CustomPaint(
                    size: const Size(18, 14),
                    painter: _TriangleIndicatorPainter(color: accent),
                  ),
                ),

                // Compass area (offset down to make room for indicator)
                Positioned(
                  top: 14,
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer compass ring (rotates with device)
                        if (heading != null)
                          _ShortestPathRotation(
                            targetTurns: ((-heading % 360) + 360) % 360 / 360,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            child: _CompassDial(isDark: isDark, accent: accent),
                          )
                        else
                          _CompassDial(isDark: isDark, accent: accent),

                        // Qibla arrow (always points to Mecca)
                        if (rotationTurns != null)
                          _ShortestPathRotation(
                            targetTurns: rotationTurns,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            child: _QiblaArrow(accent: accent),
                          ),

                        // Kaaba icon at center
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ColorsManager.black.withValues(alpha: isDark ? 0.4 : 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.mosque_rounded, color: accent, size: 26),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  label: 'زاوية القبلة',
                  value: qiblaState.qiblaAngle != null
                      ? '${qiblaState.qiblaAngle!.toStringAsFixed(1)}°'
                      : '--',
                  settings: settings,
                  textColor: textColor,
                  subColor: subColor,
                  accent: accent,
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: isDark ? ColorsManager.darkDivider : ColorsManager.lightDivider,
                ),
                _InfoItem(
                  label: 'اتجاه الهاتف',
                  value: heading != null ? '${heading.toStringAsFixed(0)}°' : '--',
                  settings: settings,
                  textColor: textColor,
                  subColor: subColor,
                  accent: accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _headingDirection(double heading) {
    const directions = ['شمال', 'شمال شرق', 'شرق', 'جنوب شرق', 'جنوب', 'جنوب غرب', 'غرب', 'شمال غرب'];
    final index = ((heading + 22.5) % 360 / 45).floor();
    return directions[index];
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  final AppSettingsState settings;
  final Color textColor, subColor, accent;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.settings,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: _font(settings, 20, accent, FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: _font(settings, 12, subColor, FontWeight.normal)),
      ],
    );
  }
}

// ── Compass Dial (drawn with CustomPaint) ─────────────────────────

class _CompassDial extends StatelessWidget {
  final bool isDark;
  final Color accent;
  const _CompassDial({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(280, 280),
      painter: _CompassDialPainter(isDark: isDark, accent: accent),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final bool isDark;
  final Color accent;
  _CompassDialPainter({required this.isDark, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    final ringPaint = Paint()
      ..color = (isDark ? ColorsManager.darkCard : ColorsManager.lightCard)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 4, ringPaint);

    // Tick marks
    for (int i = 0; i < 360; i += 5) {
      final isCardinal = i % 90 == 0;
      final isMajor = i % 30 == 0;
      final tickLength = isCardinal ? 18.0 : (isMajor ? 12.0 : 6.0);
      final tickWidth = isCardinal ? 2.5 : (isMajor ? 1.5 : 0.8);
      final tickColor = isCardinal
          ? accent
          : (isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary)
              .withValues(alpha: isMajor ? 0.7 : 0.35);

      final angle = i * pi / 180;
      final outerR = radius - 8;
      final innerR = outerR - tickLength;

      final p1 = Offset(
        center.dx + outerR * sin(angle),
        center.dy - outerR * cos(angle),
      );
      final p2 = Offset(
        center.dx + innerR * sin(angle),
        center.dy - innerR * cos(angle),
      );

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = tickColor
          ..strokeWidth = tickWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cardinal labels
    final labels = {'0': 'N', '90': 'E', '180': 'S', '270': 'W'};
    for (final entry in labels.entries) {
      final deg = int.parse(entry.key);
      final angle = deg * pi / 180;
      final labelR = radius - 36;
      final pos = Offset(
        center.dx + labelR * sin(angle),
        center.dy - labelR * cos(angle),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            color: entry.value == 'N'
                ? accent
                : (isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      isDark != oldDelegate.isDark || accent != oldDelegate.accent;
}

// ── Fixed Top Indicator Triangle ──────────────────────────────────

class _TriangleIndicatorPainter extends CustomPainter {
  final Color color;
  _TriangleIndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // bottom center (pointing down)
      ..lineTo(0, 0)                        // top left
      ..lineTo(size.width, 0)               // top right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleIndicatorPainter old) => color != old.color;
}

// ── Qibla Arrow ───────────────────────────────────────────────────

class _QiblaArrow extends StatelessWidget {
  final Color accent;
  const _QiblaArrow({required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _QiblaArrowPainter(accent: accent),
      ),
    );
  }
}

class _QiblaArrowPainter extends CustomPainter {
  final Color accent;
  _QiblaArrowPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    // Arrow pointing up (toward qibla direction)
    final path = Path()
      ..moveTo(center.dx, center.dy - 100) // tip
      ..lineTo(center.dx - 14, center.dy - 60)
      ..lineTo(center.dx - 4, center.dy - 65)
      ..lineTo(center.dx - 4, center.dy + 40)
      ..lineTo(center.dx + 4, center.dy + 40)
      ..lineTo(center.dx + 4, center.dy - 65)
      ..lineTo(center.dx + 14, center.dy - 60)
      ..close();

    canvas.drawPath(path, paint);

    // Small circle at tip
    canvas.drawCircle(
      Offset(center.dx, center.dy - 100),
      4,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter oldDelegate) =>
      accent != oldDelegate.accent;
}

// ── Map View (fallback) ───────────────────────────────────────────

const LatLng _meccaLocation = LatLng(21.4225, 39.8262);

class _MapView extends StatelessWidget {
  final double lat, lng;
  final bool isDark;
  final Color accent;

  const _MapView({
    required this.lat,
    required this.lng,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final userPos = LatLng(lat, lng);
    final centerLat = (lat + _meccaLocation.latitude) / 2;
    final centerLng = (lng + _meccaLocation.longitude) / 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 420,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: _calculateZoom(userPos),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [userPos, _meccaLocation],
                    strokeWidth: 3,
                    color: accent,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userPos,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: ColorsManager.white, size: 18),
                    ),
                  ),
                  Marker(
                    point: _meccaLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A34E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4A34E).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mosque_rounded,
                          color: ColorsManager.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateZoom(LatLng userPos) {
    final latDiff = (lat - _meccaLocation.latitude).abs();
    final lngDiff = (lng - _meccaLocation.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    if (maxDiff > 60) return 2;
    if (maxDiff > 30) return 3;
    if (maxDiff > 15) return 4;
    if (maxDiff > 5) return 5;
    return 6;
  }
}

// ── No Location State ─────────────────────────────────────────────

class _NoLocationState extends StatelessWidget {
  final AppSettingsState settings;
  final bool isDark;
  final Color accent;

  const _NoLocationState({
    required this.settings,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary;
    final subColor = isDark ? ColorsManager.darkTextSecondary : ColorsManager.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded,
                size: 64, color: accent.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            Text('لم يتم تحديد الموقع',
                style: _font(settings, 18, textColor, FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('اذهب إلى صفحة مواقيت الصلاة وحدد موقعك أولاً\nلتتمكن من استخدام بوصلة القبلة',
                style: _font(settings, 14, subColor, FontWeight.normal),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Shortest-path AnimatedRotation ────────────────────────────────
// Avoids the 359°→1° reverse-spin by accumulating turns and always
// choosing the shortest arc (max ±0.5 turns per update).

class _ShortestPathRotation extends StatefulWidget {
  final double targetTurns;
  final Duration duration;
  final Curve curve;
  final Widget child;

  const _ShortestPathRotation({
    required this.targetTurns,
    required this.duration,
    required this.curve,
    required this.child,
  });

  @override
  State<_ShortestPathRotation> createState() => _ShortestPathRotationState();
}

class _ShortestPathRotationState extends State<_ShortestPathRotation> {
  double _cumulativeTurns = 0;

  @override
  void initState() {
    super.initState();
    _cumulativeTurns = widget.targetTurns;
  }

  @override
  void didUpdateWidget(_ShortestPathRotation old) {
    super.didUpdateWidget(old);
    if (widget.targetTurns != old.targetTurns) {
      final currentFrac = _cumulativeTurns % 1.0;
      double diff = widget.targetTurns - currentFrac;
      if (diff > 0.5) diff -= 1.0;
      if (diff < -0.5) diff += 1.0;
      _cumulativeTurns += diff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: _cumulativeTurns,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────

TextStyle _font(AppSettingsState s, double size, Color color, FontWeight weight) {
  final adjusted = size + (s.baseFontSize - 16.0);
  switch (s.fontFamilyIndex) {
    case 1:  return GoogleFonts.cairo(fontSize: adjusted, color: color, fontWeight: weight);
    case 2:  return GoogleFonts.amiri(fontSize: adjusted, color: color, fontWeight: weight);
    default: return GoogleFonts.tajawal(fontSize: adjusted, color: color, fontWeight: weight);
  }
}
