import 'package:flutter/painting.dart';

/// Colour tokens from DESIGN.md, one set per brightness. Read them through
/// `context.tokens.colors` or `Theme.of(context).colorScheme`, never directly
/// in widgets.
class AppColors {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.verified,
    required this.verifiedContainer,
    required this.error,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color verified;
  final Color verifiedContainer;
  final Color error;

  static const light = AppColors(
    primary: Color(0xFF1B2A4A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE4E9F2),
    onPrimaryContainer: Color(0xFF1B2A4A),
    accent: Color(0xFFC8A24A),
    onAccent: Color(0xFF1B2A4A),
    accentContainer: Color(0xFFF6EDD6),
    onAccentContainer: Color(0xFF5E4612),
    background: Color(0xFFF7F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEFEEE9),
    onSurface: Color(0xFF151C2B),
    onSurfaceVariant: Color(0xFF545C6B),
    outline: Color(0xFFD6D9DF),
    verified: Color(0xFF1E7A4F),
    verifiedContainer: Color(0xFFE3F2EA),
    error: Color(0xFFB3261E),
  );

  // DESIGN.md lists no dark on-primary-container; it reuses dark on-surface.
  static const dark = AppColors(
    primary: Color(0xFFAFC2EA),
    onPrimary: Color(0xFF0D1321),
    primaryContainer: Color(0xFF24345A),
    onPrimaryContainer: Color(0xFFE8EBF2),
    accent: Color(0xFFD9B65E),
    onAccent: Color(0xFF0D1321),
    accentContainer: Color(0xFF3A2F14),
    onAccentContainer: Color(0xFFF1DDA6),
    background: Color(0xFF0D1321),
    surface: Color(0xFF151D2E),
    surfaceVariant: Color(0xFF1E2840),
    onSurface: Color(0xFFE8EBF2),
    onSurfaceVariant: Color(0xFFA3ABBD),
    outline: Color(0xFF2E3A55),
    verified: Color(0xFF6FCF9C),
    verifiedContainer: Color(0xFF12301F),
    error: Color(0xFFF2B8B5),
  );
}
