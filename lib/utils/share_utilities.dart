import 'package:flutter/services.dart' show rootBundle;
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:intl/intl.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
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

    String thumbnailLocalPath = "";

    if(post.thumbnailUrl.isNotEmpty || post.mediaUrl.isNotEmpty ) {
      String imgUrl = post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl;
      if(imgUrl.isNotEmpty) {
        thumbnailLocalPath = await FileDownloader.downloadImage(imgUrl);
      }
    }

    if (thumbnailLocalPath.isEmpty) {
      thumbnailLocalPath = await _getLogoLocalPath();
    }

    ShareResult? shareResult;

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

    shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: [XFile(thumbnailLocalPath)],
        previewThumbnail: XFile(thumbnailLocalPath),
      )
    );

    if(shareResult.status == ShareResultStatus.success && (shareResult.raw) != "null") {
      Sint.snackbar(MessageTranslationConstants.sharedApp.tr,
          MessageTranslationConstants.sharedAppMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

  static Future<void> shareAppWithMediaItem(AppMediaItem mediaItem) async {

    String thumbnailLocalPath = "";

    if(mediaItem.imgUrl.isNotEmpty || (mediaItem.galleryUrls?.isNotEmpty ?? false) ) {
      String imgUrl = mediaItem.imgUrl.isNotEmpty ? mediaItem.imgUrl : mediaItem.galleryUrls?.first ?? "";
      if(imgUrl.isNotEmpty) {
        thumbnailLocalPath = await FileDownloader.downloadImage(imgUrl, imgName: "${mediaItem.ownerName}_${mediaItem.name}");
      }
    }

    ShareResult? shareResult;
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

    String messageTr = thumbnailLocalPath.isNotEmpty
        ? MessageTranslationConstants.shareMediaItem.tr
        : MessageTranslationConstants.shareMediaItemMsg.tr;

    String sharedText;
    List<XFile> sharedFiles = [];

    if(thumbnailLocalPath.isNotEmpty) {
      sharedFiles.add(XFile(thumbnailLocalPath));
      sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '$messageTr\n\n'
              '$vanityUrl\n';
    } else {
      sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
          '$messageTr\n\n'
          '$vanityUrl\n';
    }

    shareResult = await SharePlus.instance.share(
        ShareParams(text: sharedText, files: sharedFiles)
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Sint.snackbar(MessageTranslationConstants.sharedMediaItem.tr,
          MessageTranslationConstants.sharedMediaItemMsg.tr,
          snackPosition: SnackPosition.bottom);
    }
  }

  /// Share a BlogEntry with optional thumbnail.
  static Future<void> shareBlogEntry(BlogEntry blogEntry) async {
    String thumbnailLocalPath = "";

    if (blogEntry.thumbnailUrl.isNotEmpty) {
      thumbnailLocalPath = await FileDownloader.downloadImage(blogEntry.thumbnailUrl);
    }

    if (thumbnailLocalPath.isEmpty) {
      thumbnailLocalPath = await _getLogoLocalPath();
    }

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

    ShareResult shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: [XFile(thumbnailLocalPath)],
        previewThumbnail: XFile(thumbnailLocalPath),
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
    String thumbnailLocalPath = "";

    if (imgUrl.isNotEmpty) {
      thumbnailLocalPath = await FileDownloader.downloadImage(
          imgUrl, imgName: "${ownerName}_$name");
    }
    if (thumbnailLocalPath.isEmpty) {
      thumbnailLocalPath = await _getLogoLocalPath();
    }

    // Vanity URL: emxi.org/shop/{productId}
    String vanityUrl = DeeplinkUtilities.generateVanityUrl(type: type, id: productId);

    String priceText = '\$${price.toStringAsFixed(0)} MXN';
    String sharedText = '$name\n'
        'por $ownerName\n'
        '$priceText\n\n'
        '${MessageTranslationConstants.shareAppMsg.tr}\n\n'
        '${AppTranslationConstants.explorePlatform.tr}: $vanityUrl';

    ShareResult shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: [XFile(thumbnailLocalPath)],
        previewThumbnail: XFile(thumbnailLocalPath),
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
    String thumbnailLocalPath = "";

    if (event.imgUrl.isNotEmpty) {
      thumbnailLocalPath = await FileDownloader.downloadImage(
          event.imgUrl, imgName: "${event.ownerName}_${event.name}");
    }
    if (thumbnailLocalPath.isEmpty) {
      thumbnailLocalPath = await _getLogoLocalPath();
    }

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
    if (thumbnailLocalPath.isNotEmpty) {
      sharedFiles.add(XFile(thumbnailLocalPath));
    }

    ShareResult shareResult = await SharePlus.instance.share(
      ShareParams(
        text: sharedText,
        files: sharedFiles.isNotEmpty ? sharedFiles : null,
        previewThumbnail: sharedFiles.isNotEmpty ? sharedFiles.first : null,
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

  static Future<String> _getLogoLocalPath() async {
    try {
      // Cargamos el asset como bytes
      final byteData = await rootBundle.load(AppAssets.icon);

      // Obtenemos el directorio temporal del dispositivo
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/logo_share.png');

      // Escribimos el archivo
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      return file.path;
    } catch (e) {
      AppConfig.logger.e("Error loading asset logo: $e");
      return "";
    }
  }

}
