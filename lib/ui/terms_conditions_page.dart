import 'package:flutter/material.dart';

import 'legal_page.dart';

/// Kept for existing callers and the `/terms` route.
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const LegalPage(document: LegalDocument.terms);
}

/// Instructions for requesting deletion, not the authenticated delete action.
class AccountDeletionPage extends StatelessWidget {
  const AccountDeletionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const LegalPage(document: LegalDocument.accountDeletion);
}
