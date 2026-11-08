import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Design tokens that ColorScheme/TextTheme don't cover (accent, verified,
/// time and script styles). Read with `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens(this.colors);

  final AppColors colors;

  TextStyle get timeLg => AppTypography.timeLg;
  TextStyle get time => AppTypography.time;
  TextStyle get caption => AppTypography.caption;
  TextStyle get label => AppTypography.label;
  TextStyle get nameArabic => AppTypography.nameArabic;
  TextStyle get nameUrdu => AppTypography.nameUrdu;

  @override
  AppTokens copyWith({AppColors? colors}) => AppTokens(colors ?? this.colors);

  @override
  AppTokens lerp(AppTokens? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
