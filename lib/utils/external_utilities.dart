import 'package:flutter/foundation.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/utils/constants/url_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'url_utilities.dart';

class ExternalUtilities {

  static void launchURL(String url, {bool openInApp = true, bool clearCache = false, bool clearCookies = false, bool sameTab = false}) async {
    AppConfig.logger.d('Launching: $url - openInApp: $openInApp');

    try {
      if (await canLaunchUrl(Uri.parse(url))) {

        if(openInApp && UrlUtilities.isExternalDomain(url)) {
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
    AppConfig.logger.d('Launching Whatsapp: $phone - message: $message');

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
      final String googleMapsUrl = '${UrlConstants.googleMapsURL}$mapOptions';
      launchURL(googleMapsUrl);
    } catch(e) {
      AppConfig.logger.e(e.toString());
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

}
