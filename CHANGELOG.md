## 1.4.1-dev - Publishing to pub.dev

## 1.4.0-dev - Architectural Changes and Refactoring:

Translation Constants Modularization:

AppTranslationConstants (Deprecated/Refactored): The monolithic AppTranslationConstants class has been refactored and its content distributed across the ecosystem.

CoreTranslationConstants (New): Introduced in neom_commons to house truly universal and UI-agnostic translation keys (e.g., "yes", "no", "error", "cancel", basic verbs, common UI elements). This serves as the most fundamental layer of translation keys.

CommonTranslationConstants (Refined): This class now specifically contains translation keys for concepts common across multiple business domains within the Neom application, but which are not as universally generic as CoreTranslationConstants (e.g., application-specific slogans, names of subscription plans, general user/profile terms, cross-module payment/subscription terms).

Module-Specific Translation Constants: All domain-specific translation keys have been moved to their respective modules (e.g., neom_events/events/utils/constants/event_translation_constants.dart, neom_posts/posts/utils/constants/post_translation_constants.dart). This significantly reduces coupling and improves clarity.

Flavor-Aware Translation Values: The actual translated strings (values) for all keys now reside exclusively within the main application's localization folder (e.g., neom_app/localization/app_es_translations.dart). This allows for easy customization and overriding of translation values per application flavor without modifying shared module packages.

AppUtilities Granularization:

The monolithic AppUtilities class has been decomposed into more granular, single-responsibility utility classes, improving code organization and reusability. This includes:

AppLocaleUtilities (for locale-related operations).

CollectionUtilities (for list/map manipulations).

DateTimeUtilities (for date and time formatting).

DeviceUtilities (for device-specific information).

ExternalUtilities (for launching URLs, external apps).

FileSystemUtilities (for file system operations).

SecurityUtilities (for security-related helpers).

ShareUtilities (for sharing content).

TextUtilities (for text formatting and manipulation).

UrlUtilities (for URL parsing and handling).

This separation ensures that each utility class is focused on a single concern, making the codebase easier to navigate, test, and maintain.

AppFlavour Integration:

AppFlavour has been established as a central mechanism within neom_commons to provide application-specific customizations (e.g., icons, text, routing, asset paths) based on the active application flavor (AppInUse enum from neom_core). This allows for dynamic adaptation of UI and behavior without hardcoding flavor-specific logic in individual modules.

Performance and Maintainability Improvements:

Reduced Bundle Size: By distributing translation keys and granularizing utilities, modules only import what they strictly need, leading to a leaner dependency graph and a smaller overall application bundle.

Faster Compilation Speed: Smaller, more focused files and reduced cross-module dependencies contribute to quicker compilation times.

Enhanced Clarity and Decoupling: The codebase is now significantly more organized, with clearer responsibilities for each utility and constant. This improves readability, testability, and long-term maintainability, facilitating open collaboration.