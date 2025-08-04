import 'package:get/get.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:share_plus/share_plus.dart';

import 'constants/translations/message_translation_constants.dart';
import 'file_downloader.dart';

class ShareUtilities {

  static Future<void> shareApp() async {

    String sharedText = '${MessageTranslationConstants.shareAppMsg.tr}\n'
        '${AppProperties.getLinksUrl()}';

    ShareResult shareResult = await SharePlus.instance.share(
        ShareParams(text: sharedText)
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedApp.tr,
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


    String sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
        '${MessageTranslationConstants.shareAppMsg.tr}\n'
        '\n${AppProperties.getLinksUrl()}\n';

    List<XFile> sharedFiles = [];
    if(thumbnailLocalPath.isNotEmpty) {
      sharedFiles.add(XFile(thumbnailLocalPath));
    }

    shareResult = await SharePlus.instance.share(
        ShareParams(text: sharedText, files: sharedFiles)
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedApp.tr,
          MessageTranslationConstants.sharedAppMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

  static Future<void> shareAppWithMediaItem(AppMediaItem mediaItem) async {

    String thumbnailLocalPath = "";

    if(mediaItem.imgUrl.isNotEmpty || (mediaItem.allImgs?.isNotEmpty ?? false) ) {
      String imgUrl = mediaItem.imgUrl.isNotEmpty ? mediaItem.imgUrl : mediaItem.allImgs?.first ?? "";
      if(imgUrl.isNotEmpty) {
        thumbnailLocalPath = await FileDownloader.downloadImage(imgUrl, imgName: "${mediaItem.artist}_${mediaItem.name}");
      }
    }

    ShareResult? shareResult;
    String caption = mediaItem.name;
    if(mediaItem.type == MediaItemType.song) {
      if(caption.contains(CoreConstants.titleTextDivider)) {
        caption = caption.replaceAll(CoreConstants.titleTextDivider, "\n\n");
      }
      String dotsLine = "";
      for(int i = 0; i < mediaItem.artist.length; i++) {
        dotsLine = "$dotsLine.";
      }
      caption = "$caption\n\n${mediaItem.artist}\n$dotsLine";
    }


    String sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
        '${MessageTranslationConstants.shareAppMsg.tr}\n'
        '\n${AppProperties.getLinksUrl()}\n';

    List<XFile> sharedFiles = [];
    if(thumbnailLocalPath.isNotEmpty) {

    }


    if(thumbnailLocalPath.isNotEmpty) {
      sharedFiles.add(XFile(thumbnailLocalPath));
      sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareMediaItem.tr}\n'
              '\n${AppProperties.getLinksUrl()}\n';
    } else {
      sharedText = '$caption${caption.isNotEmpty ? "\n\n" : ""}'
          '${MessageTranslationConstants.shareMediaItemMsg.tr}\n'
          '\n${AppProperties.getLinksUrl()}\n';
    }

    shareResult = await SharePlus.instance.share(
        ShareParams(text: sharedText, files: sharedFiles)
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedMediaItem.tr,
          MessageTranslationConstants.sharedMediaItemMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

}
