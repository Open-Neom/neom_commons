import 'package:app_links/app_links.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/slug_router.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';


class DeeplinkUtilities {

  // Ejemplo conceptual en tu controlador principal o main
  Future<void> initDeepLinks() async {
    // Escuchar links entrantes
    final appLinks = AppLinks(); // Usando paquete app_links

    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        AppConfig.logger.d("DeepLink recibido: $uri");
        handleDeepLink(uri);
      }
    });
  }

  Future<void> handleDeepLink(Uri uri) async {
    List<String> segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    String? type = uri.queryParameters['type'];
    String? id = uri.queryParameters['id'];

    // Handle vanity URL patterns from web URLs
    if (segments.isNotEmpty) {
      final first = segments.first.trim();

      // ─── @username shorthand → direct profile resolution ───
      if (first.startsWith('@') && first.length > 1) {
        final username = first.substring(1);
        AppConfig.logger.i("DeepLink: @mention '$username' → profile lookup");
        try {
          final match = await SlugRouter.resolveProfile(username);
          if (match != null) {
            navigateWithHomeBehind(AppRouteConstants.matePath(match.id, slug: match.slug));
            return;
          }
        } catch (e, st) {
          NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'resolveProfileDeepLink');
        }
        Sint.offAllNamed(AppRouteConstants.home);
        return;
      }

      // /p/{postId} → Post
      if (first.toLowerCase() == 'p' && segments.length > 1) {
        navigateWithHomeBehind(AppRouteConstants.postPath(segments[1]), arguments: segments[1]);
        return;
      }

      // /blog/{slugOrId} → BlogEntry
      if (first.toLowerCase() == 'blog' && segments.length > 1) {
        _resolveBlogLink(segments[1]);
        return;
      }

      // /e/{eventId} → Event
      if (first.toLowerCase() == 'e' && segments.length > 1) {
        navigateWithHomeBehind(AppRouteConstants.eventPath(segments[1]), arguments: segments[1]);
        return;
      }

      // /shop/{productId} → Product
      if (first.toLowerCase() == 'shop' && segments.length > 1) {
        navigateWithHomeBehind(
          AppRouteConstants.shopProductPath(segments[1]),
          arguments: {'productId': segments[1], 'type': 'release'},
        );
        return;
      }

      // /item/{itemId} → MediaItem (fallback for items without slug)
      if (first.toLowerCase() == 'item' && segments.length > 1) {
        navigateWithHomeBehind(AppRouteConstants.itemPath(segments[1]), arguments: segments[1]);
        return;
      }

      // /playlist/{itemlistId} → Playlist/Itemlist
      if (first.toLowerCase() == 'playlist' && segments.length > 1) {
        navigateWithHomeBehind(
          AppRouteConstants.listItems,
          arguments: [segments[1], false, true],
        );
        return;
      }

      // /collective/{collectiveId} → Collective
      if (first.toLowerCase() == 'collective' && segments.length > 1) {
        navigateWithHomeBehind(
          AppRouteConstants.collectivePath(segments[1]),
          arguments: [segments[1]],
        );
        return;
      }

      // ─── Single segment vanity slug (no prefix) ───
      if (segments.length == 1) {
        AppConfig.logger.i("DeepLink: resolving vanity slug '$first'");
        try {
          final match = await SlugRouter.resolve(first);
          if (match != null) {
            switch (match.type) {
              case 'profile':
                navigateWithHomeBehind(AppRouteConstants.matePath(match.id, slug: match.slug));
                return;
              case 'item':
                navigateWithHomeBehind(
                  AppFlavour.getMainItemDetailsRoute(match.id, slug: match.slug),
                  arguments: match.id,
                );
                return;
              case 'event':
                navigateWithHomeBehind(AppRouteConstants.eventPath(match.id, slug: match.slug), arguments: match.id);
                return;
              case 'collective':
                navigateWithHomeBehind(AppRouteConstants.collectivePath(match.id, slug: match.slug), arguments: [match.entity]);
                return;
              case 'post':
                navigateWithHomeBehind(AppRouteConstants.postPath(match.id, slug: match.slug), arguments: match.id);
                return;
            }
          }
        } catch (e, st) {
          NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'resolveVanityDeepLink');
        }
      }
    }

    // Handle custom scheme deep links (emxi://share/post/123)
    if (segments.contains('post')) {
      type = 'post';
      int index = segments.indexOf('post');
      if (index + 1 < segments.length) id = segments[index + 1];
    } else if (segments.contains('media')) {
      type = 'media';
      int index = segments.indexOf('media');
      if (index + 1 < segments.length) id = segments[index + 1];
    } else if (segments.contains('product')) {
      type = 'product';
      int index = segments.indexOf('product');
      if (index + 1 < segments.length) id = segments[index + 1];
    } else if (segments.contains('merch')) {
      type = 'merch';
      int index = segments.indexOf('merch');
      if (index + 1 < segments.length) id = segments[index + 1];
    }

    if (type == 'post' && id != null) {
      navigateWithHomeBehind(AppRouteConstants.postPath(id), arguments: id);
    } else if (type == 'media' && id != null) {
      navigateWithHomeBehind(AppRouteConstants.itemPath(id), arguments: id);
    } else if (type == 'product' && id != null) {
      navigateWithHomeBehind(
        AppRouteConstants.shopProductPath(id),
        arguments: {'productId': id, 'type': 'release'},
      );
    } else if (type == 'merch' && id != null) {
      navigateWithHomeBehind(
        AppRouteConstants.shopProductPath(id),
        arguments: {'productId': id, 'type': 'merch'},
      );
    } else {
      Sint.offAllNamed(AppRouteConstants.home);
    }
  }

  /// Resolves a blog link by slug or ID via [SlugRouter], then navigates.
  Future<void> _resolveBlogLink(String slugOrId) async {
    try {
      final match = await SlugRouter.resolveBlog(slugOrId);
      if (match != null) {
        navigateWithHomeBehind(AppRouteConstants.blogEntryPath(match.id, slug: match.slug), arguments: [match.entity]);
        return;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'resolveBlogLink');
    }
    Sint.offAllNamed(AppRouteConstants.home);
  }

  /// Navigates to content with home/root behind in the navigation stack.
  /// Clears the stack → root, waits a frame, then pushes the content route.
  /// Pressing "back" from the content returns to home.
  static Future<void> navigateWithHomeBehind(String route, {dynamic arguments}) async {
    Sint.offAllNamed(AppRouteConstants.root);
    await Future.delayed(const Duration(milliseconds: 150));
    Sint.toNamed(route, arguments: arguments);
  }

  /// Generates a vanity URL for sharing.
  /// Examples:
  ///   - emxi.org/serzenmontoya (profile)
  ///   - emxi.org/quemando-mis-razones (book/audio)
  ///   - emxi.org/p/abc123 (post)
  ///   - emxi.org/blog/mi-primer-articulo (blog)
  ///   - emxi.org/e/xyz789 (event)
  ///   - emxi.org/shop/def456 (product)
  static String generateVanityUrl({required String type, String id = '', String slug = ''}) {
    final siteUrl = AppProperties.getSiteUrl();
    switch (type) {
      case 'profile':
        final profileSlug = slug.isNotEmpty ? slug : id;
        final formattedSlug = profileSlug.startsWith('@') ? profileSlug : '@$profileSlug';
        return '$siteUrl/$formattedSlug';
      case 'book':
      case 'media':
        return slug.isNotEmpty ? '$siteUrl/$slug' : '$siteUrl/item/$id';
      case 'post':
        return '$siteUrl/p/$id';
      case 'blog':
        return slug.isNotEmpty ? '$siteUrl/blog/$slug' : '$siteUrl/blog/$id';
      case 'event':
        return slug.isNotEmpty ? '$siteUrl/$slug' : '$siteUrl/e/$id';
      case 'collective':
        return slug.isNotEmpty ? '$siteUrl/$slug' : '$siteUrl/collective/$id';
      case 'playlist':
        return '$siteUrl/playlist/$id';
      case 'product':
      case 'merch':
        return '$siteUrl/shop/$id';
      default:
        return siteUrl;
    }
  }

  /// @deprecated Use [generateVanityUrl] instead.
  static String generateDeepLink({required String host,
    required String type, required String id}) {
    String myScheme = AppProperties.getAppName().toLowerCase();
    const String myHost = 'share';
    return "$myScheme://$myHost/$type/$id";
  }

}
