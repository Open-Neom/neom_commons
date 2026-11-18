import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/api/app_release_items.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/secure_logger.dart';
import 'package:neom_core/utils/slug_router.dart';
import 'package:sint/sint.dart';

import '../app_flavour.dart';


class DeeplinkUtilities {
  static final RegExp _unsafeDeepLinkChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _encodedTraversalOrNull = RegExp(
    r'%(?:00|2e|2f|5c|25|c2%[89][0-9a-f]|d8%9c|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|ef%bb%bf)',
    caseSensitive: false,
  );
  static final RegExp _validInviteCouponPattern = RegExp(
    r'^[A-Za-z0-9_-]{1,64}$',
  );
  static final RegExp _safeSchemeSyntax = RegExp(r'^[a-z][a-z0-9+.\-]{0,31}$');
  static const Set<String> _blockedDeepLinkSchemes = <String>{
    'javascript',
    'vbscript',
    'data',
    'file',
    'blob',
    'about',
    'chrome',
    'chrome-extension',
    'view-source',
    'ws',
    'wss',
    'ftp',
    'jar',
    'intent',
    'ms-msdt',
    'ms-officecmd',
    'search-ms',
    'filesystem',
    'res',
    'mk',
  };
  static const Set<String> _forbiddenSegmentNames = <String>{
    '__proto__',
    'constructor',
    'prototype',
  };

  /// Invite coupon code captured from an `emxi.org/invite/{code}` link before
  /// the user has an account. Onboarding reads + clears it to auto-apply the
  /// coupon (free month / plan trial) during registration.
  static String pendingInviteCoupon = '';

  @visibleForTesting
  static bool isAllowedDeepLinkScheme(String rawScheme) {
    if (rawScheme.isEmpty) return true;
    if (_unsafeDeepLinkChars.hasMatch(rawScheme)) return false;
    final lower = rawScheme.trim().toLowerCase();
    if (!_safeSchemeSyntax.hasMatch(lower)) return false;
    return !_blockedDeepLinkSchemes.contains(lower);
  }

  @visibleForTesting
  static String sanitizeDeepLinkSegment(String raw, {int maxLength = 128}) {
    if (!maxLength.toDouble().isFinite || maxLength <= 0) return '';
    if (_encodedTraversalOrNull.hasMatch(raw)) return '';
    final cleaned = raw
        .replaceAll(_unsafeDeepLinkChars, '')
        .replaceAll(RegExp(r'[/\\?&#\s]+'), '')
        .trim();
    if (cleaned.isEmpty ||
        cleaned == '.' ||
        cleaned == '..' ||
        cleaned.contains('..') ||
        _forbiddenSegmentNames.contains(cleaned.toLowerCase()) ||
        (cleaned.startsWith('__') && cleaned.endsWith('__'))) {
      return '';
    }
    if (cleaned.length <= maxLength) return cleaned;
    var cut = maxLength;
    final lastUnit = cleaned.codeUnitAt(cut - 1);
    if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) {
      cut -= 1;
    }
    return cut <= 0 ? '' : cleaned.substring(0, cut);
  }

  @visibleForTesting
  static String sanitizeInviteCoupon(String raw) {
    if (_encodedTraversalOrNull.hasMatch(raw)) return '';
    final trimmed = raw.replaceAll(_unsafeDeepLinkChars, '').trim();
    if (!_validInviteCouponPattern.hasMatch(trimmed)) return '';
    if (_forbiddenSegmentNames.contains(trimmed.toLowerCase()) ||
        (trimmed.startsWith('__') && trimmed.endsWith('__'))) {
      return '';
    }
    return trimmed;
  }

  static StreamSubscription<Uri>? _uriLinkSubscription;

  // Ejemplo conceptual en tu controlador principal o main
  Future<void> initDeepLinks() async {
    await _uriLinkSubscription?.cancel();
    _uriLinkSubscription = null;

    // Escuchar links entrantes
    final appLinks = AppLinks(); // Usando paquete app_links

    _uriLinkSubscription = appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          AppConfig.logger.d(
            'DeepLink recibido: ${SecureLogger.sanitize(uri.toString())}',
          );
          handleDeepLink(uri);
        }
      },
      onError: (Object e, StackTrace st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_commons',
          operation: 'initDeepLinks',
        );
      },
    );
  }

  static Future<void> disposeDeepLinks() async {
    await _uriLinkSubscription?.cancel();
    _uriLinkSubscription = null;
  }

  /// Path segments of a link, however it reached the app.
  ///
  /// A custom-scheme link puts its first segment in the AUTHORITY, not the
  /// path: `gigmeout://album/novus-irae/letimum` parses as host `album` with
  /// path `/novus-irae/letimum`. Reading only `pathSegments` dropped that
  /// first segment, so prefixed addresses silently resolved as something else.
  /// Web links carry the domain as the authority, so it is not prepended.
  static List<String> _addressSegments(Uri uri) {
    final rawSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final isWebLink = uri.scheme == 'http' || uri.scheme == 'https';
    if (!isWebLink && uri.host.isNotEmpty) {
      rawSegments.insert(0, uri.host);
    }
    final sanitized = <String>[];
    for (final raw in rawSegments) {
      if (raw.startsWith('@') && raw.length > 1) {
        final handle = sanitizeDeepLinkSegment(raw.substring(1), maxLength: 64);
        if (handle.isNotEmpty) sanitized.add('@$handle');
      } else {
        final clean = sanitizeDeepLinkSegment(raw);
        if (clean.isNotEmpty) sanitized.add(clean);
      }
      if (sanitized.length >= 8) break;
    }
    return sanitized;
  }

  Future<void> handleDeepLink(Uri uri) async {
    if (uri.toString().length > 2048 || !isAllowedDeepLinkScheme(uri.scheme)) {
      AppConfig.logger.w('DeepLink rechazado por longitud o esquema inseguro');
      return;
    }
    List<String> segments = _addressSegments(uri);
    String? rawType = uri.queryParameters['type'];
    String? rawId = uri.queryParameters['id'];
    String? type = rawType != null ? sanitizeDeepLinkSegment(rawType, maxLength: 32) : null;
    if (type != null && type.isEmpty) type = null;
    String? id = rawId != null ? sanitizeDeepLinkSegment(rawId) : null;
    if (id != null && id.isEmpty) id = null;

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
                final item = await AppReleaseItems.repository.getBySlug(fullSlug);
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
        final safeItemIdOrSlug = sanitizeDeepLinkSegment(
          uri.queryParameters['item'] ?? uri.queryParameters['play'] ?? '',
        );
        if (safeItemIdOrSlug.isNotEmpty) {
          if (AppConfig.instance.appInUse == AppInUse.g) {
            Sint.offAllNamed(AppRouteConstants.root);
            Future.delayed(const Duration(milliseconds: 300), () async {
              try {
                AppReleaseItem? item;
                final match = await SlugRouter.resolve(safeItemIdOrSlug);
                if (match != null && match.type == 'item' && match.entity is AppReleaseItem) {
                  item = match.entity as AppReleaseItem;
                }
                item ??= await AppReleaseItems.repository.retrieve(safeItemIdOrSlug);
                if (item.id.isNotEmpty) {
                  Sint.find<AudioPlayerInvokerService>().init(
                    releaseItems: [item],
                    index: 0,
                    playItem: true,
                  );
                }
              } catch (e) {
                AppConfig.logger.e(
                  'Error playing item from inicio query param: ${SecureLogger.sanitize(e.toString())}',
                );
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
        final safeCoupon = sanitizeInviteCoupon(segments[1]);
        if (safeCoupon.isNotEmpty) {
          pendingInviteCoupon = safeCoupon;
          AppConfig.logger.i('DeepLink: valid invite coupon captured → register');
        } else {
          pendingInviteCoupon = '';
          AppConfig.logger.w('DeepLink: rejected malformed invite coupon');
        }
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
              final item = await AppReleaseItems.repository.retrieve(segments[1]);
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
                          : await AppReleaseItems.repository.retrieve(match.id);
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
    final safeId = sanitizeDeepLinkSegment(id);
    final rawProfileToken = slug.isNotEmpty ? slug : id;
    final cleanProfileToken = rawProfileToken.startsWith('@')
        ? sanitizeDeepLinkSegment(rawProfileToken.substring(1), maxLength: 64)
        : sanitizeDeepLinkSegment(rawProfileToken, maxLength: 64);
    final safeSlug = sanitizeDeepLinkSegment(slug);
    final safeOwnerSlug = sanitizeDeepLinkSegment(ownerSlug);

    switch (type) {
      case 'profile':
        if (cleanProfileToken.isEmpty) return siteUrl;
        return '$siteUrl/@$cleanProfileToken';
      case 'book':
      case 'media':
        // `/a/{ownerSlug}/{slug}` — the artist has to be in the address because
        // a release slug is only unique per artist: two bands may each have a
        // "Piedad", and a bare `/piedad` could not tell them apart.
        // releasePath() falls back to `/item/{id}` when the slugs are missing.
        if (safeId.isEmpty && (safeOwnerSlug.isEmpty || safeSlug.isEmpty)) {
          return siteUrl;
        }
        return '$siteUrl${AppRouteConstants.releasePath(safeId, ownerSlug: safeOwnerSlug, slug: safeSlug)}';
      case 'post':
        return safeId.isNotEmpty ? '$siteUrl/p/$safeId' : siteUrl;
      case 'blog':
        if (safeSlug.isNotEmpty) return '$siteUrl/blog/$safeSlug';
        return safeId.isNotEmpty ? '$siteUrl/blog/$safeId' : siteUrl;
      case 'event':
        if (safeSlug.isNotEmpty) return '$siteUrl/$safeSlug';
        return safeId.isNotEmpty ? '$siteUrl/e/$safeId' : siteUrl;
      case 'collective':
        if (safeSlug.isNotEmpty) return '$siteUrl/$safeSlug';
        return safeId.isNotEmpty ? '$siteUrl/collective/$safeId' : siteUrl;
      case 'playlist':
        if (AppConfig.instance.appInUse == AppInUse.g && safeSlug.isNotEmpty) {
          return '$siteUrl/$safeSlug';
        }
        return safeId.isNotEmpty ? '$siteUrl/playlist/$safeId' : siteUrl;
      case 'product':
      case 'merch':
        return safeId.isNotEmpty
            ? '$siteUrl${AppRouteConstants.shopProductPath(safeId)}'
            : siteUrl;
      case 'founding':
      case 'fondeo':
      case 'fondeos':
        final target = safeSlug.isNotEmpty ? safeSlug : safeId;
        return target.isNotEmpty
            ? '$siteUrl${AppRouteConstants.foundingPath(target)}'
            : '$siteUrl${AppRouteConstants.foundingHome}';
      case 'invite':
        final safeInvite = sanitizeInviteCoupon(id);
        return safeInvite.isNotEmpty ? '$siteUrl/invite/$safeInvite' : siteUrl;
      default:
        return siteUrl;
    }
  }

  /// @deprecated Use [generateVanityUrl] instead.
  static String generateDeepLink({required String host,
    required String type, required String id}) {
    final rawScheme = AppProperties.getAppName()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9+.\-]'), '');
    final myScheme = rawScheme.isNotEmpty ? rawScheme : 'neom';
    const String myHost = 'share';
    final safeType = sanitizeDeepLinkSegment(type, maxLength: 32);
    final safeId = sanitizeDeepLinkSegment(id);
    if (safeType.isEmpty || safeId.isEmpty) {
      return '$myScheme://$myHost';
    }
    return '$myScheme://$myHost/$safeType/$safeId';
  }

}
