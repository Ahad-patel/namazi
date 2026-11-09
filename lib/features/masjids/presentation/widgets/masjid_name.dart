import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/masjid.dart';

final _arabicRange = RegExp('[؀-ۿ]');

/// Latin name as the title; the local-script name (if any) as an RTL second
/// line in its own font. Two lines max, then an ellipsis.
class MasjidName extends StatelessWidget {
  const MasjidName(this.masjid, {super.key, this.style, this.color});

  final Masjid masjid;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final base = (style ?? Theme.of(context).textTheme.titleMedium)!.copyWith(
      color: color,
    );
    final local = masjid.nameLocal;
    final nameIsScript = _arabicRange.hasMatch(masjid.name);
    final title = Text(
      masjid.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: nameIsScript ? _scriptStyle(tokens, null).merge(base) : base,
      textDirection: nameIsScript ? TextDirection.rtl : null,
    );
    if (local == null || local.isEmpty) return title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            local,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: _scriptStyle(
              tokens,
              masjid.nameScript,
            ).copyWith(color: color ?? base.color),
          ),
        ),
      ],
    );
  }

  static TextStyle _scriptStyle(AppTokens t, NameScript? script) =>
      script == NameScript.arab ? t.nameArabic : t.nameUrdu;
}
