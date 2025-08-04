# neom_commons
Commons for Open Neom Modules.

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
Add neom_commons as a Git dependency in your pubspec.yaml file:

dependencies:
    neom_commons:
        git:
            url: https://github.com/Open-Neom/neom_commons.git

Then, run flutter pub get in your project's root directory.

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