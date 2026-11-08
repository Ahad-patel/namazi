import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds only itself, once per minute (aligned so the rounded-up minute
/// changes exactly on time), and calls [onPassed] when [target] is reached.
class Countdown extends StatefulWidget {
  const Countdown({
    super.key,
    required this.target,
    required this.builder,
    this.onPassed,
    this.clock = DateTime.now,
  });

  final DateTime target;
  final Widget Function(BuildContext context, Duration left) builder;
  final VoidCallback? onPassed;
  final DateTime Function() clock;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _tick;
  Timer? _end;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(Countdown old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) _schedule();
  }

  void _schedule() {
    _tick?.cancel();
    _end?.cancel();
    final left = widget.target.difference(widget.clock());
    if (left <= Duration.zero) return;
    _end = Timer(left, () {
      _tick?.cancel();
      widget.onPassed?.call();
      if (mounted) setState(() {});
    });
    final toNextMinute = Duration(
      microseconds: left.inMicroseconds % Duration.microsecondsPerMinute,
    );
    _tick = Timer(toNextMinute, () {
      if (mounted) setState(() {});
      _tick = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _end?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.target.difference(widget.clock());
    return widget.builder(context, left.isNegative ? Duration.zero : left);
  }
}
