import 'package:flutter/material.dart';

/// MEDIKU Design System - Color Tokens
///
/// Nature-inspired green palette optimized for healthcare app
/// WCAG 2.1 AA compliant for accessibility

class AppColors {
  AppColors._(); // Private constructor

  // ============================================
  // PRIMARY PALETTE
  // ============================================

  /// Primary: Dark Forest Green
  /// Use for: Main buttons, active nav, FAB, key CTAs, headings
  static const Color primary = Color(0xFF144425);

  /// Primary Light: Lighter Forest Green
  /// Use for: Ripple effects, secondary buttons, icon accents
  static const Color primaryLight = Color(0xFF1E6B38);

  /// Primary Surface: Light green tint
  /// Use for: Chip backgrounds, selected state backgrounds
  static const Color primarySurface = Color(0xFFE8F0EA);

  // ============================================
  // NEUTRAL PALETTE
  // ============================================

  /// Background: Off-white/cream
  /// Use for: Scaffold background on all screens
  static const Color background = Color(0xFFF7F9F7);

  /// Card: Pure white
  /// Use for: Card/Container fill with shadow
  static const Color card = Color(0xFFFFFFFF);

  /// Surface: Slightly darker than background
  /// Use for: Input fields, elevated surfaces
  static const Color surface = Color(0xFFF0F2F0);

  /// Divider: Subtle separator
  /// Use for: Dividers, input borders
  static const Color divider = Color(0xFFE8EDE9);

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Text Primary: Almost black with green tint
  /// Use for: All primary text, titles, metric values
  static const Color textPrimary = Color(0xFF0D1F14);

  /// Text Secondary: Muted green-grey
  /// Use for: Subtitles, labels, hints
  static const Color textSecondary = Color(0xFF6B7A70);

  /// Text On Primary: White
  /// Use for: Text/icons on dark green backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Status Red: Danger/Error
  /// Use for: Danger metrics (high blood pressure, errors)
  static const Color statusRed = Color(0xFFD94F4F);

  /// Status Amber: Warning
  /// Use for: Warning metrics (borderline cholesterol, etc.)
  static const Color statusAmber = Color(0xFFD97706);

  /// Status Green: Success/Normal
  /// Use for: Normal/healthy metrics
  static const Color statusGreen = Color(0xFF2D8653);

  // ============================================
  // DEPRECATED ALIASES (for backward compatibility)
  // These will be removed in future versions
  // ============================================

  /// @deprecated Use statusGreen instead
  static Color get success => statusGreen;

  /// @deprecated Use statusRed instead
  static Color get error => statusRed;

  /// @deprecated Use statusAmber instead
  static Color get warning => statusAmber;

  /// @deprecated Use primarySurface instead
  static Color get accent => primarySurface;

  /// @deprecated Use divider instead
  static Color get surfaceVariant => divider;

  /// @deprecated Use primary with opacity instead
  static Color get primary80 => const Color(0xCC144425);

  /// @deprecated Use textSecondary instead
  static Color get primary60 => textSecondary;

  /// @deprecated Use textSecondary with opacity instead
  static Color get primary40 => const Color(0x666B7A70);

  /// @deprecated Use divider instead
  static Color get primary20 => const Color(0x33E8EDE9);

  /// @deprecated Not used in new design system
  static Color get accent60 => const Color(0x99E8F0EA);

  /// @deprecated Use primarySurface with opacity instead
  static Color get accent40 => const Color(0x66E8F0EA);

  /// @deprecated Use primarySurface with opacity instead
  static Color get accent20 => const Color(0x33E8F0EA);

  /// @deprecated Not used in new design system
  static Color get secondary => const Color(0xFF6FA9BB);

  /// @deprecated Not used in new design system
  static Color get secondary60 => const Color(0x996FA9BB);

  /// @deprecated Not used in new design system
  static Color get secondary40 => const Color(0x666FA9BB);

  /// @deprecated Not used in new design system
  static Color get secondary20 => const Color(0x336FA9BB);

  /// @deprecated Use statusRed instead
  static Color get errorLight => const Color(0xFFEF5350);

  /// @deprecated Use textSecondary instead
  static Color get textHint => textSecondary;

  /// @deprecated Use divider instead
  static Color get border => divider;

  /// @deprecated Use divider instead
  static Color get borderFocused => primary;

  /// @deprecated Use textSecondary instead
  static Color get textDisabled => textSecondary;
}
