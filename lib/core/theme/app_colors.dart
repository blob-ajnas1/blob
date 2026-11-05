import 'package:flutter/material.dart';

/// BLOB design system.
///
/// The app ships two visually distinct experiences that share one layout
/// language: the agri marketplace (dark green, high contrast for outdoor
/// sunlight) and the education track (blue, calmer and study-oriented).
///
/// ## Why this is a mutable static, not a `Theme.of(context)` lookup
///
/// `AppColors.primary` is referenced ~190 times across 35 files, 63 of those
/// inside `const` constructors (`const BorderSide(color: AppColors.primary)`).
/// Converting every one to a context lookup would mean de-`const`ing large
/// widget subtrees — a sweeping, regression-prone edit for no user benefit.
///
/// Instead the brand colours stay compile-time-shaped but are re-pointed once
/// per session by [applyPalette], which the root widget calls before the first
/// build of a signed-in user. The values are read during `build`, so a
/// `setState`/rebuild after switching picks them up. Non-brand colours
/// (semantic status, text) are identical in both palettes and stay `const`.
class AppColors {
  AppColors._();

  // ---- Brand colours: re-pointed by [applyPalette] ----
  // Default to agri so pre-login screens (language, splash, OTP) have a hue
  // before any user exists to pick a track from.
  static Color primary = _agri.primary;
  static Color primaryDark = _agri.primaryDark;
  static Color primaryLight = _agri.primaryLight;
  static Color primarySoft = _agri.primarySoft;
  static Color background = _agri.background;
  static Color border = _agri.border;

  static const AppPalette _agri = AgriPalette();

  /// Points the brand colours at [palette]. Call before building signed-in UI.
  static void applyPalette(AppPalette palette) {
    primary = palette.primary;
    primaryDark = palette.primaryDark;
    primaryLight = palette.primaryLight;
    primarySoft = palette.primarySoft;
    background = palette.background;
    border = palette.border;
    success = palette.success;
  }

  /// Fixed logo colours, independent of the active marketplace/education palette.
  static const Color brandInk = Color(0xFF14301F);
  static const Color brandGreen = Color(0xFF1B8A3A);
  static const Color brandBlue = Color(0xFF1F6FD0);
  static const Color brandGold = Color(0xFFF2B705);
  static const Color brandCream = Color(0xFFFBF7EE);
  static const Color brandGreenOnDark = Color(0xFF43C463);
  static const Color brandBlueOnDark = Color(0xFF4DA3FF);

  /// Warm canvas used by the marketplace onboarding and buyer home.
  static const Color agriCream = Color(0xFFFBF8ED);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF11170F);
  static const Color textSecondary = Color(0xFF5C6B5E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Re-pointed per track by applyPalette, so completion chrome in the shared
  // learning screens follows the active app's brand instead of forcing green.
  static Color success = _agri.success;
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFB3261E);
  static const Color info = Color(0xFF1565C0);

  static const Color pending = Color(0xFFB26A00);
  static const Color pendingSoft = Color(0xFFFFF2DC);
  static const Color clearedSoft = Color(0xFFE6F0E7);
  static const Color dangerSoft = Color(0xFFFBE9E7);

  /// Learning module accents. Amber reads clearly against both the dark green
  /// and deep blue headers, where the primary colour would disappear.
  static const Color accent = Color(0xFFFFC107);
  static const Color accentSoft = Color(0xFFFFF7E0);
  static const Color streak = Color(0xFFE65100);
}

/// A brand colour set. Two exist: [AgriPalette] and [EduPalette].
///
/// Declared as `final` fields on a `const` constructor rather than statics, so
/// a palette can be passed around as a value (`const EduPalette()`) while still
/// being usable in constant expressions.
abstract class AppPalette {
  const AppPalette();

  Color get primary;
  Color get primaryDark;
  Color get primaryLight;
  Color get primarySoft;
  Color get background;
  Color get border;

  /// Completion / "done" chrome: progress bars, tick badges, finished cards.
  ///
  /// Track-scoped rather than a fixed green, because the shared learning
  /// screens (tasks, quiz) render in both apps. A fixed green put agri brand
  /// colour — literally the same 0xFF2E7D32 as [AgriPalette.primaryLight] —
  /// inside the blue student app, which is the cross-branding this split
  /// exists to prevent.
  Color get success;
}

/// Agri marketplace — dark green, chosen for legibility in direct sunlight.
class AgriPalette extends AppPalette {
  const AgriPalette();

  @override
  Color get primary => const Color(0xFF1B5E20);
  @override
  Color get primaryDark => const Color(0xFF0E3D13);
  @override
  Color get primaryLight => const Color(0xFF2E7D32);
  @override
  Color get primarySoft => const Color(0xFFE6F0E7);
  @override
  Color get background => const Color(0xFFF6F8F6);
  @override
  Color get border => const Color(0xFFD9E2DA);
  @override
  Color get success => const Color(0xFF2E7D32);
}

/// Education track — blue. Contrast ratios are held at the same level as the
/// green palette so nothing becomes harder to read after switching: primary
/// on white is 8.6:1 here versus 8.9:1 for green, both well past WCAG AA.
class EduPalette extends AppPalette {
  const EduPalette();

  @override
  Color get primary => const Color(0xFF12468F);
  @override
  Color get primaryDark => const Color(0xFF0A2C5C);
  @override
  Color get primaryLight => const Color(0xFF1E6BC8);
  @override
  Color get primarySoft => const Color(0xFFE4EDFA);
  @override
  Color get background => const Color(0xFFF5F7FB);
  @override
  Color get border => const Color(0xFFD5DEEC);
  // A blue-green teal: still reads as "done" without dragging agri green into
  // the education app.
  @override
  Color get success => const Color(0xFF0F7B6C);
}
