import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';
import '../utils/legal.dart';
import '../../l10n/gen/app_localizations.dart';

/// "Terms" · "Privacy Policy" links. Hidden on mobile until SITE_URL is set.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.siteUrl = Env.siteUrl});

  final String siteUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final terms = legalUri(LegalPage.terms, siteUrl: siteUrl);
    final privacy = legalUri(LegalPage.privacy, siteUrl: siteUrl);
    if (terms == null || privacy == null) return const SizedBox.shrink();
    return Wrap(
      children: [
        TextButton(onPressed: () => launchUrl(terms), child: Text(l10n.terms)),
        TextButton(
          onPressed: () => launchUrl(privacy),
          child: Text(l10n.privacyPolicy),
        ),
      ],
    );
  }
}
