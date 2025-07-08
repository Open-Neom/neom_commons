import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';

import 'app_utilities.dart';
import 'constants/app_translation_constants.dart';

class DeviceUtilities {

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

  static bool isTablet(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;  // Typically, tablets have a minimum width of 600dp
  }

  static void copyToClipboard({required String text, String? displayText,}) {
    Clipboard.setData(ClipboardData(text: text),);
    AppUtilities.showSnackBar(message: displayText ?? AppTranslationConstants.copied.tr);
  }

}
