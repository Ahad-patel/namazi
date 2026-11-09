import 'package:flutter/foundation.dart';

import '../config/env.dart';

enum LegalPage {
  privacy('privacy'),
  terms('terms'),
  deleteAccount('delete-account');

  const LegalPage(this.file);
  final String file;
}

/// `/privacy.html`, `/terms.html` or `/delete-account.html` on the website. Null on mobile when
/// `SITE_URL` is not set yet (the caller hides the link).
Uri? legalUri(LegalPage page, {String siteUrl = Env.siteUrl}) {
  final path = '/${page.file}.html';
  if (siteUrl.isNotEmpty) return Uri.parse(siteUrl).resolve(path);
  if (kIsWeb) return Uri.base.resolve(path);
  return null;
}
