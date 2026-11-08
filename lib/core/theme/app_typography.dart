import 'package:flutter/painting.dart';

/// DESIGN.md typography. The bundled fonts are variable (wght axis), so every
/// style sets both [FontWeight] and the matching [FontVariation].
class AppTypography {
  const AppTypography._();

  static const latin = 'Manrope';
  static const arabic = 'NotoNaskhArabic';
  static const urdu = 'NotoNastaliqUrdu';

  static TextStyle _style(
    String family,
    double size,
    int weight,
    double height, {
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation.weight(weight.toDouble())],
    height: height,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  static final display = _style(latin, 32, 800, 1.15);
  static final headline = _style(latin, 24, 700, 1.2);
  static final title = _style(latin, 18, 700, 1.3);
  static final body = _style(latin, 15, 500, 1.5);
  static final label = _style(latin, 13, 600, 1.3);
  static final caption = _style(latin, 12, 500, 1.35);
  static final timeLg = _style(latin, 28, 800, 1.1, tabular: true);
  static final time = _style(latin, 17, 700, 1.2, tabular: true);
  static final nameArabic = _style(arabic, 18, 600, 1.6);
  static final nameUrdu = _style(urdu, 17, 600, 2.0);
}
