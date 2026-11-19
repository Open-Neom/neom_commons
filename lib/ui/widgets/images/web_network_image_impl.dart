import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/release_catalog_visibility.dart';

const int _maxOutcomeCacheEntries = 500;
const int _maxViewTypeCacheEntries = 2000;
final Map<String, String> _viewTypeByKey = <String, String>{};
int _nextViewTypeId = 0;

final RegExp _rasterDataImagePattern = RegExp(
  r'^data:image/(?:png|jpe?g|webp|gif|avif|bmp|x-icon|vnd\.microsoft\.icon)(?:;[a-z0-9\-=+.]+)*,',
  caseSensitive: false,
);

extension type _JSOrigin._(JSObject _) implements JSObject {
  external bool get opaque;
  external bool isSameOrigin(_JSOrigin other);
}

extension type _JSOriginConstructor._(JSObject _) implements JSObject {
  external _JSOrigin from(JSAny candidate);
}

extension type _JSUrl._(JSObject _) implements JSObject {
  external factory _JSUrl(String url);
  external String get origin;
}

bool _hasUnsafeWebUrlChars(String value) {
  for (int i = 0; i < value.length; i++) {
    final unit = value.codeUnitAt(i);
    if (unit <= 0x20 ||
        (unit >= 0x7F && unit <= 0x9F) ||
        unit == 0x5C || // backslash
        unit == 0x0085 ||
        unit == 0x061C ||
        (unit >= 0x200B && unit <= 0x200F) ||
        (unit >= 0x2028 && unit <= 0x202E) ||
        unit == 0x2060 ||
        (unit >= 0x2066 && unit <= 0x2069) ||
        unit == 0x3002 ||
        unit == 0xFF0E ||
        unit == 0xFF61 ||
        unit == 0xFEFF) {
      return true;
    }
  }
  return false;
}

String? _currentExecutionHref() {
  try {
    final loc = globalContext['location'];
    if (loc != null && loc.isA<JSObject>()) {
      final href = (loc as JSObject)['href'];
      if (href != null && href.isA<JSString>()) {
        final value = (href as JSString).toDart.trim();
        if (value.isNotEmpty) return value;
      }
    }
  } catch (_) {}
  return null;
}

bool _checkSameOriginCandidate(
  String candidateUrl, {
  String? referenceOriginUrl,
}) {
  try {
    if (globalContext.has('Origin')) {
      final originVal = globalContext['Origin'];
      if (originVal != null && originVal.isA<JSObject>()) {
        final ctor = _JSOriginConstructor._(originVal as JSObject);
        final candidateOrigin = ctor.from(candidateUrl.toJS);
        // Pass globalContext (`self`) rather than Location/Document (which
        // throw TypeError in Origin.from()) when validating against our own
        // execution context.
        final trustedOrigin = referenceOriginUrl != null
            ? ctor.from(referenceOriginUrl.trim().toJS)
            : ctor.from(globalContext);
        return !candidateOrigin.opaque &&
            !trustedOrigin.opaque &&
            candidateOrigin.isSameOrigin(trustedOrigin);
      }
    }

    final trustedHref = referenceOriginUrl?.trim() ?? _currentExecutionHref();
    if (trustedHref == null || trustedHref.isEmpty) return false;
    final candidateParsed = _JSUrl(candidateUrl);
    final trustedParsed = _JSUrl(trustedHref);
    final candOrigin = candidateParsed.origin;
    return candOrigin != 'null' &&
        candOrigin.isNotEmpty &&
        candOrigin == trustedParsed.origin;
  } catch (_) {
    return false;
  }
}

/// Validates whether a `blob:` image URL belongs to the same non-opaque tuple
/// origin as [referenceOriginUrl] (or the current browser execution context).
@visibleForTesting
bool isSameOriginWebImageBlobUrl(
  String rawUrl, {
  String? referenceOriginUrl,
}) {
  final trimmed = rawUrl.trim();
  if (trimmed.length <= 5 ||
      trimmed.length > 4096 ||
      _hasUnsafeWebUrlChars(trimmed) ||
      !trimmed.toLowerCase().startsWith('blob:')) {
    return false;
  }
  final inner = trimmed.substring(5);
  if (inner.isEmpty ||
      inner.toLowerCase().startsWith('null') ||
      !inner.contains('/')) {
    return false;
  }
  return _checkSameOriginCandidate(
    inner,
    referenceOriginUrl: referenceOriginUrl,
  );
}

/// Validates whether [rawUrl] uses a safe scheme and origin for browser `<img>`
/// rendering without triggering SVG XSS or unsolicited Local Network Access
/// (`local-network` / `loopback-network`) prompts.
@visibleForTesting
bool isAllowedWebImageUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty ||
      trimmed == 'null' ||
      trimmed == 'undefined' ||
      trimmed.length > 4096 ||
      _hasUnsafeWebUrlChars(trimmed)) {
    return false;
  }
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.userInfo.isNotEmpty || uri.host.isEmpty) {
      return false;
    }
    if (ReleaseCatalogVisibility.usesUnavailableHost(
      trimmed,
      app: AppConfig.instance.appInUse,
    )) {
      return false;
    }
    // Same-origin local development (`http://localhost:<port>`) stays within
    // the loopback address space and does not cross LNA boundaries.
    if (_checkSameOriginCandidate(trimmed)) {
      return true;
    }
    // Cross-origin <img> loads must target public hosts only so untrusted image
    // URLs cannot probe RFC1918/loopback/IMDS or trigger LNA prompts.
    return CoreUtilities.isSafePublicMediaUri(uri);
  }
  if (lower.startsWith('blob:')) {
    if (isSameOriginWebImageBlobUrl(trimmed)) {
      return true;
    }
    final inner = trimmed.substring(5);
    if (inner.isEmpty || inner.toLowerCase().startsWith('null')) {
      return false;
    }
    final innerUri = Uri.tryParse(inner);
    return innerUri != null &&
        innerUri.scheme.toLowerCase() == 'https' &&
        innerUri.path.length > 1 &&
        CoreUtilities.isSafePublicMediaUri(innerUri);
  }
  if (lower.startsWith('data:image/')) {
    // Allow raster formats only; block `image/svg+xml` (plain or base64) to
    // prevent embedded script/event-handler payloads.
    return _rasterDataImagePattern.hasMatch(trimmed);
  }
  return false;
}

/// Creates the load probe. Tests can deliver a transient browser error without
/// depending on an external image server; displayed images still use <img>.
@visibleForTesting
JSObject Function()? debugWebNetworkImageProbeFactory;

/// Optimizes Google user content image URLs for web by appending size parameter.
/// Reduces bandwidth and avoids HTTP 429 rate limits from Google's CDN.
@visibleForTesting
String optimizeGoogleWebImageUrl(String url, {int size = 96}) {
  if (url.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.hasQuery || uri.hasFragment) return url;
  final host = uri.host.toLowerCase();
  if (host != 'googleusercontent.com' &&
      !host.endsWith('.googleusercontent.com')) {
    return url;
  }
  if (url.contains(RegExp(r'=s\d+'))) return url;
  final safeSize = size.toDouble().isFinite ? size.clamp(16, 2048) : 96;
  return '$url=s$safeSize';
}

double? _finitePositiveDimension(double? value) =>
    (value != null && value.isFinite && value > 0) ? value : null;

JSObject _createHtmlImageElement({required bool isSameOrigin}) {
  final doc = globalContext['document'];
  if (doc == null || !doc.isA<JSObject>()) {
    throw StateError('DOM document is unavailable');
  }
  final img = (doc as JSObject).callMethod<JSObject>(
    'createElement'.toJS,
    'img'.toJS,
  );
  img['decoding'] = 'async'.toJS;
  img['loading'] = 'lazy'.toJS;
  img['referrerPolicy'] = (isSameOrigin
          ? 'strict-origin-when-cross-origin'
          : 'no-referrer')
      .toJS;
  return img;
}

/// Builds a native HTML <img> element via HtmlElementView (Dart2Wasm-ready).
/// This bypasses CanvasKit/Skwasm CORS requirements for cross-origin images.
///
/// The load outcome is probed in Dart so [placeholder] and [errorWidget] are
/// actually rendered: the platform view alone can only hide a broken <img>,
/// which left an empty hole where the fallback should be.
/// Changing [retryToken] retries a failed URL without changing the URL itself.
Widget buildWebNativeImage({
  required String imageUrl,
  int retryToken = 0,
  BoxFit fit = BoxFit.cover,
  double? height,
  double? width,
  Widget? placeholder,
  Widget? errorWidget,
  bool circular = false,
}) {
  final safeHeight = _finitePositiveDimension(height);
  final safeWidth = _finitePositiveDimension(width);
  final sanitizedUrl = imageUrl.trim();
  if (!isAllowedWebImageUrl(sanitizedUrl)) {
    final fallback = errorWidget ?? const SizedBox.shrink();
    if (safeHeight == null && safeWidth == null) return fallback;
    return SizedBox(height: safeHeight, width: safeWidth, child: fallback);
  }

  return _WebNativeImage(
    imageUrl: sanitizedUrl,
    retryToken: retryToken,
    fit: fit,
    height: safeHeight,
    width: safeWidth,
    placeholder: placeholder,
    errorWidget: errorWidget,
    circular: circular,
  );
}

/// Tracks whether [imageUrl] loaded, so a 403/404/CORS failure shows
/// [errorWidget] instead of an empty box.
class _WebNativeImage extends StatefulWidget {
  const _WebNativeImage({
    required this.imageUrl,
    required this.retryToken,
    required this.fit,
    this.height,
    this.width,
    this.placeholder,
    this.errorWidget,
    this.circular = false,
  });

  final String imageUrl;
  final int retryToken;
  final BoxFit fit;
  final double? height;
  final double? width;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool circular;

  @override
  State<_WebNativeImage> createState() => _WebNativeImageState();
}

enum _LoadState { loading, loaded, failed }

class _WebNativeImageState extends State<_WebNativeImage> {

  /// Outcome per URL, bounded to [_maxOutcomeCacheEntries] so long sessions
  /// do not accumulate unbounded URL strings in memory.
  static final Map<String, _LoadState> _outcomes = {};

  late String _optimizedUrl;
  _LoadState _state = _LoadState.loading;
  int _loadGeneration = 0;
  JSObject? _activeProbe;
  JSFunction? _loadListener;
  JSFunction? _errorListener;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_WebNativeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolve();
    } else if (oldWidget.retryToken != widget.retryToken) {
      _resolve(retry: true);
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _cancelProbe();
    super.dispose();
  }

  static void _recordOutcome(String url, _LoadState outcome) {
    if (!_outcomes.containsKey(url) &&
        _outcomes.length >= _maxOutcomeCacheEntries) {
      _outcomes.remove(_outcomes.keys.first);
    }
    _outcomes[url] = outcome;
  }

  void _cancelProbe() {
    final probe = _activeProbe;
    final onLoad = _loadListener;
    final onError = _errorListener;
    _activeProbe = null;
    _loadListener = null;
    _errorListener = null;
    if (probe != null) {
      try {
        if (onLoad != null) {
          probe.callMethod('removeEventListener'.toJS, 'load'.toJS, onLoad);
        }
        if (onError != null) {
          probe.callMethod('removeEventListener'.toJS, 'error'.toJS, onError);
        }
      } catch (_) {}
    }
  }

  void _resolve({bool retry = false}) {
    final generation = ++_loadGeneration;
    _cancelProbe();
    if (!isAllowedWebImageUrl(widget.imageUrl)) {
      _state = _LoadState.failed;
      return;
    }

    _optimizedUrl = optimizeGoogleWebImageUrl(widget.imageUrl);
    final url = _optimizedUrl;

    // Only a new, explicit retry invalidates a failed result. Normal rebuilds
    // and revisits retain the cached outcome, and successful images stay warm.
    // Keep the URL intact, including any signed query or authorization token.
    if (retry && _outcomes[url] == _LoadState.failed) {
      _outcomes.remove(url);
    }

    final known = _outcomes[url];
    if (known != null && known != _LoadState.loading) {
      _state = known;
      return;
    }

    _state = _LoadState.loading;
    void settle(_LoadState outcome) {
      if (!mounted || generation != _loadGeneration) return;
      _cancelProbe();
      _recordOutcome(url, outcome);
      if (_state == outcome) return;
      setState(() => _state = outcome);
    }

    try {
      // The browser serves this from cache for the <img> the platform view
      // creates, so probing does not cost a second download.
      final sameOrigin = url.startsWith('data:') ||
          isSameOriginWebImageBlobUrl(url) ||
          _checkSameOriginCandidate(url);
      final probe = debugWebNetworkImageProbeFactory?.call() ??
          _createHtmlImageElement(isSameOrigin: sameOrigin);
      final onLoad = ((JSAny? _) {
        settle(_LoadState.loaded);
      }).toJS;
      final onError = ((JSAny? _) {
        settle(_LoadState.failed);
      }).toJS;
      _activeProbe = probe;
      _loadListener = onLoad;
      _errorListener = onError;
      probe.callMethod('addEventListener'.toJS, 'load'.toJS, onLoad);
      probe.callMethod('addEventListener'.toJS, 'error'.toJS, onError);
      probe['src'] = url.toJS;
    } catch (_) {
      settle(_LoadState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _LoadState.failed:
        return _sized(widget.errorWidget ?? const SizedBox.shrink());
      case _LoadState.loading:
        if (widget.placeholder != null) return _sized(widget.placeholder!);
        break;
      case _LoadState.loaded:
        break;
    }
    return _buildPlatformView(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      height: widget.height,
      width: widget.width,
      circular: widget.circular,
    );
  }

  /// Keeps the fallback the same size as the image it replaces, so a broken
  /// image does not collapse the layout around it.
  Widget _sized(Widget child) {
    if (widget.height == null && widget.width == null) return child;
    return SizedBox(height: widget.height, width: widget.width, child: child);
  }
}

String _resolveViewType({
  required String optimizedUrl,
  required BoxFit fit,
  required bool circular,
}) {
  final compositeKey = '${circular ? 1 : 0}|${fit.name}|$optimizedUrl';
  final existing = _viewTypeByKey[compositeKey];
  if (existing != null) return existing;

  if (_viewTypeByKey.length >= _maxViewTypeCacheEntries) {
    _viewTypeByKey.remove(_viewTypeByKey.keys.first);
  }
  final viewType = 'neom-web-img-${++_nextViewTypeId}';
  _viewTypeByKey[compositeKey] = viewType;
  final sameOrigin = optimizedUrl.startsWith('data:') ||
      isSameOriginWebImageBlobUrl(optimizedUrl) ||
      _checkSameOriginCandidate(optimizedUrl);

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final img = _createHtmlImageElement(isSameOrigin: sameOrigin);
      final styleAny = img['style'];
      if (styleAny != null && styleAny.isA<JSObject>()) {
        final style = styleAny as JSObject;
        style['width'] = '100%'.toJS;
        style['height'] = '100%'.toJS;
        style['objectFit'] = _boxFitToCss(fit).toJS;
        style['display'] = 'block'.toJS;
        style['pointerEvents'] = 'none'.toJS;

        if (circular) {
          style['borderRadius'] = '50%'.toJS;
        }

        // On error (429, 404, CORS, etc.), hide the broken image icon
        // and show a neutral background instead.
        img['onerror'] = ((JSAny? _) {
          style['display'] = 'none'.toJS;
        }).toJS;
      }
      img['src'] = optimizedUrl.toJS;
      return img;
    },
  );
  return viewType;
}

Widget _buildPlatformView({
  required String imageUrl,
  required BoxFit fit,
  double? height,
  double? width,
  bool circular = false,
}) {
  final optimizedUrl = optimizeGoogleWebImageUrl(imageUrl);
  final viewType = _resolveViewType(
    optimizedUrl: optimizedUrl,
    fit: fit,
    circular: circular,
  );

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
