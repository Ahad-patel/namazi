import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Hands [text] to the user as a file named [name]: the share sheet on
/// mobile, a browser download on web (share_plus falls back to a download
/// when the Web Share API can't take files).
Future<void> shareTextFile(
  String name,
  String text, {
  String mime = 'application/json',
}) => SharePlus.instance.share(
  ShareParams(
    files: [XFile.fromData(utf8.encode(text), mimeType: mime, name: name)],
    fileNameOverrides: [name],
  ),
);
