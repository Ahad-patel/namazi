import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  /// Emits `true` when online, `false` when offline.
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map((r) => !r.every((c) => c == ConnectivityResult.none))
      .distinct();
}
