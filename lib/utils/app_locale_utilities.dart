
import 'package:flutter/cupertino.dart';
import 'package:neom_core/utils/enums/app_locale.dart';

class AppLocaleUtilities {

  static String languageFromLocale(Locale locale) {
    String language = "";
    switch(locale.languageCode){
      case 'en':
        language = AppLocale.english.name;
        break;
      case 'esp':
        language = AppLocale.spanish.name;
        break;
      case 'es':
        language = AppLocale.spanish.name;
        break;
      case 'fr':
        language = AppLocale.french.name;
        break;
      case 'de':
        language = AppLocale.deutsch.name;
        break;
    }

    return language;
  }

}
