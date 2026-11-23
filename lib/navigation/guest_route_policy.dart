/// Reusable fail-closed guest navigation policy engine for Open Neom host apps.
///
/// Host apps declare their brand-specific allow-listed routes (exact paths,
/// dynamic `:param` templates, public prefixes, private dynamic overrides,
/// onboarding paths, and optional namespace [scopePrefixes]) without duplicating
/// URI normalization or path-matching logic.
class NeomGuestRoutePolicy {
  const NeomGuestRoutePolicy({
    this.publicExactPaths = const <String>{},
    this.publicTemplates = const <String>{},
    this.privateDynamicPathOverrides = const <String>{},
    this.publicPrefixes = const <String>{},
    this.onboardingExactPaths = const <String>{},
    this.scopePrefixes,
    this.allowProfileVanityUrls = false,
    this.caseInsensitive = false,
  });

  final Set<String> publicExactPaths;
  final Set<String> publicTemplates;
  final Set<String> privateDynamicPathOverrides;
  final Set<String> publicPrefixes;
  final Set<String> onboardingExactPaths;

  /// When non-null, only routes matching one of these prefixes are governed by
  /// this policy (e.g. `{'/audioplayer'}` for Gigmeout's audio-only guard).
  /// Routes outside [scopePrefixes] return `false` from [requiresAuthentication].
  final Set<String>? scopePrefixes;

  /// When true, top-level vanity profile routes (`/@handle`) are treated as
  /// public guest routes.
  final bool allowProfileVanityUrls;

  /// When true, path normalization lowercases the path before comparison.
  final bool caseInsensitive;

  /// Whether [route] falls inside [scopePrefixes] (or any valid path when
  /// [scopePrefixes] is null).
  bool isInScope(String? route) {
    final path = normalizedPath(route, caseInsensitive: caseInsensitive);
    if (path == null) return false;
    final scopes = scopePrefixes;
    if (scopes == null) return true;
    return scopes.any((prefix) => isPathWithin(path, prefix));
  }

  /// Routes belonging to the new-account onboarding wizard (`/intro/*`).
  bool isOnboardingRoute(String? route) {
    final path = normalizedPath(route, caseInsensitive: caseInsensitive);
    if (path == null) return false;
    return onboardingExactPaths.contains(path);
  }

  bool isPublic(String? route) {
    final path = normalizedPath(route, caseInsensitive: caseInsensitive);
    if (path == null || privateDynamicPathOverrides.contains(path)) {
      return false;
    }

    if (publicExactPaths.contains(path)) return true;
    if (publicPrefixes.any((prefix) => isPathWithin(path, prefix))) {
      return true;
    }
    if (publicTemplates.any((template) => matchesTemplate(path, template))) {
      return true;
    }

    if (allowProfileVanityUrls &&
        path.startsWith('/@') &&
        path.length > 2 &&
        !path.substring(2).contains('/')) {
      return true;
    }

    return false;
  }

  bool requiresAuthentication(String? route) {
    if (scopePrefixes != null) {
      return isInScope(route) && !isPublic(route);
    }
    return !isPublic(route);
  }

  /// Returns only the path used for policy matching. The original route is
  /// kept by the middleware so query parameters survive the login round trip.
  static String? normalizedPath(
    String? route, {
    bool caseInsensitive = false,
  }) {
    if (route == null || route.trim().isEmpty) return null;

    final uri = Uri.tryParse(route.trim());
    if (uri == null || uri.path.isEmpty || !uri.path.startsWith('/')) {
      return null;
    }

    var path = uri.path;
    while (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return caseInsensitive ? path.toLowerCase() : path;
  }

  static bool isPathWithin(String path, String prefix) =>
      path == prefix || path.startsWith('$prefix/');

  static bool matchesTemplate(String path, String template) {
    final pathSegments = path.split('/');
    final templateSegments = template.split('/');
    if (pathSegments.length != templateSegments.length) return false;

    for (var index = 0; index < templateSegments.length; index++) {
      final expected = templateSegments[index];
      final actual = pathSegments[index];
      if (expected.startsWith(':')) {
        if (actual.isEmpty) return false;
        continue;
      }
      if (expected != actual) return false;
    }
    return true;
  }
}
