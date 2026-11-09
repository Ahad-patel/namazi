import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/core/theme/app_colors.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$name contrast >= 4.5', () {
      final pairs = {
        'on-surface/surface': (c.onSurface, c.surface),
        'on-surface/background': (c.onSurface, c.background),
        'on-surface-variant/surface': (c.onSurfaceVariant, c.surface),
        'on-surface-variant/background': (c.onSurfaceVariant, c.background),
        'on-primary/primary': (c.onPrimary, c.primary),
        'on-primary-container/primary-container': (
          c.onPrimaryContainer,
          c.primaryContainer,
        ),
        'on-accent/accent': (c.onAccent, c.accent),
        'on-accent-container/accent-container': (
          c.onAccentContainer,
          c.accentContainer,
        ),
        'verified/verified-container': (c.verified, c.verifiedContainer),
        'error/surface': (c.error, c.surface),
        'surface/error (env strip)': (c.surface, c.error),
        'on-surface/surface-variant (offline banner)': (
          c.onSurface,
          c.surfaceVariant,
        ),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () => expect(contrast(fg, bg), greaterThanOrEqualTo(4.5)));
      }
    });
  }
}
