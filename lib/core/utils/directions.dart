import 'package:flutter/foundation.dart';

/// Opens the platform maps app with directions to the point.
Uri directionsUri(double lat, double lng, TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
    ? Uri.https('maps.apple.com', '/', {'daddr': '$lat,$lng'})
    : Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lng',
      });
