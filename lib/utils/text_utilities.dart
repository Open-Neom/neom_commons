import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/instrument.dart';

import 'constants/app_constants.dart';
import 'url_utilities.dart';

class TextUtilities {

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

  static String capitalizeFirstLetter(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  static String normalizeUrlCaption(String caption) {
    AppConfig.logger.t("normalizeUrlCaption on String value");

    String urlWithoutQueryParams = '';
    String url = UrlUtilities.getUrlFromText(caption);

    if(url.isNotEmpty) {
      urlWithoutQueryParams = UrlUtilities.removeQueryParameters(url);
    }

    return caption.replaceAll(url, urlWithoutQueryParams);
  }

}
