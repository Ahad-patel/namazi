import 'package:flutter/material.dart';

import '../../domain/entities/prayer.dart';

/// `h:mm` with a smaller AM/PM, or `HH:mm`, following the device setting.
class TimeText extends StatelessWidget {
  const TimeText(this.time, {super.key, this.style, this.color});

  final ClockTime time;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
    );
    final mm = time.minute.toString().padLeft(2, '0');
    if (MediaQuery.alwaysUse24HourFormatOf(context)) {
      return Text('${time.hour.toString().padLeft(2, '0')}:$mm', style: base);
    }
    final loc = MaterialLocalizations.of(context);
    final h12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final suffix = time.hour < 12
        ? loc.anteMeridiemAbbreviation
        : loc.postMeridiemAbbreviation;
    return Text.rich(
      TextSpan(
        text: '$h12:$mm',
        children: [
          TextSpan(
            text: ' $suffix',
            style: TextStyle(fontSize: (base.fontSize ?? 14) * 0.6),
          ),
        ],
      ),
      style: base,
    );
  }
}
