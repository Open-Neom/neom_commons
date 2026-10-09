# Shared public legal pages

Use one set of Markdown files per host app for web, Android, iOS and desktop.
The shared renderer supplies layout and safe substitutions, not legal advice or
a universal set of business terms. Content must reflect each app's real services.

| Public path | Host app source |
| --- | --- |
| `/politica-de-privacidad/` | `assets/privacy_policy.md` |
| `/eliminar-cuenta/` | `assets/legal/account_deletion.md` |
| `/terminos-y-condiciones/` | `assets/legal/terms_conditions.md` |

The three pages use the existing public metadata in `assets/privacy_policy.json`:
`status`, `updatedAt`, `controllerName`, optional `controllerAddress`,
`privacyEmail` and `themeColor`. When changing any legal document, review the
shared revision date. `published` is a publication state, **not** legal approval,
Google Play acceptance, or proof that the described process has been implemented.
`approved` and `--require-approved` remain the stricter, human-reviewed gate.
Internal review notes belong outside `assets/` and are never rendered.

Only `appName`, `contactEmail`, `siteUrl` and `privacyPolicyUrl` are read from
`assets/properties.json`. A valid HTTPS `privacyPolicyUrl` ending in
`/politica-de-privacidad/` supplies the canonical origin; otherwise `siteUrl` is
used. Old terms URLs cannot change the new route or mix branding. The generator
never serializes the properties file into HTML.

Supported Markdown placeholders:

- `{{APP_NAME}}`, `{{CONTROLLER_NAME}}`, `{{CONTACT_EMAIL}}`
- `{{SITE_URL}}`, `{{PRIVACY_URL}}`, `{{TERMS_URL}}`, `{{ACCOUNT_DELETION_URL}}`
- `{{UPDATED_AT}}`, optional `{{CONTROLLER_ADDRESS}}`

`CONTACT_EMAIL` uses the metadata privacy mailbox, falling back to the public
contact only for a draft. Sources support an optional leading `#` title (the
HTML shell supplies the displayed page title), `##` / `###` headings, paragraphs,
numbered and bulleted lists, bold and HTTP(S), mailto or local-anchor links.
Raw HTML is escaped; unknown tokens and unsafe link schemes fail generation.
Every source is validated before any of the three output files is written.

## Generate and verify (no deployment)

From a host app directory:

```sh
node ../neom_modules/main/neom_commons/tool/legal/generate.mjs --app-dir . --require-published
node ../neom_modules/main/neom_commons/tool/legal/generate.mjs --app-dir . --check --require-published
```

After `flutter build web`, verify the copied output:

```sh
node ../neom_modules/main/neom_commons/tool/legal/generate.mjs --app-dir . --output-dir build/web --check --require-published
```

The existing `tool/privacy/generate.mjs` CLI is retained for privacy-only callers;
new deployments should use the legal generator to avoid stale sibling pages.
Generated files live under `web/<route>/index.html`; do not edit them manually.
The app must list both `assets/` and `assets/legal/` in `pubspec.yaml`, because
Flutter does not recursively bundle nested asset directories.

Both Hosting entrypoints must keep exact no-slash redirects, explicit legal
rewrites before the SPA fallback, HTML/no-cache headers, and internal-file
exclusions. `/terminos-de-servicio` is a legacy redirect; `/terms` remains the
Flutter route. Generating a file does not publish it or change Play Console.

## In-app rendering

`LegalPage` in `lib/ui/legal_page.dart` loads the same host Markdown assets.
`TermsConditionsPage` remains compatible with existing callers; the new
`AccountDeletionPage` displays instructions, not a destructive action.
`CommonRoutes` includes the new paths with and without the trailing slash.
Apps with their own guest allowlist must allow these exact informational routes,
without allowing authenticated account-removal actions or arbitrary subpaths.

Public identity, contact, revision date and theme come from the existing metadata;
the brand name and canonical site use the host's public app properties. No
hard-coded registry of apps or contacts is needed. An older host without the
metadata file can use its public properties as a fallback. The documents are
currently Spanish; adding another UI language does not translate legal content.

## Local HTTP preview

Generate the pages, then run from the host app directory:

```sh
node ../neom_modules/main/neom_commons/tool/privacy/preview.mjs --app-dir . --port 5450 --source-web
```

This serves only local generated source pages through the Hosting emulator with
a `demo-*` project on loopback. It does not build Flutter, deploy, or use a real
Firebase project. Without `--source-web`, the preview uses `build/web` instead;
that directory must have been rebuilt after changing the source pages or assets.

## Deletion page behavior

This is a public **request and instruction page**, not an account-deletion API.
It is usable without authentication or JavaScript. The mailto link opens a mail
client: the user must send the message, and can copy the visible mailbox if no
client is configured. No account information is submitted by merely visiting.

Do not promise automatic deletion, a fixed 90-day schedule, or complete cascade
cleanup unless the actual backend and operations implement them. The existing
account removal flow does not establish complete removal of posts, files,
projects, messages or assistant memory. Requests require a monitored mailbox,
identity verification proportional to the request, actual processing and an
appropriate confirmation. Retention reasons and applicable periods must be
defined by the responsible operator; a page alone does not solve this obligation.

## Sources and scope of the 2026-10-04 adaptation

Historical SRZNVRSE references reviewed without modifying them:

- Gigmeout: `Legal/TÉRMINOS DE SERVICIO - Gigmeout 2024.docx` and the historical
  privacy document in `Archivo/Secure/IT/Politica de Privacidad.doc`.
- EMXI: `Archivo/Docs Por ordenar/ACUERDO DE TÉRMINOS Y CONDICIONES - V1.docx`
  and the EscritoresMXI privacy document under `EMXI Cloud/Drive-2026-Soporte/IT`.
- Cyberneom: the existing app terms; no separate historical terms or deletion
  instructions were located in the targeted archive search.

Retained relevant ownership, conduct, moderation and account-security concepts.
Did not carry forward obsolete domains, third-party integration promises,
historical subscription prices/refund rules, broad indemnities, absolute
security promises, or unverified retention/deletion deadlines. No private
contracts, financial details or infrastructure secrets belong in public assets.

External references: [Google Play account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=es)
and [user-generated content](https://support.google.com/googleplay/android-developer/answer/9876937?hl=es).
Publication still requires matching declarations, working operational processes
and appropriate legal review; this tool does not certify compliance.

## Tests

```sh
node --test tool/privacy/generate.test.mjs tool/legal/generate.test.mjs
NEOM_LEGAL_APPS_ROOT=/path/to/codebase_flutter node --test tool/legal/hosting.test.mjs tool/legal/public_pages.test.mjs
```

For HTTP checks, also set `LEGAL_GIGMEOUT_URL`, `LEGAL_EMXI_URL` and
`LEGAL_CYBERNEOM_URL` to the corresponding loopback preview URLs. Tests reject
production hosts. Widget tests live in `test/ui/legal_page_test.dart`; EMXI's
guest-route regression tests remain in the host app.

No tests create accounts, delete user data or deploy to Firebase.
