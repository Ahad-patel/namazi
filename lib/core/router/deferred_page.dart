import 'package:flutter/material.dart';

import '../error/failures.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Shows [builder] once [load] (a `deferred as` library's `loadLibrary`)
/// completes, so the web build only downloads admin code when it's opened.
class DeferredPage extends StatelessWidget {
  DeferredPage({
    super.key,
    required Future<void> Function() load,
    required this.builder,
  }) : _loaded = load();

  final Future<void> _loaded;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loaded,
    builder: (context, snap) => switch (snap) {
      AsyncSnapshot(hasError: true, :final error) => Scaffold(
        appBar: AppBar(),
        body: Center(child: ErrorView(failure: NetworkFailure('$error'))),
      ),
      AsyncSnapshot(connectionState: ConnectionState.done) => builder(),
      _ => const Scaffold(body: LoadingView(shape: SkeletonShape.row)),
    },
  );
}
