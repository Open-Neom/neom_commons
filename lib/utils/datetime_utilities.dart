import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:sint/sint.dart';

import 'constants/translations/app_translation_constants.dart';


class DateTimeUtilities {

  static List<DateTime> getDaysFromNow({int days = 28}){

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

  static String dateFormat(int dateMsSinceEpoch, {dateFormat = "dd-MM-yyyy"}) {
    String formattedDate = "";

    formattedDate = DateFormat(dateFormat)
        .format(DateTime.fromMillisecondsSinceEpoch(dateMsSinceEpoch));

    AppConfig.logger.t("Date formatted to: $formattedDate");

    return formattedDate;
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

  static bool isWithinLastSevenDays(int date) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);
    return difference.inDays < 7;
  }

  static String formatTimeAgo(DateTime dateTime, {String? locale}) {
    return GetTimeAgo.parse(dateTime,
        locale: locale ?? Sint.locale?.languageCode,
        pattern: CoreConstants.timeAgoPattern,
    );
  }

}
