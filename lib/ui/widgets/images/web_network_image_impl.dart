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
}) {
  if (imageUrl.isEmpty || imageUrl == 'null') {
    return errorWidget ?? const SizedBox.shrink();
  }

  final optimizedUrl = _optimizeGoogleUrl(imageUrl);
  final viewType = 'web-img-${optimizedUrl.hashCode}';

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

  // When explicit dimensions are provided, use SizedBox to constrain.
  if (height != null || width != null) {
    return SizedBox(
      height: height,
      width: width,
      child: imageView,
    );
  }

  // No explicit dimensions: use AspectRatio to prevent unbounded height
  // in scrollable contexts (SliverList, Column, etc.) where HtmlElementView
  // would otherwise expand to infinity.
  return AspectRatio(
    aspectRatio: 4 / 3,
    child: imageView,
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
