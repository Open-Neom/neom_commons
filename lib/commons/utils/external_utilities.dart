import 'dart:io';

// import 'dart:html' as html;
// import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/app_properties.dart';
import 'package:neom_core/core/domain/model/app_media_item.dart';
import 'package:neom_core/core/domain/model/place.dart';
import 'package:neom_core/core/domain/model/post.dart';
import 'package:neom_core/core/utils/constants/core_constants.dart';
import 'package:neom_core/core/utils/constants/url_constants.dart';
import 'package:neom_core/core/utils/enums/media_item_type.dart';
import 'package:neom_core/core/utils/enums/post_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'constants/message_translation_constants.dart';

class ExternalUtilities {

  static Future<void> shareApp() async {
    ShareResult shareResult = await Share.share('${MessageTranslationConstants.shareAppMsg.tr}\n'
        '${AppProperties.getLinksUrl()}'
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedApp.tr,
          MessageTranslationConstants.sharedAppMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

  static Future<void> clearWebViewCache() async {
    WebViewController webViewController = WebViewController();
    await webViewController.clearCache();
  }

  static Future<void> clearWebViewCookies() async {
    WebViewCookieManager cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
  }

  static void launchURL(String url, {bool openInApp = true, bool clearCache = false, bool clearCookies = false, bool sameTab = false}) async {
    AppConfig.logger.d('Launching: $url - openInApp: $openInApp');

    try {
      if (await canLaunchUrl(Uri.parse(url))) {

        if(openInApp && ExternalUtilities.isExternalDomain(url)) {
          openInApp = false;
        }

        if (kIsWeb && sameTab) {
          // Si estás en la web, abre en la misma pestaña o en una nueva
          // html.window.location.href = url; // Esto abrirá en la misma pestaña
        } else {
          if(clearCache) await clearWebViewCache();
          if(clearCookies) await clearWebViewCookies();

          await launchUrl(Uri.parse(url),
            mode: openInApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
          );
        }

      } else {
        AppConfig.logger.i('Could not launch $url');
      }
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  static void launchWhatsappURL(String phone, String message) async {
    try {
      String url = AppProperties.getWhatsappUrl().replaceAll("<phoneNumber>", phone);
      url = url.replaceAll("<message>", message);

      if (await canLaunchUrl(Uri.parse("https://$url"))) { //TODO Verify how to use constant
        await launchUrl(Uri.parse(url));
      } else {
        AppConfig.logger.i('Could not launch $url');
      }
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  static void launchGoogleMaps({String? address, Place? place}) async {
    try {
      String mapsQuery = '';
      if(address != null) {
        mapsQuery = address;
      } else if(place != null) {
        StringBuffer placeAddress = StringBuffer();
        placeAddress.write(place.name);
        placeAddress.write(',');
        placeAddress.write(place.address!.street);
        placeAddress.write(',');
        placeAddress.write(place.address!.city);
        placeAddress.write(',');
        placeAddress.write(place.address!.state);
        placeAddress.write(',');
        placeAddress.write(place.address!.country);
        AppConfig.logger.i(placeAddress.toString());
        mapsQuery = placeAddress.toString();
      }

      String mapOptions = Uri.encodeComponent(mapsQuery);
      final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$mapOptions";
      launchURL(googleMapsUrl);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }

  static Future<void> shareAppWithPost(Post post) async {

    String thumbnailLocalPath = "";

    if(post.thumbnailUrl.isNotEmpty || post.mediaUrl.isNotEmpty ) {
      String imgUrl = post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl;
      if(imgUrl.isNotEmpty) {
        thumbnailLocalPath = await downloadImage(imgUrl);
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


    if(thumbnailLocalPath.isNotEmpty) {
      shareResult = await Share.shareXFiles([XFile(thumbnailLocalPath)],
          text: '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareAppMsg.tr}\n'
              '\n${AppProperties.getLinksUrl()}\n'
      );
    } else {
      shareResult = await Share.share(
          '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareAppMsg.tr}\n'
              '\n${AppProperties.getLinksUrl()}\n'
      );
    }


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
        thumbnailLocalPath = await downloadImage(imgUrl, imgName: "${mediaItem.artist}_${mediaItem.name}");
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


    if(thumbnailLocalPath.isNotEmpty) {
      shareResult = await Share.shareXFiles([XFile(thumbnailLocalPath)],
          text: '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareMediaItem.tr}\n'
              '\n${AppProperties.getLinksUrl()}\n'
      );
    } else {
      shareResult = await Share.share(
          '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareMediaItemMsg.tr}\n'
              '\n${AppProperties.getLinksUrl()}\n'
      );
    }


    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedMediaItem.tr,
          MessageTranslationConstants.sharedMediaItemMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

  static Future<String> downloadImage(String imgUrl, {String imgName = ''}) async {
    AppConfig.logger.d("Entering downloadImage method");
    String localPath = "";
    String name = imgName.isNotEmpty ? imgName : imgUrl;
    try {

      final response = await http.get(Uri.parse(imgUrl));
      if (response.statusCode == 200) {
        name = name.replaceAll(".", "").replaceAll(":", "").replaceAll("/", "");
        // Get the document directory path
        localPath = await getLocalPath();
        localPath = "$localPath/$name.jpeg";
        File jpegFileRef = File(localPath);
        await jpegFileRef.writeAsBytes(response.bodyBytes);
        AppConfig.logger.i("Image downloaded to path $localPath successfully.");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return localPath;
  }

  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static String removeQueryParameters(String url) {
    final int questionMarkIndex = url.indexOf('?');
    if (questionMarkIndex == -1) {
      return url;
    }

    return url.substring(0, questionMarkIndex);
  }

  static bool isExternalDomain(String url) {
    final uri = Uri.parse(url);
    return UrlConstants.externalDomains.contains(uri.host);
  }

}
