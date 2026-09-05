import 'package:app_links/app_links.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/slug_router.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';


class DeeplinkUtilities {

  /// Invite coupon code captured from an `emxi.org/invite/{code}` link before
  /// the user has an account. Onboarding reads + clears it to auto-apply the
  /// coupon (free month / plan trial) during registration.
  static String pendingInviteCoupon = '';

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

  /// Path segments of a link, however it reached the app.
  ///
  /// A custom-scheme link puts its first segment in the AUTHORITY, not the
  /// path: `gigmeout://album/novus-irae/letimum` parses as host `album` with
  /// path `/novus-irae/letimum`. Reading only `pathSegments` dropped that
  /// first segment, so prefixed addresses silently resolved as something else.
  /// Web links carry the domain as the authority, so it is not prepended.
  static List<String> _addressSegments(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final isWebLink = uri.scheme == 'http' || uri.scheme == 'https';
    if (!isWebLink && uri.host.isNotEmpty) {
      segments.insert(0, uri.host);
    }
    return segments;
  }

  Future<void> handleDeepLink(Uri uri) async {
    List<String> segments = _addressSegments(uri);
    String? type = uri.queryParameters['type'];
    String? id = uri.queryParameters['id'];

    // Handle vanity URL patterns from web URLs
    if (segments.isNotEmpty) {
      final first = segments.first.trim();

      // ─── Album deep link (artistSlug/a/albumSlug) ───
      if (segments.length == 3 && segments[1].toLowerCase() == 'a') {
        final fullSlug = '${segments[0]}/a/${segments[2]}';
        AppConfig.logger.i("DeepLink: Album slug '$fullSlug' → Home Autoplay");
        if (AppConfig.instance.appInUse == AppInUse.g) {
          Sint.offAllNamed(AppRouteConstants.root);
          Future.delayed(const Duration(milliseconds: 300), () async {
            try {
              final itemlist = await ItemlistFirestore().getBySlug(fullSlug);
              final List<AppReleaseItem> releaseItems = itemlist?.appReleaseItems ?? [];
              if (releaseItems.isNotEmpty) {
                Sint.find<AudioPlayerInvokerService>().init(
                  releaseItems: releaseItems,
                  index: 0,
                  playItem: true,
                );
              }
            } catch (e) {
              AppConfig.logger.e("Error playing album from deep link: $e");
            }
          });
          return;
        }
      }

      // ─── Song deep link (artistSlug/songSlug) ───
      if (segments.length == 2) {
        final prefixes = {'invite', 'p', 'collective', 'playlist', 'post', 'blog', 'e', 'shop', 'item'};
        if (!prefixes.contains(first.toLowerCase())) {
          final fullSlug = '${segments[0]}/${segments[1]}';
          AppConfig.logger.i("DeepLink: Song slug '$fullSlug' → Home Autoplay");
          if (AppConfig.instance.appInUse == AppInUse.g) {
            Sint.offAllNamed(AppRouteConstants.root);
            Future.delayed(const Duration(milliseconds: 300), () async {
              try {
                final item = await AppReleaseItemFirestore().getBySlug(fullSlug);
                if (item != null && item.id.isNotEmpty) {
                  Sint.find<AudioPlayerInvokerService>().init(
                    releaseItems: [item],
                    index: 0,
                    playItem: true,
                  );
                }
              } catch (e) {
                AppConfig.logger.e("Error playing song from deep link: $e");
              }
            });
            return;
          }
        }
      }

      // ─── /inicio?item={slug/id} → play song in background on Home Page ───
      if (first.toLowerCase() == 'inicio') {
        final itemIdOrSlug = uri.queryParameters['item'] ?? uri.queryParameters['play'] ?? '';
        if (itemIdOrSlug.isNotEmpty) {
          if (AppConfig.instance.appInUse == AppInUse.g) {
            Sint.offAllNamed(AppRouteConstants.root);
            Future.delayed(const Duration(milliseconds: 300), () async {
              try {
                AppReleaseItem? item;
                final match = await SlugRouter.resolve(itemIdOrSlug);
                if (match != null && match.type == 'item' && match.entity is AppReleaseItem) {
                  item = match.entity as AppReleaseItem;
                }
                if (item == null) {
                  item = await AppReleaseItemFirestore().retrieve(itemIdOrSlug);
                }
                if (item.id.isNotEmpty) {
                  Sint.find<AudioPlayerInvokerService>().init(
                    releaseItems: [item],
                    index: 0,
                    playItem: true,
                  );
                }
              } catch (e) {
                AppConfig.logger.e("Error playing item from inicio query param: $e");
              }
            });
          }
          return;
        }
      }

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

      // /invite/{code} → store coupon, go to registration (auto-applied later)
      if (first.toLowerCase() == 'invite' && segments.length > 1) {
        pendingInviteCoupon = segments[1].trim();
        AppConfig.logger.i("DeepLink: invite coupon '$pendingInviteCoupon' → register");
        Sint.offAllNamed(AppRouteConstants.login);
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

      // /{kind}/{ownerSlug}/{slug} → Itemlist (album, ep, podcast…).
      // Prefixes come from ItemlistType, so the address names its own kind.
      final listType = AppRouteConstants.itemlistTypeFromPrefix(first);
      if (listType != null && segments.length >= 3) {
        navigateWithHomeBehind(
          AppRouteConstants.itemlistPath(listType, '',
              ownerSlug: segments[1], slug: segments[2]),
        );
        return;
      }

      // /a/{ownerSlug}/{slug} → Release, /a/{ownerSlug} → Artist.
      // Delegated to SlugResolverPage, which owns the resolution and the
      // per-app open behaviour.
      if (first.toLowerCase() == AppRouteConstants.releasePrefix
          && segments.length >= 2) {
        final path = segments.length >= 3
            ? AppRouteConstants.releasePath('',
                ownerSlug: segments[1], slug: segments[2])
            : AppRouteConstants.artistPath(segments[1]);
        navigateWithHomeBehind(path);
        return;
      }

      // /item/{itemId} → MediaItem (fallback for items without slug)
      if (first.toLowerCase() == 'item' && segments.length > 1) {
        if (AppConfig.instance.appInUse == AppInUse.g) {
          Sint.offAllNamed(AppRouteConstants.root);
          Future.delayed(const Duration(milliseconds: 300), () async {
            try {
              final item = await AppReleaseItemFirestore().retrieve(segments[1]);
              if (item.id.isNotEmpty) {
                Sint.find<AudioPlayerInvokerService>().init(
                  releaseItems: [item],
                  index: 0,
                  playItem: true,
                );
              }
            } catch (e) {
              AppConfig.logger.e("Error playing item from deep link: $e");
            }
          });
        } else {
          navigateWithHomeBehind(AppRouteConstants.itemPath(segments[1]), arguments: segments[1]);
        }
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
                if (AppConfig.instance.appInUse == AppInUse.g) {
                  Sint.offAllNamed(AppRouteConstants.root);
                  Future.delayed(const Duration(milliseconds: 300), () async {
                    try {
                      final item = match.entity is AppReleaseItem
                          ? match.entity as AppReleaseItem
                          : await AppReleaseItemFirestore().retrieve(match.id);
                      if (item.id.isNotEmpty) {
                        Sint.find<AudioPlayerInvokerService>().init(
                          releaseItems: [item],
                          index: 0,
                          playItem: true,
                        );
                      }
                    } catch (e) {
                      AppConfig.logger.e("Error playing item from deep link: $e");
                    }
                  });
                } else {
                  navigateWithHomeBehind(
                    AppFlavour.getMainItemDetailsRoute(match.id, slug: match.slug),
                    arguments: match.id,
                  );
                }
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
  static String generateVanityUrl({required String type, String id = '',
      String slug = '', String ownerSlug = ''}) {
    final siteUrl = AppProperties.getSiteUrl();
    switch (type) {
      case 'profile':
        final profileSlug = slug.isNotEmpty ? slug : id;
        final formattedSlug = profileSlug.startsWith('@') ? profileSlug : '@$profileSlug';
        return '$siteUrl/$formattedSlug';
      case 'book':
      case 'media':
        // `/a/{ownerSlug}/{slug}` — the artist has to be in the address because
        // a release slug is only unique per artist: two bands may each have a
        // "Piedad", and a bare `/piedad` could not tell them apart.
        // releasePath() falls back to `/item/{id}` when the slugs are missing.
        return '$siteUrl${AppRouteConstants.releasePath(id, ownerSlug: ownerSlug, slug: slug)}';
      case 'post':
        return '$siteUrl/p/$id';
      case 'blog':
        return slug.isNotEmpty ? '$siteUrl/blog/$slug' : '$siteUrl/blog/$id';
      case 'event':
        return slug.isNotEmpty ? '$siteUrl/$slug' : '$siteUrl/e/$id';
      case 'collective':
        return slug.isNotEmpty ? '$siteUrl/$slug' : '$siteUrl/collective/$id';
      case 'playlist':
        if (AppConfig.instance.appInUse == AppInUse.g) {
          final param = slug.isNotEmpty ? slug : 'playlist/$id';
          return '$siteUrl/$param';
        }
        return '$siteUrl/playlist/$id';
      case 'product':
      case 'merch':
        return '$siteUrl/shop/$id';
      case 'invite':
        return '$siteUrl/invite/$id';
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
