
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_found_in_list.dart';
import 'package:neom_core/domain/model/item_list.dart';

import '../ui/theme/app_color.dart';
import 'constants/app_constants.dart';
import 'text_utilities.dart';


class AppUtilities {

  static void showSnackBar({String title = '', String message = '', Duration duration = const Duration(seconds: 3)}) {
    if(title.isEmpty) title = AppProperties.getAppName();
    Get.snackbar(title.tr, message.tr,
        snackPosition: SnackPosition.bottom,
        duration: duration
    );
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
          cachedNetworkImageProvider = CachedNetworkImageProvider(AppProperties.getAppLogoUrl());
        }
      }

    } catch (e){
      AppConfig.logger.e(e.toString());
    }

    return cachedNetworkImageProvider;
  }

  static Map<String, AppProfile> filterByName(Map<String, AppProfile> profiles, String name) {

    Map<String, AppProfile> filteredProfiles = {};

    try {
      if(name.isNotEmpty) {
        for (var profile in profiles.values) {
          if(TextUtilities.normalizeString(profile.name.toLowerCase()).contains(name.toLowerCase())){
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
          if(TextUtilities.normalizeString(profile.name.toLowerCase()).contains(name.toLowerCase())
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

  static ItemFoundInList? getItemFoundInList(List<Itemlist> itemlists, String itemId) {
    AppConfig.logger.d("Verifying if item already exists in itemlists");
    bool itemAlreadyInList = false;

    String listId = "";
    String listName = "";
    String? listImgUrl;
    String itemName = "";
    String itemImgUrl = "";
    int itemState = 0;

    for (var list in itemlists) {
      for (AppMediaItem item in list.appMediaItems ?? []) {
        if (item.id == itemId) {
          itemAlreadyInList = true;
          itemState = item.state;
          itemName = item.name;
          itemImgUrl = item.imgUrl;
        }
      }

      if(!itemAlreadyInList) {
        for (AppReleaseItem item in list.appReleaseItems ?? []) {
          if (item.id == itemId) {
            itemAlreadyInList = true;
            itemState = item.state;
            itemName = item.name;
            itemImgUrl = item.imgUrl;
          }
        }
      }

      if(itemAlreadyInList) {
        listId = list.id;
        listName = list.name;
        listImgUrl = list.imgUrl;
        break;
      }
    }

    if(itemAlreadyInList) {
      AppConfig.logger.d("Item found in itemlists: $itemId");
      return ItemFoundInList(
        itemId: itemId,
        itemName: itemName,
        itemState: itemState,
        itemImgUrl: itemImgUrl,
        listId: listId,
        listName: listName,
        listImgUrl: listImgUrl,
      );
    } else {
      return null;
    }

  }

  static Uint8List base64Decode(String base64String) {
    return base64.decode(base64String);
  }

}
