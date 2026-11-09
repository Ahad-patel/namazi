import 'package:flutter/foundation.dart';

import '../config/env.dart';

enum LegalPage { privacy, terms }

/// `/privacy.html` or `/terms.html` on the website. Null on mobile when
/// `SITE_URL` is not set yet (the caller hides the link).
Uri? legalUri(LegalPage page, {String siteUrl = Env.siteUrl}) {
  final path = '/${page.name}.html';
  if (siteUrl.isNotEmpty) return Uri.parse(siteUrl).resolve(path);
  if (kIsWeb) return Uri.base.resolve(path);
  return null;
}
