import 'package:flutter/material.dart';

abstract class ColorsManager {
  // ── Light Mode ──────────────────────────────────────────────
  static const Color lightBg        = Color(0xFFF0E9DF); // warm beige background
  static const Color lightCard      = Color(0xFFFFFFFF); // white cards
  static const Color lightAccent    = Color(0xFF4A7C59); // muted green accent
  static const Color lightNavBar    = Color(0xFFFFFFFF); // nav bar background
  static const Color lightTextPrimary   = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightDivider   = Color(0xFFE0D8CE);
  static const Color lightCardAlt   = Color(0xFFF7F0E8); // slightly tinted card alt

  // ── Dark Mode ────────────────────────────────────────────────
  static const Color darkBg         = Color(0xFF0D1A0F); // dark forest green background
  static const Color darkCard       = Color(0xFF162318); // dark card
  static const Color darkAccent     = Color(0xFF4CAF6E); // bright green accent
  static const Color darkNavBar     = Color(0xFF1A2B1D); // nav bar background
  static const Color darkTextPrimary   = Color(0xFFF0F0E8);
  static const Color darkTextSecondary = Color(0xFF9EA89F);
  static const Color darkDivider    = Color(0xFF1F3022);
  static const Color darkCardAlt    = Color(0xFF1C2D1F); // slightly different card alt

  // ── Dhikr Card Accent Colors (light / dark pairs) ────────────
  // Evening (أذكار المساء)
  static const Color eveningLight   = Color(0xFFE3D5C8);
  static const Color eveningDark    = Color(0xFF1F3020);
  // Morning (أذكار الصباح)
  static const Color morningLight   = Color(0xFFFFF5D6);
  static const Color morningDark    = Color(0xFF2A2810);
  // After Prayer (أذكار بعد الصلاة)
  static const Color prayerLight    = Color(0xFFD6EDDF);
  static const Color prayerDark     = Color(0xFF0E2818);
  // Sleep (أذكار النوم)
  static const Color sleepLight     = Color(0xFFE8D6ED);
  static const Color sleepDark      = Color(0xFF201328);

  // ── Common ───────────────────────────────────────────────────
  static const Color white          = Color(0xFFFFFFFF);
  static const Color black          = Color(0xFF000000);
  static const Color transparent    = Color(0x00000000);
  static const Color errorRed       = Color(0xFFE53935);
  static const Color successGreen   = Color(0xFF43A047);
  static const Color grey           = Color(0xFF9E9E9E);
}
