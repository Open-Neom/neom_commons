import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:intl/intl.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/blog_entry.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/app_locale.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sint/sint.dart';

import 'constants/app_assets.dart';
import 'constants/translations/app_translation_constants.dart';
import 'constants/translations/message_translation_constants.dart';
import 'deeplink_utilities.dart';
import 'file_downloader.dart';

class ShareUtilities {

  static Future<void> shareApp() async {
    String sharedText = '${MessageTranslationConstants.shareAppMsg.tr}\n'
        '${AppProperties.getLinksUrl()}';

    ShareResult shareResult = await SharePlus.instance.share(
        ShareParams(text: sharedText)
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Sint.snackbar(MessageTranslationConstants.sharedApp.tr,
          MessageTranslationConstants.sharedAppMsg.tr,
          snackPosition: SnackPosition.bottom);
    }
  }

  static Future<void> shareAppWithPost(Post post) async {

    String caption = post.caption;
    if(post.type == PostType.blogEntry) {
      if(caption.contains(CoreConstants.titleTextDivider)) {
        caption = caption.replaceAll(CoreConstants.titleTextDivider, "\n\n");
      }
      String dotsLine = "";
      for(int i = 0; i < post.profileName.length; i++) {
        dotsLine = "$dotsLine.";
      }
      caption = "$caption\n\n${post.profileName}\n$dotsLine";
    }

    // Vanity URL: emxi.org/p/{postId}
    String vanityUrl = DeeplinkUtilities.generateVanityUrl(type: 'post', id: post.id);

    String sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
        '${MessageTranslationConstants.shareAppMsg.tr}\n\n'
        '${AppTranslationConstants.explorePlatform.tr}: $vanityUrl';

    // On web: share text only (no file system access).
    // On mobile: download thumbnail and attach it.
    List<XFile> sharedFiles = [];
    if (!kIsWeb) {
      final thumbnailLocalPath = await _getThumbnailPath(
        post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl,
      );
      if (thumbnailLocalPath.isNotEmpty) {
        sharedFiles.add(XFile(thumbnailLocalPath));
      }
    }

    final shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: sharedFiles.isNotEmpty ? sharedFiles : null,
        previewThumbnail: sharedFiles.isNotEmpty ? sharedFiles.first : null,
        uri: kIsWeb ? Uri.tryParse(vanityUrl) : null,
      )
    );

    if(shareResult.status == ShareResultStatus.success && (shareResult.raw) != "null") {
      Sint.snackbar(MessageTranslationConstants.sharedApp.tr,
          MessageTranslationConstants.sharedAppMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

  static Future<void> shareAppWithMediaItem(AppMediaItem mediaItem) async {

    String caption = mediaItem.name;
    if(mediaItem.type == MediaItemType.song) {
      if(caption.contains(CoreConstants.titleTextDivider)) {
        caption = caption.replaceAll(CoreConstants.titleTextDivider, "\n\n");
      }
      String dotsLine = "";
      for(int i = 0; i < mediaItem.ownerName.length; i++) {
        dotsLine = "$dotsLine.";
      }
      caption = "$caption\n\n${mediaItem.ownerName}\n$dotsLine";
    }

    // Vanity URL: emxi.org/{slug} or emxi.org/item/{id}
    String vanityUrl = DeeplinkUtilities.generateVanityUrl(
      type: 'media', slug: mediaItem.slug, id: mediaItem.id,
    );

    String messageTr = MessageTranslationConstants.shareMediaItemMsg.tr;

    String sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
        '$messageTr\n\n'
        '$vanityUrl\n';

    List<XFile> sharedFiles = [];
    if (!kIsWeb) {
      String imgUrl = mediaItem.imgUrl.isNotEmpty
          ? mediaItem.imgUrl
          : mediaItem.galleryUrls?.firstOrNull ?? "";
      final thumbnailLocalPath = await _getThumbnailPath(
        imgUrl,
        imgName: "${mediaItem.ownerName}_${mediaItem.name}",
      );
      if (thumbnailLocalPath.isNotEmpty) {
        sharedFiles.add(XFile(thumbnailLocalPath));
        messageTr = MessageTranslationConstants.shareMediaItem.tr;
        sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
            '$messageTr\n\n'
            '$vanityUrl\n';
      }
    }

    final shareResult = await SharePlus.instance.share(
        ShareParams(
          text: sharedText,
          files: sharedFiles.isNotEmpty ? sharedFiles : null,
          uri: kIsWeb ? Uri.tryParse(vanityUrl) : null,
        )
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Sint.snackbar(MessageTranslationConstants.sharedMediaItem.tr,
          MessageTranslationConstants.sharedMediaItemMsg.tr,
          snackPosition: SnackPosition.bottom);
    }
  }

  /// Share a BlogEntry with optional thumbnail.
  static Future<void> shareBlogEntry(BlogEntry blogEntry) async {

    // Format the blog content
    String content = blogEntry.content;
    String dotsLine = "";
    for (int i = 0; i < blogEntry.profileName.length; i++) {
      dotsLine = "$dotsLine.";
    }
    String formattedContent = "${blogEntry.title}\n\n$content\n\n${blogEntry.profileName}\n$dotsLine";

    // Vanity URL: emxi.org/blog/{slug} or emxi.org/blog/{id}
    String vanityUrl = DeeplinkUtilities.generateVanityUrl(
      type: 'blog', slug: blogEntry.slug, id: blogEntry.id,
    );

    String sharedText = '$formattedContent\n\n'
        '${MessageTranslationConstants.shareAppMsg.tr}\n\n'
        '${AppTranslationConstants.explorePlatform.tr}: $vanityUrl';

    List<XFile> sharedFiles = [];
    if (!kIsWeb) {
      final thumbnailLocalPath = await _getThumbnailPath(blogEntry.thumbnailUrl);
      if (thumbnailLocalPath.isNotEmpty) {
        sharedFiles.add(XFile(thumbnailLocalPath));
      }
    }

    ShareResult shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: sharedFiles.isNotEmpty ? sharedFiles : null,
        previewThumbnail: sharedFiles.isNotEmpty ? sharedFiles.first : null,
        uri: kIsWeb ? Uri.tryParse(vanityUrl) : null,
      ),
    );

    if (shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Sint.snackbar(
        MessageTranslationConstants.sharedApp.tr,
        MessageTranslationConstants.sharedAppMsg.tr,
        snackPosition: SnackPosition.bottom,
      );
    }
  }

  /// Share a shop product (AppReleaseItem or ShopMerchItem) with vanity URL.
  static Future<void> shareProduct({
    required String productId,
    required String name,
    required String imgUrl,
    required double price,
    required String ownerName,
    String type = 'product', // 'product' for release, 'merch' for merch
  }) async {

    // Vanity URL: emxi.org/shop/{productId}
    String vanityUrl = DeeplinkUtilities.generateVanityUrl(type: type, id: productId);

    String priceText = '\$${price.toStringAsFixed(0)} MXN';
    String sharedText = '$name\n'
        'por $ownerName\n'
        '$priceText\n\n'
        '${MessageTranslationConstants.shareAppMsg.tr}\n\n'
        '${AppTranslationConstants.explorePlatform.tr}: $vanityUrl';

    List<XFile> sharedFiles = [];
    if (!kIsWeb) {
      final thumbnailLocalPath = await _getThumbnailPath(imgUrl, imgName: "${ownerName}_$name");
      if (thumbnailLocalPath.isNotEmpty) {
        sharedFiles.add(XFile(thumbnailLocalPath));
      }
    }

    ShareResult shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: sharedFiles.isNotEmpty ? sharedFiles : null,
        previewThumbnail: sharedFiles.isNotEmpty ? sharedFiles.first : null,
        uri: kIsWeb ? Uri.tryParse(vanityUrl) : null,
      ),
    );

    if (shareResult.status == ShareResultStatus.success &&
        shareResult.raw != "null") {
      Sint.snackbar(
        MessageTranslationConstants.sharedApp.tr,
        MessageTranslationConstants.sharedAppMsg.tr,
        snackPosition: SnackPosition.bottom,
      );
    }
  }

  /// Share an Event with date, place, and vanity URL.
  static Future<void> shareEvent(Event event) async {

    // Vanity URL: emxi.org/{slug} or emxi.org/e/{eventId}
    String vanityUrl = DeeplinkUtilities.generateVanityUrl(type: 'event', id: event.id, slug: event.slug);

    String dateText = event.eventDate > 0
        ? DateFormat.yMMMd(AppLocale.spanish.code)
            .format(DateTime.fromMillisecondsSinceEpoch(event.eventDate))
        : '';
    String placeText = event.place?.name ?? '';

    String sharedText = '${event.name}\n'
        '${dateText.isNotEmpty ? "$dateText\n" : ""}'
        '${placeText.isNotEmpty ? "$placeText\n" : ""}'
        '${event.ownerName.isNotEmpty ? "por ${event.ownerName}\n" : ""}\n'
        '${MessageTranslationConstants.shareAppMsg.tr}\n\n'
        '${AppTranslationConstants.explorePlatform.tr}: $vanityUrl';

    List<XFile> sharedFiles = [];
    if (!kIsWeb) {
      final thumbnailLocalPath = await _getThumbnailPath(
        event.imgUrl, imgName: "${event.ownerName}_${event.name}",
      );
      if (thumbnailLocalPath.isNotEmpty) {
        sharedFiles.add(XFile(thumbnailLocalPath));
      }
    }

    ShareResult shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: sharedFiles.isNotEmpty ? sharedFiles : null,
        previewThumbnail: sharedFiles.isNotEmpty ? sharedFiles.first : null,
        uri: kIsWeb ? Uri.tryParse(vanityUrl) : null,
      ),
    );

    if (shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Sint.snackbar(
        MessageTranslationConstants.sharedApp.tr,
        MessageTranslationConstants.sharedAppMsg.tr,
        snackPosition: SnackPosition.bottom,
      );
    }
  }

  // ── Private helpers (mobile only) ──

  /// Download an image and return its local path. Falls back to the app logo.
  /// Only called on mobile — web shares text+URL without file attachments.
  static Future<String> _getThumbnailPath(String imgUrl, {String imgName = ''}) async {
    String localPath = "";
    if (imgUrl.isNotEmpty) {
      localPath = await FileDownloader.downloadImage(imgUrl, imgName: imgName);
    }
    if (localPath.isEmpty) {
      localPath = await _getLogoLocalPath();
    }
    return localPath;
  }

  static Future<String> _getLogoLocalPath() async {
    try {
      final byteData = await rootBundle.load(AppAssets.icon);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/logo_share.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      return file.path;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'getLogoLocalPath');
      return "";
    }
  }

}
