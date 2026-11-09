import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// `version+build` and, on a Shorebird-patched Android build, the patch
/// number, so a bug report names the exact code that ran.
Future<({String build, int? patch})> appVersion() async {
  final info = await PackageInfo.fromPlatform();
  final build = '${info.version}+${info.buildNumber}';
  final updater = ShorebirdUpdater();
  if (!updater.isAvailable) return (build: build, patch: null);
  final patch = await updater.readCurrentPatch().then<Patch?>(
    (p) => p,
    // The version line still shows without the patch; log why.
    onError: (Object e) {
      debugPrint('Shorebird readCurrentPatch failed: $e');
      return null;
    },
  );
  return (build: build, patch: patch?.number);
}
