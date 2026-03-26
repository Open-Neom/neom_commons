// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final Set<String> _registeredFactories = {};

/// Optimizes Google user content image URLs for web by appending size parameter.
/// Reduces bandwidth and avoids HTTP 429 rate limits from Google's CDN.
String _optimizeGoogleUrl(String url) {
  if (url.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (!uri.host.contains('googleusercontent.com')) return url;
  if (url.contains(RegExp(r'=s\d+'))) return url;
  return '$url=s96';
}

/// Builds a native HTML <img> element via HtmlElementView.
/// This bypasses CanvasKit's CORS requirement for cross-origin images.
/// Includes error handling: on load failure, hides the broken image icon
/// and sets a neutral background so Flutter's placeholder/error widget shows through.
Widget buildWebNativeImage({
  required String imageUrl,
  BoxFit fit = BoxFit.cover,
  double? height,
  double? width,
  Widget? placeholder,
  Widget? errorWidget,
  bool circular = false,
}) {
  if (imageUrl.isEmpty || imageUrl == 'null') {
    return errorWidget ?? const SizedBox.shrink();
  }

  final optimizedUrl = _optimizeGoogleUrl(imageUrl);
  final suffix = circular ? '-circle' : '';
  final viewType = 'web-img$suffix-${optimizedUrl.hashCode}';

  if (!_registeredFactories.contains(viewType)) {
    _registeredFactories.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = optimizedUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = _boxFitToCss(fit)
          ..style.display = 'block'
          ..style.pointerEvents = 'none';

        if (circular) {
          img.style.borderRadius = '50%';
        }

        // On error (429, 404, CORS, etc.), hide the broken image icon
        // and show a neutral background instead.
        img.onError.listen((_) {
          img.style.display = 'none';
        });

        return img;
      },
    );
  }

  final Widget imageView = HtmlElementView(viewType: viewType);

  // When BOTH explicit dimensions are provided, use SizedBox to constrain.
  if (height != null && width != null) {
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        children: [
          Positioned.fill(child: imageView),
          Positioned.fill(child: ColoredBox(color: const Color(0x00000000))),
        ],
      ),
    );
  }
  // When only one dimension is provided, fall through to LayoutBuilder
  // which handles unbounded constraints safely.

  // ⚠️ DO NOT CHANGE THIS TO AspectRatio OR any other constrained wrapper.
  // SizedBox.expand is REQUIRED so the HTML <img> fills its parent constraints
  // (e.g. Stack/Positioned.fill in Librinder cards, profile covers, etc.).
  // The CSS object-fit:cover handles scaling. If you wrap in AspectRatio,
  // images won't cover full-bleed containers on web. — 2026-03-23
  //
  // HtmlElementView absorbs pointer events even with CSS pointerEvents:none.
  // The transparent overlay lets parent GestureDetectors receive taps.
  // Wrap in LayoutBuilder to get parent constraints.
  // If parent provides finite constraints, expand to fill.
  // If parent is unbounded (ListView/Column), use a default size.
  return LayoutBuilder(
    builder: (context, constraints) {
      final hasFiniteSize = constraints.hasBoundedHeight && constraints.hasBoundedWidth;
      final effectiveWidth = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 300.0);
      final effectiveHeight = height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : 200.0);
      final child = Stack(
        children: [
          if (hasFiniteSize && width == null && height == null)
            SizedBox.expand(child: imageView)
          else
            SizedBox(
              width: effectiveWidth,
              height: effectiveHeight,
              child: imageView,
            ),
          Positioned.fill(
            child: ColoredBox(color: const Color(0x00000000)),
          ),
        ],
      );
      return (hasFiniteSize && width == null && height == null) ? child : SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: child,
      );
    },
  );
}

String _boxFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitWidth:
      return 'cover';
    case BoxFit.fitHeight:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
