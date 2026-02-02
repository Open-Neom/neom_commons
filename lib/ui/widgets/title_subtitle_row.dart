import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../../utils/app_alerts.dart';
import '../../utils/constants/translations/common_translation_constants.dart';
import '../../utils/external_utilities.dart';
import 'custom_url_text.dart';

class TitleSubtitleRow extends StatelessWidget {

  final bool showDivider;
  final String navigateTo;
  final String url;
  final String subtitle, title;
  final Color textColor;
  final Function? onPressed;
  final double titleFontSize, subTitleFontSize;
  final double vPadding, hPadding;
  final dynamic navigateArguments;
  const TitleSubtitleRow(
    this.title, {
    super.key,
    this.navigateTo = "",
    this.url = "",
    this.subtitle = "",
    this.titleFontSize = 16,
    this.subTitleFontSize = 14,
    this.textColor = Colors.white70,
    this.onPressed,
    this.vPadding = 0,
    this.hPadding = 10,
    this.showDivider = true,
    this.navigateArguments,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding:
              EdgeInsets.symmetric(vertical: vPadding, horizontal: hPadding),
          onTap: () {
            if (onPressed != null) {
              onPressed!();
            }

            if(navigateTo.isNotEmpty) {
              navigateTo != AppRouteConstants.underConstruction ?
              Sint.toNamed(navigateTo, arguments: navigateArguments)
                  : AppAlerts.showAlert(context, title: title, message: CommonTranslationConstants.underConstruction.tr);
            } else if(url.isNotEmpty) {
              ExternalUtilities.launchURL(url);
            }
          },
          title: title.isNotEmpty ? UrlText(
            text: title,
            style: TextStyle(fontSize: titleFontSize, color: textColor, ),
          ) : const SizedBox.shrink(),
          subtitle: Text(subtitle,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w400,
              fontSize: subTitleFontSize,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        !showDivider ? const SizedBox.shrink() : const Divider(height: 0)
      ],
    );
  }
}
