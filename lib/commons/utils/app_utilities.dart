import 'dart:convert';
import 'dart:io';
import 'dart:math';

// import 'dart:html' as html;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/app_properties.dart';
import 'package:neom_core/core/domain/model/app_profile.dart';
import 'package:neom_core/core/domain/model/instrument.dart';
import 'package:neom_core/core/domain/model/item_list.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'package:path_provider/path_provider.dart';

import '../ui/theme/app_color.dart';
import 'constants/app_constants.dart';
import 'constants/app_translation_constants.dart';


class AppUtilities {

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static void showSnackBar({String title = '', String message = '', Duration duration = const Duration(seconds: 3)}) {
    if(title.isEmpty) title = AppProperties.getAppName();
    Get.snackbar(title.tr, message.tr,
        snackPosition: SnackPosition.bottom,
        duration: duration
    );
  }

  static List<DateTime> getDaysFromNow({days = 28}){

    List<DateTime> dates = [];

    DateTime dateTimeNow = DateTime.now();
    dates.add(dateTimeNow);

    for( int nextDay = 1 ; nextDay <= days; nextDay++ ) {
      dates.add(dateTimeNow.add(Duration(days: nextDay)));
    }

    return dates;
  }

  static String getDurationInMinutes(int durationMs) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    Duration duration = Duration(milliseconds: durationMs);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  static void goHome() {
    AppConfig.logger.d("");
    Get.offAllNamed(AppRouteConstants.home);
  }

  static String dateFormat(int dateMsSinceEpoch, {dateFormat = "dd-MM-yyyy"}) {
    String formattedDate = "";

    formattedDate = DateFormat(dateFormat)
        .format(DateTime.fromMillisecondsSinceEpoch(dateMsSinceEpoch));

    AppConfig.logger.t("Date formatted to: $formattedDate");

    return formattedDate;
  }

  static String getNumberWithFormat(String number) {
    String numberWithFormat = "";
    if(number.length > 3) {
      NumberFormat formatter = NumberFormat('#,###,###');
      if(number.length == 4) {
        formatter = NumberFormat('#,###');
      } else if(number.length == 5) {
        formatter = NumberFormat('##,###');
      } else if(number.length == 6) {
        formatter = NumberFormat('###,###');
      }
      numberWithFormat = formatter.format(double.parse(number));
    } else {
      numberWithFormat = number;
    }

    AppConfig.logger.d("Returning number $number with format as $numberWithFormat");
    return numberWithFormat;
  }

  static Future<File> getPdfFromUrl(String pdfUrl) async {
    AppConfig.logger.d("getPdfFromUrl $pdfUrl");
    File file = File("");
    String filename = "";
    try {
      filename = pdfUrl.substring(pdfUrl.lastIndexOf("/") + 1);
      var request = await HttpClient().getUrl(Uri.parse(pdfUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      AppConfig.logger.d("File loaded and buffered");
      AppConfig.logger.i("PDF Path: ${dir.path}/$filename");
      file = File("${dir.path}/$filename");
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return file;
  }

  static Future<File> getFileFromPath(String filePath) async {
    AppConfig.logger.d("Getting File From Path: $filePath");
    File file = File("");

    try {
      AppConfig.logger.i("File Path: $filePath");

      if(Platform.isAndroid) {
        file = File(filePath);
      } else {
        file = await File.fromUri(Uri.parse(filePath)).create();
      }
    } catch (e) {
      AppConfig.logger.e('Error getting File');
    }

    return file;
  }

  static String secondsToMinutes(int seconds, {bool clockView = true}) {
    // Calculate the number of minutes and remaining seconds
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    // Format the minutes and seconds as two-digit strings
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    // Create the formatted string
    String formattedTime = '';

    if(clockView) {
      formattedTime = '$minutesStr:$secondsStr';
    } else {
      formattedTime = '$minutesStr ${AppTranslationConstants.minutes.tr} - $secondsStr ${AppTranslationConstants.seconds.tr}';
    }

    return formattedTime;
  }

  static bool isDeviceSupportedVersion({bool isIOS = false}){
    AppConfig.logger.i(Platform.operatingSystemVersion);
    if(isIOS) {
      return Platform.operatingSystemVersion.contains('13')
          || Platform.operatingSystemVersion.contains('14')
          || Platform.operatingSystemVersion.contains('15')
          || Platform.operatingSystemVersion.contains('16')
          || Platform.operatingSystemVersion.contains('17');
    } else {
      return true;
    }
  }

  static bool isWithinLastSevenDays(int date) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);
    return difference.inDays < 7;
  }



  static List<DropdownMenuItem<String>> buildDropDownMenuItemlists(List<Itemlist> itemlists) {

    List<DropdownMenuItem<String>> menuItems = [];

    for (Itemlist list in itemlists) {
      menuItems.add(
          DropdownMenuItem<String>(
            value: list.id,
            child: Center(
                child: Text(
                    list.name.length > AppConstants.maxItemlistNameLength
                        ? "${list.name
                        .substring(0,AppConstants.maxItemlistNameLength).capitalizeFirst}..."
                        : list.name.capitalizeFirst)
            ),
          )
      );
    }

    return menuItems;
  }

  static String getArtistName(String artistMediaTitle) {

    String artistName = '';
    List<String> mediaNameSplitted = artistMediaTitle.split("-");

    if(mediaNameSplitted.isNotEmpty) {
      artistName = mediaNameSplitted.first.trim();
    }

    return artistName;
  }

  static String getMediaName(String artistMediaTitle) {

    String mediaName = '';
    List<String> mediaNameSplitted = artistMediaTitle.split("-");

    if(mediaNameSplitted.isNotEmpty && mediaNameSplitted.length == 1) {
      mediaName = mediaNameSplitted.last.trim();
    } else {
      List<String> partsAfterFirst = mediaNameSplitted.sublist(1).map((part) => part.trim()).toList();
      mediaName = partsAfterFirst.join(' - ');
    }

    return mediaName;
  }

  static String getInstruments(Map<String, Instrument> profileInstruments) {
    AppConfig.logger.t("getInstruments on String value");
    String instruments = "";
    String mainInstrument = "";

    int instrumentsQty = profileInstruments.length;
    int index = 1;

    profileInstruments.forEach((key, value) {
      if (index < instrumentsQty) {
        if(value.isMain) {
          mainInstrument = key.tr;
        } else {
          instruments = "$instruments${key.tr} - ";
        }
      } else {
        instruments = instruments + key.tr;
      }
      index++;
    });

    if(instruments.length > AppConstants.maxInstrumentsNameLength) {
      instruments = "${instruments.substring(0, AppConstants.maxInstrumentsNameLength)}...";
    }

    return mainInstrument.isEmpty ? instruments : mainInstrument;
  }

  static Future<bool?> showConfirmationDialog(
      BuildContext context, {
        String title = '',
        String message = '',
        String textConfirm = 'OK', // Default text for confirm button
        String textCancel = 'Cancel', // Default text for cancel button
      }) async {
    if (title.isEmpty) title = AppProperties.getAppName(); // Use default app name if title is empty

    return showDialog<bool?>( // Specify the return type of showDialog
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.getMain(), // Consistent with showAlert
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              child: Text(
                textCancel,
                style: const TextStyle(color: AppColor.white), // White text color
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false when cancelled
              },
            ),
            // Confirm Button
            TextButton(
              child: Text(
                textConfirm,
                style: const TextStyle(color: AppColor.white), // White text color
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true when confirmed
              },
            ),
          ],
        );
      },
    );
  }

  /// Normaliza una cadena, quitando acentos y caracteres especiales comunes.
  static String normalizeString(String input) {
    // Mapa de caracteres acentuados y especiales a sus equivalentes sin acento.
    const Map<String, String> accentMap = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
      'À': 'A', 'È': 'E', 'Ì': 'I', 'Ò': 'O', 'Ù': 'U',
      'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u',
      'Â': 'A', 'Ê': 'E', 'Î': 'I', 'Ô': 'O', 'Û': 'U',
      'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u',
      'Ä': 'A', 'Ë': 'E', 'Ï': 'I', 'Ö': 'O', 'Ü': 'U',
      'ñ': 'n', 'Ñ': 'N',
      'ç': 'c', 'Ç': 'C',
    };

    String normalized = input;
    // Reemplazar cada carácter acentuado con su equivalente sin acento.
    accentMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    // Opcional: quitar otros caracteres no alfanuméricos si es necesario para el código del cupón.
    // Por ejemplo, para permitir solo letras y números:
    // normalized = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    return normalized;
  }

  static Widget ratingImage(String asset) {
    return Image.asset(
      asset,
      height: 10.0,
      width: 10.0,
      color: Colors.blueGrey,
    );
  }

  static String getAppItemHeroTag(int index) {
    return "APP_ITEM_HERO_TAG_$index";
  }

  static bool isTablet(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;  // Typically, tablets have a minimum width of 600dp
  }

  static Future<CachedNetworkImageProvider> handleCachedImageProvider(String imageUrl) async {

    CachedNetworkImageProvider cachedNetworkImageProvider = const CachedNetworkImageProvider("");

    try {
      if(imageUrl.isEmpty) {
        imageUrl = AppProperties.getNoImageUrl();
      }

      Uri uri = Uri.parse(imageUrl);

      if(uri.host.isNotEmpty) {
        http.Response response = await http.get(uri);
        if (response.statusCode == 200) {
          cachedNetworkImageProvider = CachedNetworkImageProvider(imageUrl);
        } else {
          cachedNetworkImageProvider = CachedNetworkImageProvider(AppProperties.getNoImageUrl());
        }
      }

    } catch (e){
      AppConfig.logger.e(e.toString());
    }

    return cachedNetworkImageProvider;
  }

  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static void copyToClipboard({required String text, String? displayText,}) {
    Clipboard.setData(ClipboardData(text: text),);
    AppUtilities.showSnackBar(message: displayText ?? AppTranslationConstants.copied.tr);
  }

  static String capitalizeFirstLetter(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  static Map<String, AppProfile> filterByName(Map<String, AppProfile> profiles, String name) {

    Map<String, AppProfile> filteredProfiles = {};

    try {
      if(name.isNotEmpty) {
        for (var profile in profiles.values) {
          if(AppUtilities.normalizeString(profile.name.toLowerCase()).contains(name.toLowerCase())){
            filteredProfiles[profile.id] = profile;
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return filteredProfiles;
  }


  static Map<String, AppProfile> filterByNameOrInstrument(Map<String, AppProfile> profiles, String name) {

    Map<String, AppProfile> filteredProfiles = {};

    try {
      if(name.isNotEmpty) {
        for (var profile in profiles.values) {
          if(AppUtilities.normalizeString(profile.name.toLowerCase()).contains(name.toLowerCase())
              || profile.mainFeature.toLowerCase().contains(name.toLowerCase())
              || profile.mainFeature.tr.toLowerCase().contains(name.toLowerCase())
              || profile.address.toLowerCase().contains(name.toLowerCase())
          ){
            filteredProfiles[profile.id] = profile;
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return filteredProfiles;
  }

  static bool mapKeysEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) {
      return false;
    }

    for (String key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }

    return true;
  }

}
