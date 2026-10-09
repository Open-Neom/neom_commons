# neom_commons
Commons for Open Neom Modules.

## Public privacy policy pages

For the complete public legal site (privacy, account deletion and terms), use
[`tool/legal/generate.mjs`](tool/legal/generate.mjs). See the [shared legal-page
guide](tool/legal/README.md) for sources, host-app setup and validation. The
privacy-only entrypoint below remains backwards compatible.

The renderer in `tool/privacy/generate.mjs` is shared by all host apps. Each app
maintains **one** `assets/privacy_policy.md` for its actual data practices and
`assets/privacy_policy.json` for public identity and publication status, not a separate
policy for Android, iOS and web. Existing mobile/web privacy links open the same
public `/politica-de-privacidad/` URL.

The generator reads only the public app name, contact and website/privacy URL
fields from `assets/properties.json` (the same source as `AppProperties`). It
never embeds that configuration file wholesale. Legal metadata can override the
privacy contact. The result is static, responsive HTML: no Flutter bootstrap,
authentication, scripts, third-party fonts or runtime Markdown fetch is needed.

From an app directory in this workspace:

```sh
node ../neom_modules/main/neom_commons/tool/privacy/generate.mjs --app-dir . --require-published
flutter build web --release --no-tree-shake-icons
node ../neom_modules/main/neom_commons/tool/privacy/generate.mjs --app-dir . --output-dir build/web --check --require-published
```

The output `web/politica-de-privacidad/index.html` is generated; edit the Markdown,
metadata or shared template instead. Flutter copies the page to `build/web`.
`--check` detects stale output without writing. `--require-published` accepts
`published` or `approved` and rejects drafts. The three apps' deploy scripts use
this publication check before building and verify the built page afterward.
`--require-approved` remains a separate, stricter check and rejects `published`.
A bare Firebase command or
unrelated CI workflow does not automatically run those scripts: the same check
must be included if another publication path is used. Generation is local and
does not deploy anything.

Metadata fields: `status` (`draft`, `published` or `approved`), `updatedAt` (ISO date),
`controllerName`, `controllerAddress`, `privacyEmail`, `themeColor` (six-digit
hex color). A `draft` has a visible notice and `noindex`. `published` records the
owner's publication decision; it requires a responsible name, privacy contact,
HTTPS canonical URL and public text without pending markers or unresolved
placeholders. It does not require a physical address or certify legal approval.
`approved` retains the stricter requirement for a physical address and complete
legal metadata, no pending markers, and no outstanding legacy review notes.
Approval requires the corresponding human/legal and operational review; the
generator does not perform or certify it. Both `published` and `approved` render
without a draft notice or `noindex`.

`reviewNotes` is optional legacy input and is never serialized into HTML,
including in a draft. Do not keep internal notes in `assets/privacy_policy.json`:
Flutter can bundle that JSON independently of the HTML generator. Store them
locally in `legal/privacy_policy.review.json`, outside Flutter assets and ignored
by Git. Both Hosting configurations must exclude `**/privacy_policy.review.json`.
The local review file is optional and is not required in a fresh clone.

Simple Markdown headings, paragraphs, bold, lists and links
are supported; raw HTML is escaped and unsafe URL schemes are rejected.

For another app, add both assets (explicitly in `pubspec.yaml` if needed), set its
public properties, generate the page and add the Hosting route before the SPA
fallback. No application-specific changes to the renderer are required. If a
build switches flavors, its assets must belong to the selected app; never ship a
different app's legal identity or practices.

### Source review for the October 2026 migration

The recovered sources were `SRZNVRSE/Gigmeout/Archivo/Secure/IT/Politica de
Privacidad.doc` (Word-generated HTML saved in 2021) and
`SRZNVRSE/EMXI/EMXI Cloud/Drive-2026-Soporte/IT/EscritoresMXI - Política de
privacidad.docx`. The originals were left unchanged. No separate historical
Cyberneom privacy policy was found in that archive search.

The old documents describe a website/WordPress on SiteGround, not the current
apps. The migration retains useful concepts (purposes, third-party services,
control of personal information and no-sale commitments), but replaces obsolete
domains and WordPress account/export/erasure instructions. Unsupported promises
of perfect security, automatic permanent deletion, a three-year purge or
indefinite retention were not carried over. The policy sources cover Firebase,
files and notifications, permissions, diagnostics, payments and conditional AI;
Gigmeout covers Giglab, EMXI covers reading activity, and Cyberneom distinguishes
local EEG/voice results from cloud session history. AdMob is described only for
apps whose code enables the module, not inferred from a shared dependency.

The former privacy paragraphs inside each app's terms were aligned to avoid
contradictory statements such as “all biofeedback is local” or “profiles are used
only for statistics.” On October 4, the owner supplied the responsible names
Gigmeout, EMXI and Cyberneom and the privacy contacts `contacto@gigmeout.com`,
`contacto@emxi.org` and `contacto@cyberneom.xyz`. These are shown as electronic
contacts, not physical addresses. No physical address was supplied:
`controllerAddress` is omitted from public metadata and the stricter approval
gate remains in place. The owner authorized `published` policies for the public
sites without claiming that they were legally approved.
The public Markdown omits the physical-address line at the owner's request;
legal review must resolve that requirement and restore `{{CONTROLLER_ADDRESS}}`
where applicable before approving the notice. This does not imply that an email
replaces the domicile required by Mexico's LFPDPPP, article 15.

Operational review details belong in the optional local review files, not the
public metadata or generated pages. The client account-deletion action is not evidence of a
complete cascade through files, posts, sessions, projects and assistant memory.

Publication also requires matching the store's Data safety declaration and
updating its privacy URL; those external changes are separate from generating
the page. See [Google Play user data requirements](https://support.google.com/googleplay/android-developer/answer/10144311?hl=es)
and [Mexico's LFPDPPP](https://www.diputados.gob.mx/LeyesBiblio/pdf/LFPDPPP.pdf).

Run shared renderer tests with `node --test tool/privacy/generate.test.mjs`.

Local Hosting verification (no deployment): after building the app, run
`node tool/privacy/preview.mjs --app-dir /path/to/Gigmeout --port 5400` from this
module. The helper uses a temporary config, a demo project and loopback only;
Firebase CLI must be available on `PATH`. Stop it with Ctrl+C. To verify all
three apps' routes and generated artifacts, run:

```sh
NEOM_PRIVACY_APPS_ROOT=/path/to/codebase_flutter \
PRIVACY_GIGMEOUT_URL=http://127.0.0.1:5400 \
PRIVACY_EMXI_URL=http://127.0.0.1:5410 \
PRIVACY_CYBERNEOM_URL=http://127.0.0.1:5420 \
node --test tool/privacy/*.test.mjs
```

Start one preview per app on those ports; HTTP checks are skipped when the
corresponding URL is omitted. These checks require local URLs and never create
accounts or write production data.

neom_commons serves as a vital support package within the Open Neom ecosystem. 
It is meticulously designed to house all reusable widgets, shared UI components,
and generic utility functions that are transversal to the application. 
This module ensures consistency in design and functionality across the entire Open Neom platform,
promoting a clean, modular, and maintainable codebase.

🌟 Features & Responsibilities
neom_commons is the central repository for shared elements, responsible for:
•	Reusable UI Widgets: Providing a library of common Flutter widgets that can be used across various modules,
    ensuring a consistent user experience and reducing code duplication. This includes custom image loaders,
    progress indicators, buttons, and more.
•	Shared UI Components: Defining common UI patterns and theming elements (like AppColor, AppTheme) 
    that establish the visual identity of the Open Neom application.
•	Generic Utility Functions: Offering a collection of helper functions and classes that perform common tasks
    across different domains, such as text manipulation (TextUtilities), URL handling (UrlUtilities),
    date/time formatting (DateTimeUtilities), and file operations (FileUtilities).
•   Universal Constants & Enums: Housing application-wide constants (e.g., AppConstants, AppAssets, AppPageIdConstants,
    AppHiveConstants) and generic enums (e.g., AppLocale, MediaType) that are used by multiple modules.
•   Common Service Interfaces: Potentially defining highly generic service interfaces (e.g., CommonTranslationConstants)
    that are implemented by specific modules, adhering to the Dependency Inversion Principle.
•	External Utility Integrations: Encapsulating common integrations with third-party utility packages 
    (e.g., intl, share_plus, flutter_linkify) that are widely used across the application.

🏗️ Architectural Enhancements
Recent architectural enhancements in neom_commons focus on improving modularity,
decoupling, and customization capabilities across the Open Neom ecosystem:

•	Translation Constants Modularization:
    -   The monolithic AppTranslationConstants has been refactored.
    neom_commons now introduces CoreTranslationConstants for universal UI keys
    and refines CommonTranslationConstants for cross-domain business keys.
    -   This ensures that module-specific translation keys reside in their respective modules,
    while actual translated values are managed by the main application (neom_app) based on its flavor,
    allowing for flexible customization.

•	AppUtilities Granularization:
    -   The broad AppUtilities class has been decomposed into more granular, single-responsibility utility classes
    (e.g., AppLocaleUtilities, DateTimeUtilities, TextUtilities, UrlUtilities, FileUtilities, ShareUtilities).
    This enhances code organization, reusability, and testability.

•	AppFlavour Integration:
    -   AppFlavour has been established as a central mechanism within neom_commons to provide application-specific
    customizations. This allows for dynamic adaptation of UI elements (e.g., icons, text strings, asset paths)
    and behavioral logic based on the active application flavor (AppInUse enum from neom_core).
    This ensures a consistent yet customizable experience across different versions or brands of the Neom application.

📦 Installation
Add neom_commons to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  neom_commons: ^2.0.0
```

Then, run `flutter pub get` in your project's root directory.

🚀 Usage
neom_commons is primarily consumed by other domain-specific Neom modules (e.g., neom_auth, neom_home, neom_posts)
and the main application (neom_app). It provides the building blocks and helper functions for these modules.

Example of using a common UI widget:

// In a widget from another module (e.g., neom_posts)
import 'package:flutter/material.dart';
import 'package:neom_commons/commons/ui/widgets/app_circular_progress_indicator.dart'; // Import from neom_commons

class MyLoadingScreen extends StatelessWidget {
    const MyLoadingScreen({Key? key}) : super(key: key);
    
    @override
    Widget build(BuildContext context) {
        return const Center(
            child: AppCircularProgressIndicator(), // Reusable loading indicator
        );
    }
}

Example of using a common utility:

// In a controller from another module (e.g., neom_posts)
import 'package:neom_commons/commons/utils/text_utilities.dart'; // Import from neom_commons

void formatText() {
    String originalText = "hello world";
    String capitalizedText = TextUtilities.capitalizeFirstLetter(originalText);
    print(capitalizedText); // Output: Hello world
}

🛠️ Dependencies
neom_commons relies on the following key packages to provide its functionalities:
•   flutter: The Flutter SDK.
•	neom_core: For core models and utilities.
•	UI & Styling: font_awesome_flutter, lucide_icons_flutter, cached_network_image, readmore, animated_text_kit,
    carousel_slider, flutter_slider_indicator, rubber.
•   Utilities: intl, get_time_ago, flutter_rating_bar, flutter_linkify, hashtagable_v3, intl_phone_field, share_plus, crypto.
•   Web Integration: webview_flutter.

🤝 Contributing
We welcome contributions to neom_commons! Please refer to the main Open Neom repository
for detailed contribution guidelines and code of conduct.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
