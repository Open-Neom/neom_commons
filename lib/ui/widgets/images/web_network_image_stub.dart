import 'package:flutter/material.dart';
import 'package:neom_core/utils/core_utilities.dart';

final RegExp _rasterDataImagePattern = RegExp(
  r'^data:image/(?:png|jpe?g|webp|gif|avif|bmp|x-icon|vnd\.microsoft\.icon)(?:;[a-z0-9\-=+.]+)*,',
  caseSensitive: false,
);

bool _hasUnsafeWebUrlChars(String value) {
  for (int i = 0; i < value.length; i++) {
    final unit = value.codeUnitAt(i);
    if (unit <= 0x20 ||
        (unit >= 0x7F && unit <= 0x9F) ||
        unit == 0x5C || // backslash
        unit == 0x061C ||
        (unit >= 0x200B && unit <= 0x200F) ||
        (unit >= 0x202A && unit <= 0x202E) ||
        (unit >= 0x2066 && unit <= 0x2069) ||
        unit == 0xFEFF) {
      return true;
    }
  }
  return false;
}

({String scheme, String host, int port})? _parseTupleOrigin(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty ||
      trimmed == 'null' ||
      _hasUnsafeWebUrlChars(trimmed)) {
    return null;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.userInfo.isNotEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  final host = uri.host.trim().toLowerCase();
  if (host.isEmpty) return null;
  final port = uri.hasPort ? uri.port : (scheme == 'https' ? 443 : 80);
  return (scheme: scheme, host: host, port: port);
}

/// Validates whether a `blob:` image URL belongs to the same non-opaque tuple
/// origin as [referenceOriginUrl].
@visibleForTesting
bool isSameOriginWebImageBlobUrl(
  String rawUrl, {
  String? referenceOriginUrl,
}) {
  if (referenceOriginUrl == null) return false;
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
  final cand = _parseTupleOrigin(inner);
  final ref = _parseTupleOrigin(referenceOriginUrl);
  if (cand == null || ref == null) return false;
  return cand.scheme == ref.scheme &&
      cand.host == ref.host &&
      cand.port == ref.port;
}

/// Validates whether [rawUrl] uses a safe scheme and origin for browser `<img>`
/// rendering without triggering SVG XSS or unsolicited Local Network Access.
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
    return CoreUtilities.isSafePublicMediaUri(uri);
  }
  if (lower.startsWith('blob:')) {
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
    return _rasterDataImagePattern.hasMatch(trimmed);
  }
  return false;
}

/// Optimizes Google user content image URLs without matching spoofed hosts.
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
  final safeSize = size.isFinite ? size.clamp(16, 2048) : 96;
  return '$url=s$safeSize';
}

double? _finitePositiveDimension(double? value) =>
    (value != null && value.isFinite && value > 0) ? value : null;

/// Stub for non-web platforms — uses Image.network after safe-URL validation.
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
  if (!isAllowedWebImageUrl(imageUrl)) {
    final fallback = errorWidget ?? const SizedBox.shrink();
    if (safeHeight == null && safeWidth == null) return fallback;
    return SizedBox(height: safeHeight, width: safeWidth, child: fallback);
  }
  final child = Image.network(
    optimizeGoogleWebImageUrl(imageUrl.trim()),
    fit: fit,
    height: safeHeight,
    width: safeWidth,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return placeholder ??
          const Center(child: CircularProgressIndicator(strokeWidth: 2));
    },
    errorBuilder: (context, error, stackTrace) =>
        errorWidget ?? const Icon(Icons.image_not_supported),
  );
  return circular ? ClipOval(child: child) : child;
}
